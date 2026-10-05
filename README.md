# GitHub Actions (Intrepids)

Reusable **composite** Actions. Not a fork of upstream products—only Action wrappers.

> Preferred org path: `Intrepids-AI/github-actions`. This repo was created under `jazo-zonora` because org create is blocked by custom-property policy; transfer when an admin can.

## Actions

| Path | Purpose |
|------|---------|
| [`code-review-graph-pr`](./code-review-graph-pr) | Sticky PR risk via [code-review-graph](https://github.com/tirth8205/code-review-graph) PyPI + `.code-review-graphignore` on detect-changes |

```yaml
- uses: jazo-zonora/github-actions/code-review-graph-pr@main
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

After transfer to the org, consumers should switch to `Intrepids-AI/github-actions/...` and pin a tag.
