#!/usr/bin/env bash
# Ruff lint (includes cyclomatic C901 when configured in pyproject).
# Env: QUALITY_REPO_ROOT, PYTHON_LINT_PATHS (default: app tests)
set -euo pipefail
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
ROOT="$QUALITY_REPO_ROOT"
cd "$ROOT"
# shellcheck disable=SC2206
paths=(${PYTHON_LINT_PATHS:-app tests})
echo "==> ruff check ${paths[*]}"
uv run ruff check "${paths[@]}"
