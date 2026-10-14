#!/usr/bin/env bash
# Cognitive complexity via complexipy.
# Env: QUALITY_REPO_ROOT, COMPLEXIPY_PATHS, COMPLEXIPY_MAX, COMPLEXIPY_SNAPSHOT
set -euo pipefail
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
ROOT="$QUALITY_REPO_ROOT"
cd "$ROOT"
OUT_DIR="$ROOT/scripts/quality-out"
mkdir -p "$OUT_DIR"

# shellcheck disable=SC2206
paths=(${COMPLEXIPY_PATHS:-app})
max="${COMPLEXIPY_MAX:-20}"
snapshot="${COMPLEXIPY_SNAPSHOT:-complexipy-snapshot.json}"

if [[ ! -f "$ROOT/$snapshot" ]]; then
  echo "cognitive-complexity check FAILED: missing $snapshot" >&2
  echo "Create with: uv run complexipy ${paths[*]} --max-complexity-allowed $max --snapshot-create" >&2
  exit 1
fi

echo "==> complexipy (cognitive complexity ≤${max} + snapshot watermark)"
uv run complexipy "${paths[@]}" \
  --max-complexity-allowed "$max" \
  --failed \
  --quiet \
  --output-format json \
  --output "$OUT_DIR" \
  >"$OUT_DIR/complexipy.stdout" 2>"$OUT_DIR/complexipy.stderr"

echo "cognitive-complexity check OK"
