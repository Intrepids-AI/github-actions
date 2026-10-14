# Shared quality-scripts

Canonical bash gates for Intrepids repos (complexity allowlists, knip, jscpd).
Consumer repos keep **baselines / allowlists / configs** under their own `scripts/`
and a small `scripts/quality-env.sh` that sets paths + package manager.

## Resolution order

Wrappers look for this directory as:

1. `$QUALITY_SCRIPTS_ROOT` (set by CI composite `node-quality-gates`)
2. `$QUALITY_REPO_ROOT/../github-actions/quality-scripts` (sibling clone)
3. `$QUALITY_REPO_ROOT/vendor/github-actions/quality-scripts` (submodule / vendor)

## Env contract (`scripts/quality-env.sh` in the consumer)

| Variable | Purpose |
|----------|---------|
| `QUALITY_REPO_ROOT` | Consumer repo root |
| `PACKAGE_EXEC` | `pnpm exec` or `npx` |
| `JSCPD_PATHS` | Space-separated paths to scan |
| `QUALITY_SCAN_PATHS` | Paths for allowlist `rg` scans |
| `QUALITY_GLOBS` | Space-separated globs (default `*.ts *.tsx`) |
| `QUALITY_CHECK_COMMAND` | e.g. `pnpm check` |
| `QUALITY_FORMAT_COMMAND` | e.g. `pnpm format:check` (optional) |
| `QUALITY_SKIP_ENSURE_NODE` | `1` for Python-only allowlist use |
| `KNIP_FINGERPRINT_PREFIX` | Optional prefix for mixed baselines |

## Consumer wrapper pattern

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=quality-env.sh
source "$ROOT/scripts/quality-env.sh"
exec bash "$QUALITY_SCRIPTS_ROOT/check-jscpd.sh"
```

Do **not** copy the gate implementations into each repo — change them here.
