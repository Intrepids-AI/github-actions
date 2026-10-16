# Versioning (per action / workflow)

Each **composite action** and the **reusable ECS release workflow** are versioned with **git tags** in this repo:

```text
<name>/v<MAJOR>.<MINOR>.<PATCH>
```

Examples:

| Tag | Use in caller |
|-----|----------------|
| `create-github-release/v1.0.0` | `uses: Intrepids-AI/github-actions/create-github-release@create-github-release/v1.0.0` |
| `ecs-fargate-deploy/v1.0.0` | `uses: Intrepids-AI/github-actions/ecs-fargate-deploy@ecs-fargate-deploy/v1.0.0` |
| `ecs-fargate-release/v1.0.0` | `uses: Intrepids-AI/github-actions/.github/workflows/ecs-fargate-release.yml@ecs-fargate-release/v1.0.0` |

The canonical version for each unit lives in that directory’s **`VERSION`** file (e.g. `ecs-fargate-deploy/VERSION` → `1.0.0`).

## Tag shape (important)

Use **lightweight** tags only (`git tag <name>`). **Annotated** tags (`git tag -a`) can make reusable workflow callers fail at startup with *workflow file issue* / *workflow was not found* when using `uses: …/ecs-fargate-release.yml@<name>/vX.Y.Z`. Composite actions are less picky; the release script always creates lightweight tags.

**Never put `${{ … }}` in `workflow_call` input `description` fields** (GitHub evaluates expressions there at workflow load time; the reusable workflow fails to load and callers show *workflow file issue*). Composite `action.yml` descriptions have the same rule.

If you must pin a reusable workflow without a tag, use the **commit SHA** the tag points to (not the annotated tag object SHA).

## Cutting a release

After merging changes to `main`:

```bash
# From repo root, on the commit you want to tag (usually main HEAD):
./scripts/release-action-tags.sh          # tags all actions whose VERSION changed
./scripts/release-action-tags.sh --push   # create + push tags to origin
```

Or tag one unit:

```bash
./scripts/release-action-tags.sh ecs-fargate-deploy
./scripts/release-action-tags.sh --push ecs-fargate-deploy
```

**Semver:**

- **PATCH** — bugfix, docs, no input/output contract change
- **MINOR** — new optional inputs, backward compatible
- **MAJOR** — breaking input/output or behavior change

Consumers should pin **`@<name>/vX.Y.Z`**, not `@main`.
