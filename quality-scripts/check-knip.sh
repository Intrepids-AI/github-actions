#!/usr/bin/env bash
# Fail if knip issue fingerprints are not exactly scripts/knip-baseline.txt.
# Env: QUALITY_REPO_ROOT, PACKAGE_EXEC (default: npx)
# Optional: KNIP_FINGERPRINT_PREFIX (e.g. "knip:" for mixed baselines)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/compare-comm.sh
source "$SCRIPT_DIR/lib/compare-comm.sh"

: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"

ROOT="$QUALITY_REPO_ROOT"
PACKAGE_EXEC="${PACKAGE_EXEC:-npx}"
BASELINE="$ROOT/scripts/knip-baseline.txt"
CONFIG="$ROOT/scripts/knip.json"
OUT_DIR="$ROOT/scripts/quality-out"
PREFIX="${KNIP_FINGERPRINT_PREFIX:-}"

if [[ "${QUALITY_SKIP_ENSURE_NODE:-0}" != "1" ]]; then
  # shellcheck source=ensure-node.sh
  source "$SCRIPT_DIR/ensure-node.sh"
fi

mkdir -p "$OUT_DIR"

tmp_json="$(mktemp)"
tmp_found="$(mktemp)"
tmp_allowed="$(mktemp)"
trap 'rm -f "$tmp_json" "$tmp_found" "$tmp_allowed"' EXIT

set +e
# shellcheck disable=SC2086
$PACKAGE_EXEC knip --config "$CONFIG" --no-progress --reporter json --no-exit-code \
  >"$tmp_json" 2>"$OUT_DIR/knip-check.stderr"
knip_ec=$?
set -e

if [[ $knip_ec -ne 0 ]]; then
  echo "knip check FAILED: knip exited $knip_ec" >&2
  cat "$OUT_DIR/knip-check.stderr" >&2 || true
  exit 1
fi

cp "$tmp_json" "$OUT_DIR/knip-check.json"
node "$SCRIPT_DIR/lib/knip-to-fingerprints.js" "$tmp_json" "$tmp_found" "$PREFIX"

grep -v '^#' "$BASELINE" | grep -v '^[[:space:]]*$' | LC_ALL=C sort -u >"$tmp_allowed" || true
LC_ALL=C sort -u -o "$tmp_found" "$tmp_found"

if ! compare_comm "$tmp_found" "$tmp_allowed" "knip" \
  "Never expand scripts/knip-baseline.txt — shrink only when removing dead code." \
  "New issues (not in baseline):" \
  "Stale baseline entries (no longer reported — remove them):"; then
  exit 1
fi

count="$(grep -c . "$tmp_found" || true)"
echo "knip check OK ($count baseline fingerprints)"
