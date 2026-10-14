#!/usr/bin/env bash
# Fail if jscpd clone count or duplicated-lines % exceeds scripts/jscpd-baseline.json ceilings.
# Env: QUALITY_REPO_ROOT, PACKAGE_EXEC (default: npx), JSCPD_PATHS (space-separated)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
: "${JSCPD_PATHS:?JSCPD_PATHS required}"

ROOT="$QUALITY_REPO_ROOT"
PACKAGE_EXEC="${PACKAGE_EXEC:-npx}"
BASELINE="$ROOT/scripts/jscpd-baseline.json"
CONFIG="$ROOT/scripts/jscpd.json"
OUT_DIR="$ROOT/scripts/quality-out"

if [[ "${QUALITY_SKIP_ENSURE_NODE:-0}" != "1" ]]; then
  # shellcheck source=ensure-node.sh
  source "$SCRIPT_DIR/ensure-node.sh"
fi

mkdir -p "$OUT_DIR"

# shellcheck disable=SC2206
paths=($JSCPD_PATHS)

set +e
# PACKAGE_EXEC may be "npx" or "pnpm exec" — split for exec.
# shellcheck disable=SC2086
$PACKAGE_EXEC jscpd "${paths[@]}" \
  --config "$CONFIG" \
  --output "$OUT_DIR" \
  >"$OUT_DIR/jscpd-check.stdout" 2>"$OUT_DIR/jscpd-check.stderr"
jscpd_ec=$?
set -e

REPORT="$OUT_DIR/jscpd-report.json"
if [[ ! -f "$REPORT" ]]; then
  echo "jscpd check FAILED: missing report at $REPORT (exit $jscpd_ec)" >&2
  cat "$OUT_DIR/jscpd-check.stderr" >&2 || true
  exit 1
fi

node "$SCRIPT_DIR/lib/compare-jscpd-ceilings.js" "$REPORT" "$BASELINE"
