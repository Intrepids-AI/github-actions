#!/usr/bin/env bash
# Pytest suite.
# Env: QUALITY_REPO_ROOT, PYTHON_PYTEST_ARGS (default: -q --tb=short)
set -euo pipefail
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
ROOT="$QUALITY_REPO_ROOT"
cd "$ROOT"
args="${PYTHON_PYTEST_ARGS:--q --tb=short}"
echo "==> pytest ${args}"
# shellcheck disable=SC2086
uv run pytest ${args}
