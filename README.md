# Intrepids-AI GitHub Actions

Reusable **composite** Actions for Intrepids repos. This is not a fork of third-party products—only Action wrappers and shared CI helpers live here.

## Actions

| Path | Purpose |
|------|---------|
| [`code-review-graph-pr`](./code-review-graph-pr) | Sticky PR risk comment via [code-review-graph](https://github.com/tirth8205/code-review-graph) PyPI, applying `.code-review-graphignore` to `detect-changes` so OpenSpec/planning trees stay in the PR without inflating scores |

### Example

```yaml
- uses: Intrepids-AI/github-actions/code-review-graph-pr@main
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    comment: false
```

Pin to a tag (e.g. `@v1`) once you cut a release.

## Adding an action

1. Create `your-action-name/action.yml` (+ scripts as needed).
2. Document it in this README.
3. Prefer thin wrappers over vendoring entire upstream products.
