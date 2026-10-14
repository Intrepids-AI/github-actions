# Intrepids-AI GitHub Actions

Reusable **composite** Actions and shared CI helpers for Intrepids repos. This is
not a fork of third-party products—only Action wrappers and shared scripts live here.

## Actions

| Path | Purpose |
|------|---------|
| [`code-review-graph-pr`](./code-review-graph-pr) | Sticky PR risk comment via [code-review-graph](https://github.com/tirth8205/code-review-graph) PyPI, applying `.code-review-graphignore` to `detect-changes` so OpenSpec/planning trees stay in the PR without inflating scores |
| [`create-github-release`](./create-github-release) | Idempotent GitHub Release on tag push (`gh release create --generate-notes`), race-safe if the UI created the release first |
| [`install-ripgrep`](./install-ripgrep) | Install `rg` on the runner (shared by quality gates) |
| [`setup-quality-scripts`](./setup-quality-scripts) | Export `QUALITY_SCRIPTS_ROOT` (+ optional ripgrep) for Python / custom gate runners |
| [`node-quality-gates`](./node-quality-gates) | Export shared `quality-scripts` + run consumer `check` / optional format |

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

Pin to a tag (e.g. `@v1`) or commit SHA once you cut a release.

## Adding an action

1. Create `your-action-name/action.yml` (+ scripts as needed).
2. Document it in this README.
3. Prefer thin wrappers over vendoring entire upstream products.
4. Prefer shared logic under `quality-scripts/` over copying bash into each consumer repo.
