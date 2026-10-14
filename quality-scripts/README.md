# Shared quality-scripts

Canonical bash gates for Intrepids repos. Consumer repos keep **baselines /
allowlists / configs** under their own `scripts/` and a small
`scripts/quality-env.sh`.

## CI

Use the composites (no manual clone):

- Node: `Intrepids-AI/github-actions/node-quality-gates@main`
- Python: `Intrepids-AI/github-actions/python-quality-gates@main`

Both export `QUALITY_SCRIPTS_ROOT` from this directory via `github.action_path`.

## Local resolution order

1. `$QUALITY_SCRIPTS_ROOT` (set by CI Action)
2. `$QUALITY_REPO_ROOT/../github-actions/quality-scripts` (sibling clone)
3. `$QUALITY_REPO_ROOT/vendor/github-actions/quality-scripts` (vendor)
4. Auto-cache clone under `$XDG_CACHE_HOME/intrepids-quality-scripts/` (see Python example)

## Python gates (`run-python-quality-gates.sh`)

| Script | Tool |
|--------|------|
| `check-ruff.sh` | Ruff |
| `check-complexity-disable.sh` | `# noqa: C901` allowlist |
| `check-xenon.sh` | Xenon / Radon |
| `check-complexipy.sh` | complexipy snapshot |
| `check-knip-vulture.sh` | knip + vulture |
| `check-jscpd.sh` | jscpd ceilings |
| `check-pytest.sh` | pytest (separate CI job) |

See `quality-env.example.python.sh`.

## Node gates

See `quality-env.example.sh` + `run-node-quality-gates.sh`.

Do **not** copy gate implementations into each repo — change them here.
