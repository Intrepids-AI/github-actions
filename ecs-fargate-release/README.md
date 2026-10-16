# ECS Fargate release (reusable workflow)

Callable workflow: **GitHub Release** → **ECR** (version + sha) → **ECS** via OIDC (`tf-deployer`). No in-repo Terraform apply.

## Caller trigger (app repo)

Use **version tags only**:

```yaml
name: deploy prod

on:
  push:
    tags:
      - "v*.*.*"

# Required on the caller job (reusable workflow permissions do not inherit).
permissions:
  id-token: write
  contents: read

jobs:
  prod:
    # Optional: environment: production  # approval gates / env-scoped config
    uses: Intrepids-AI/github-actions/.github/workflows/ecs-fargate-release.yml@ecs-fargate-release/v1.0.0
    with:
      aws-account-id: "446070271612"
      ecr-repository-name: intrepidsai/admin-api-nestjs
      ecs-cluster: zonora-admin-prod
      ecs-service: zonora-admin-prod-service-v2
      task-definition-family: zonora-prod-admin-task-definition
      container-name: zonora-prod-admin-container
      rollout-strategy: register
      # codebuild-runner-label defaults to codebuild-common-infra-prod (CodeBuild GHA runner)
```

Pin the workflow and actions per [VERSIONING.md](../VERSIONING.md) (e.g. `@ecs-fargate-release/v1.0.0`).

## AWS auth (replace static keys)

1. Add OIDC trust for the app repo on **`tf-deployer`** (`workspaces/deployer/core-prod`), e.g.  
   `repo:Intrepids-AI/zonora-admin-api-v2:ref:refs/tags/v*.*.*` (and `repo:ORG@ORG_ID/...` form if you use numeric IDs).
2. Ensure the role can **ECR push** to the app repository and **ECS** `Describe*`, `RegisterTaskDefinition`, `UpdateService` on the target cluster/service.
3. **Remove** GitHub Environment / org secrets for **`AWS_ACCESS_KEY_ID`** / **`AWS_SECRET_ACCESS_KEY`** (`gitlab-ci-cd`).

## Secrets and env (Terraform only)

Runtime secrets and non-secret env belong in **`workspaces/<stack>/core-prod`** (Secrets Manager + `container_environment`). After cutover, **delete** obsolete GitHub **production** secrets, for example:

- `DATABASE_URL`, `JWT_SECRET`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`
- `N8N_API_KEY`, `MC_INTEGRATION_TOKEN`, `BILLING_CALL_INGEST_SECRET`, `CLOUDFRONT_PRIVATE_KEY` (if present)
- Any duplicate Cognito keys only kept for the old workflow (values live in tfvars or SM as designed)

Keep **vars** used for build/deploy wiring (`ECS_CLUSTER`, `TASK_DEFINITION_NAME`, `ECR_REPOSITORY`, …) only if still needed; the reusable workflow passes cluster/service/family as **inputs** instead of vars where possible.

## Inputs

See [`ecs-fargate-release.yml`](../.github/workflows/ecs-fargate-release.yml) `workflow_call` for the full list.
