# ECS Fargate deploy

Composite action + script used by [`.github/workflows/ecs-fargate-release.yml`](../.github/workflows/ecs-fargate-release.yml).

## Rollout strategies

| Strategy | When to use | Pros | Cons |
|----------|-------------|------|------|
| **`register`** (default) | Task definition pins an **immutable tag** (`v1.2.3`); Terraform owns env/secrets | Clear revision history; image-only change preserves SM `secrets`; matches `ignore_changes = [task_definition]` | One extra `register-task-definition` API call |
| **`force`** | Task definition image is a **mutable tag** (`:prod`) | Smallest CI surface; good for dual-service stacks that only retag `:prod` | Running revision does not show version tag; not ideal when audit needs `family:revision` → `v1.2.3` |
| **`amazon-ecs-render-task-definition` + env** | Legacy | — | **Do not use** for Terraform-managed secrets/env; easy to strip SM keys or drift from tfvars |

**Admin API / calls-api style:** build `version`, `sha`, and `prod` tags; set **task definition image to `…:version`** via **`register`**. Keep `:prod` and `:sha` for rollback lookup and ECR browsing only.

## Direct action usage

```yaml
- uses: Intrepids-AI/github-actions/ecs-fargate-deploy@main
  with:
    ecs-cluster: zonora-admin-prod
    ecs-service: zonora-admin-prod-service-v2
    task-definition-family: zonora-prod-admin-task-definition
    container-name: zonora-prod-admin-container
    image-uri: 446070271612.dkr.ecr.us-east-2.amazonaws.com/intrepidsai/admin-api-nestjs:v4.5.0
    rollout-strategy: register
```

## Script

`ecs-deploy-release.sh` reads configuration from the environment (see script header). The composite action sets those variables.
