#!/usr/bin/env bash
# Cyclomatic complexity disable allowlist (ESLint complexity or Python noqa: C901).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"

# Defaults for Nest/Next (TS). Python overrides via quality-env.sh.
export QUALITY_ALLOWLIST_REL="${QUALITY_ALLOWLIST_REL:-scripts/complexity-disable-allowlist.txt}"
export QUALITY_PATTERN="${QUALITY_PATTERN:-eslint-disable-next-line complexity}"
export QUALITY_LABEL="${QUALITY_LABEL:-complexity-disable}"
export QUALITY_FAIL_HINT="${QUALITY_FAIL_HINT:-Never add eslint-disable-next-line complexity — extract helpers until cyclomatic complexity ≤20.}"
export QUALITY_ALLOWLIST_HINT="${QUALITY_ALLOWLIST_HINT:-Leave existing grandfathered disables alone; see scripts/complexity-disable-allowlist.txt}"

if [[ "${QUALITY_SKIP_ENSURE_NODE:-0}" != "1" ]]; then
  # shellcheck source=ensure-node.sh
  source "$SCRIPT_DIR/ensure-node.sh"
fi

exec bash "$SCRIPT_DIR/check-allowlist.sh"
