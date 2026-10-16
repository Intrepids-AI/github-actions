# Intrepids-AI GitHub Actions

Reusable **composite** Actions and shared CI helpers for Intrepids repos. This is
not a fork of third-party products—only Action wrappers and shared scripts live here.

## Actions

| Path | Purpose |
|------|---------|
| [`code-review-graph-pr`](./code-review-graph-pr) | Sticky PR risk comment via [code-review-graph](https://github.com/tirth8205/code-review-graph) PyPI, applying `.code-review-graphignore` to `detect-changes` so OpenSpec/planning trees stay in the PR without inflating scores |
| [`create-github-release`](./create-github-release) | Idempotent GitHub Release on tag push (`gh release create --generate-notes`), race-safe if the UI created the release first |
| [`ecs-fargate-deploy`](./ecs-fargate-deploy) | ECS rollout composite (`register` image-only revision or `force`); used by the reusable release workflow |
| [`.github/workflows/ecs-fargate-release.yml`](./.github/workflows/ecs-fargate-release.yml) | Reusable **v*.*.*** prod pipeline: release + ECR (version/sha/prod) + ECS via **tf-deployer** OIDC ([docs](./ecs-fargate-release/README.md)) |
| [`install-ripgrep`](./install-ripgrep) | Install `rg` on the runner (shared by quality gates) |
| [`setup-quality-scripts`](./setup-quality-scripts) | Export `QUALITY_SCRIPTS_ROOT` (+ optional ripgrep) for Python / custom gate runners |
| [`node-quality-gates`](./node-quality-gates) | Export shared `quality-scripts` + run consumer `check` / optional format |
| [`python-quality-gates`](./python-quality-gates) | Export shared `quality-scripts` + run Python mechanical gates (ruff/xenon/complexipy/knip/jscpd) |
| [`tfsec-critical-gate`](./tfsec-critical-gate) | Fail PRs on **new** tfsec CRITICAL findings (optional baseline for known debt; SEC-33) |

## Shared quality scripts

Canonical implementations live in [`quality-scripts/`](./quality-scripts). Consumer
repos keep thin wrappers + `scripts/quality-env.sh` (paths, `pnpm exec` vs `npx`)
and per-repo baselines/allowlists. See [quality-scripts/README.md](./quality-scripts/README.md).

### Examples

#### node-quality-gates

Caller owns checkout, Node setup, and `npm ci` / `pnpm install` (+ Prisma generate).

```yaml
- uses: Intrepids-AI/github-actions/node-quality-gates@main
  with:
    check-command: npm run check
    format-command: npm run format:check
```


#### python-quality-gates

Caller owns checkout, `uv sync --group dev`, and `npm ci` (for knip/jscpd).

```yaml
- uses: Intrepids-AI/github-actions/python-quality-gates@main
```

#### install-ripgrep

```yaml
- uses: Intrepids-AI/github-actions/install-ripgrep@main
```

#### code-review-graph-pr

```yaml
- uses: Intrepids-AI/github-actions/code-review-graph-pr@main
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

#### create-github-release

Caller owns checkout and the job-level `if` / tag globs; the composite owns the `gh` logic.

```yaml
jobs:
  create-github-release:
    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: Intrepids-AI/github-actions/create-github-release@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

Per-action tags: see [VERSIONING.md](./VERSIONING.md) (e.g. `@create-github-release/v1.0.0`).

## Adding an action

1. Create `your-action-name/action.yml` (+ scripts as needed).
2. Document it in this README.
3. Prefer thin wrappers over vendoring entire upstream products.
4. Prefer shared logic under `quality-scripts/` over copying bash into each consumer repo.


#### tfsec-critical-gate

Caller owns checkout. Scans Terraform/OpenTofu at **CRITICAL** and fails on findings
not listed in an optional baseline (so known debt does not block while new CRITICAL
issues still do).

```yaml
jobs:
  tfsec-critical:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Intrepids-AI/github-actions/tfsec-critical-gate@main
        with:
          working_directory: terraform
```

Optional baseline path (repo-relative): `<working_directory>/.tfsec/critical-baseline.json`
or `.tfsec/critical-baseline.json`. Generate with the action's `gate.py --write-baseline`.
