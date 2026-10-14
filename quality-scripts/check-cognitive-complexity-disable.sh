#!/usr/bin/env bash
# Cognitive complexity disable allowlist (ESLint sonarjs).
# Matches standalone or combined disables, e.g.
#   eslint-disable-next-line sonarjs/cognitive-complexity
#   eslint-disable-next-line complexity, sonarjs/cognitive-complexity
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"

export QUALITY_ALLOWLIST_REL="${QUALITY_ALLOWLIST_REL:-scripts/cognitive-complexity-disable-allowlist.txt}"
export QUALITY_PATTERN="${QUALITY_PATTERN:-eslint-disable-next-line.*sonarjs/cognitive-complexity}"
export QUALITY_LABEL="${QUALITY_LABEL:-cognitive-complexity-disable}"
export QUALITY_FAIL_HINT="${QUALITY_FAIL_HINT:-Never add eslint-disable-next-line sonarjs/cognitive-complexity — extract helpers until cognitive complexity ≤20.}"
export QUALITY_ALLOWLIST_HINT="${QUALITY_ALLOWLIST_HINT:-Leave existing grandfathered disables alone; see scripts/cognitive-complexity-disable-allowlist.txt}"

if [[ "${QUALITY_SKIP_ENSURE_NODE:-0}" != "1" ]]; then
  # shellcheck source=ensure-node.sh
  source "$SCRIPT_DIR/ensure-node.sh"
fi

exec bash "$SCRIPT_DIR/check-allowlist.sh"
