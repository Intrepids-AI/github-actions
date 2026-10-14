#!/usr/bin/env bash
# Generic allowlist gate: rg for PATTERN under SCAN_PATHS; compare to allowlist file:line.
# Required env (from consumer quality-env.sh):
#   QUALITY_REPO_ROOT, QUALITY_SCAN_PATHS (space-separated, relative to repo)
# Optional:
#   QUALITY_GLOBS (space-separated, default: *.ts *.tsx)
#   QUALITY_ALLOWLIST_REL (default: scripts/complexity-disable-allowlist.txt)
#   QUALITY_PATTERN, QUALITY_LABEL, QUALITY_FAIL_HINT, QUALITY_ALLOWLIST_HINT
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/compare-comm.sh
source "$SCRIPT_DIR/lib/compare-comm.sh"

: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
: "${QUALITY_SCAN_PATHS:?QUALITY_SCAN_PATHS required}"
: "${QUALITY_PATTERN:?QUALITY_PATTERN required}"

ROOT="$QUALITY_REPO_ROOT"
ALLOWLIST_REL="${QUALITY_ALLOWLIST_REL:-scripts/complexity-disable-allowlist.txt}"
ALLOWLIST="$ROOT/$ALLOWLIST_REL"
LABEL="${QUALITY_LABEL:-allowlist}"
FAIL_HINT="${QUALITY_FAIL_HINT:-Never add new matches — pay down via allowlist shrink only.}"
ALLOWLIST_HINT="${QUALITY_ALLOWLIST_HINT:-Leave grandfathered entries alone; see $ALLOWLIST_REL}"
GLOBS="${QUALITY_GLOBS:-*.ts *.tsx}"

if ! command -v rg >/dev/null 2>&1; then
  echo "rg (ripgrep) is required for ${LABEL}" >&2
  exit 1
fi

tmp_found="$(mktemp)"
tmp_allowed="$(mktemp)"
trap 'rm -f "$tmp_found" "$tmp_allowed"' EXIT

glob_args=()
# shellcheck disable=SC2206
for g in $GLOBS; do
  glob_args+=(--glob "$g")
done

scan_args=()
# shellcheck disable=SC2206
for p in $QUALITY_SCAN_PATHS; do
  scan_args+=("$ROOT/$p")
done

# rg exits 1 when there are no matches (full paydown).
set +e
rg -n "$QUALITY_PATTERN" "${glob_args[@]}" "${scan_args[@]}" \
  | sed "s|^$ROOT/||" \
  | cut -d: -f1,2 \
  | LC_ALL=C sort -u >"$tmp_found"
set -e

grep -v '^#' "$ALLOWLIST" | grep -v '^[[:space:]]*$' | LC_ALL=C sort -u >"$tmp_allowed" || true

if ! compare_comm "$tmp_found" "$tmp_allowed" "$LABEL" \
  "$FAIL_HINT"$'\n'"$ALLOWLIST_HINT" \
  "Disallowed (not in allowlist):" \
  "Allowlist entries with no matching disable (update allowlist after paying down debt):"; then
  exit 1
fi

echo "${LABEL} check OK ($(wc -l <"$tmp_found" | tr -d ' ') grandfathered entries)"
