#!/usr/bin/env bash
# Cyclomatic complexity index via Xenon (Radon grades).
# Env: QUALITY_REPO_ROOT, PYTHON_COMPLEXITY_PATHS, PYTHON_XENON_*
set -euo pipefail
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
ROOT="$QUALITY_REPO_ROOT"
cd "$ROOT"
OUT_DIR="$ROOT/scripts/quality-out"
mkdir -p "$OUT_DIR"

# shellcheck disable=SC2206
paths=(${PYTHON_COMPLEXITY_PATHS:-app})
avg="${PYTHON_XENON_MAX_AVERAGE:-C}"
modules="${PYTHON_XENON_MAX_MODULES:-C}"
absolute="${PYTHON_XENON_MAX_ABSOLUTE:-F}"
exclude="${PYTHON_XENON_EXCLUDE:-*/migrations/*,*/tests/*,*/maintenance/*}"

echo "==> radon cc (report)"
uv run radon cc "${paths[@]}" -s -a >"$OUT_DIR/radon-cc.txt"
uv run radon mi "${paths[@]}" -s >"$OUT_DIR/radon-mi.txt"

echo "==> xenon complexity index"
uv run xenon "${paths[@]}" \
  --max-average "$avg" \
  --max-modules "$modules" \
  --max-absolute "$absolute" \
  --exclude "$exclude"

echo "complexity-index check OK"
