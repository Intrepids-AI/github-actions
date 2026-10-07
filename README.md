# Intrepids-AI GitHub Actions

Reusable **composite** Actions for Intrepids repos. This is not a fork of third-party products—only Action wrappers and shared CI helpers live here.

## Actions

| Path | Purpose |
|------|---------|
| [`code-review-graph-pr`](./code-review-graph-pr) | Sticky PR risk comment via [code-review-graph](https://github.com/tirth8205/code-review-graph) PyPI, applying `.code-review-graphignore` to `detect-changes` so OpenSpec/planning trees stay in the PR without inflating scores |
| [`create-github-release`](./create-github-release) | Idempotent GitHub Release on tag push (`gh release create --generate-notes`), race-safe if the UI created the release first |

### Examples

#### code-review-graph-pr

```yaml
- uses: Intrepids-AI/github-actions/code-review-graph-pr@main
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    # default comment: true (Bot-safe sticky upsert)
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
          # prerelease: true   # for alpha/beta/rc tags
```

Pin to a tag (e.g. `@v1`) or commit SHA once you cut a release.

## Adding an action

1. Create `your-action-name/action.yml` (+ scripts as needed).
2. Document it in this README.
3. Prefer thin wrappers over vendoring entire upstream products.
