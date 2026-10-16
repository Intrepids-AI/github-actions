#!/usr/bin/env bash
# Register a new ECS task definition revision (image only) and roll the service.
# Terraform owns structure (env, secrets, CPU, roles); CI owns image tags.
#
# Required env:
#   ECS_CLUSTER, ECS_SERVICE, TASK_DEFINITION_FAMILY, CONTAINER_NAME, IMAGE_URI
# Optional:
#   AWS_REGION (default us-east-2)
#   ROLLOUT=register|force (default register)
#     register — new revision with IMAGE_URI, update-service, optional wait
#     force    — update-service --force-new-deployment only (mutable :prod tag setups)
set -euo pipefail

CLUSTER="${ECS_CLUSTER:?ECS_CLUSTER required}"
SERVICE="${ECS_SERVICE:?ECS_SERVICE required}"
FAMILY="${TASK_DEFINITION_FAMILY:?TASK_DEFINITION_FAMILY required}"
CONTAINER="${CONTAINER_NAME:?CONTAINER_NAME required}"
IMAGE_URI="${IMAGE_URI:?IMAGE_URI required}"
AWS_REGION="${AWS_REGION:-us-east-2}"
ROLLOUT="${ROLLOUT:-register}"
WAIT_STABLE="${WAIT_STABLE:-true}"

register_task_def_with_image() {
  local task_def input
  task_def="$(aws ecs describe-task-definition --task-definition "$FAMILY" --region "$AWS_REGION" --query taskDefinition)"
  if ! echo "$task_def" | jq -e --arg CONTAINER "$CONTAINER" \
    '.containerDefinitions[] | select(.name == $CONTAINER)' >/dev/null; then
    echo "Container ${CONTAINER} not found in task definition family ${FAMILY}" >&2
    exit 1
  fi
  input="$(echo "$task_def" | jq \
    --arg IMAGE "$IMAGE_URI" \
    --arg CONTAINER "$CONTAINER" \
    '(.containerDefinitions[] | select(.name == $CONTAINER) | .image) = $IMAGE
     | del(
         .taskDefinitionArn,
         .revision,
         .status,
         .requiresAttributes,
         .compatibilities,
         .registeredAt,
         .registeredBy,
         .deregisteredAt
       )')"

  aws ecs register-task-definition --region "$AWS_REGION" --cli-input-json "$(echo "$input" | jq '{
    family: .family,
    taskRoleArn: .taskRoleArn,
    executionRoleArn: .executionRoleArn,
    networkMode: .networkMode,
    containerDefinitions: .containerDefinitions,
    volumes: .volumes,
    placementConstraints: .placementConstraints,
    requiresCompatibilities: .requiresCompatibilities,
    cpu: .cpu,
    memory: .memory,
    tags: .tags,
    pidMode: .pidMode,
    ipcMode: .ipcMode,
    proxyConfiguration: .proxyConfiguration,
    inferenceAccelerators: .inferenceAccelerators,
    ephemeralStorage: .ephemeralStorage,
    runtimePlatform: .runtimePlatform
  } | with_entries(select(.value != null))')" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text
}

case "$ROLLOUT" in
  register)
    echo "Registering ${FAMILY} container ${CONTAINER} with image ${IMAGE_URI}"
    TASK_DEF_ARN="$(register_task_def_with_image)"
    echo "Registered ${TASK_DEF_ARN}"
    aws ecs update-service \
      --region "$AWS_REGION" \
      --cluster "$CLUSTER" \
      --service "$SERVICE" \
      --task-definition "$TASK_DEF_ARN" \
      --output text \
      --query 'service.serviceName'
    ;;
  force)
    echo "Forcing new deployment for ${SERVICE} on ${CLUSTER} (task definition unchanged)"
    aws ecs update-service \
      --region "$AWS_REGION" \
      --cluster "$CLUSTER" \
      --service "$SERVICE" \
      --force-new-deployment \
      --output text \
      --query 'service.serviceName'
    ;;
  *)
    echo "Unknown ROLLOUT=${ROLLOUT} (expected register or force)" >&2
    exit 1
    ;;
esac

if [[ "$WAIT_STABLE" == "true" ]]; then
  echo "Waiting for service to become stable..."
  aws ecs wait services-stable \
    --region "$AWS_REGION" \
    --cluster "$CLUSTER" \
    --services "$SERVICE"
fi

echo "Rollout complete for ${SERVICE}"
