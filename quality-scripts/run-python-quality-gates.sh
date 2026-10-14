#!/usr/bin/env bash
# Full Python PASS/FAIL gates (same order as python-quality-gates CI Action).
# Expects QUALITY_REPO_ROOT (+ knobs from consumer quality-env.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
cd "$QUALITY_REPO_ROOT"

if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
  nvm use >/dev/null 2>&1 || true
fi

echo "==> lint (ruff)"
bash "$SCRIPT_DIR/check-ruff.sh"

echo "==> complexity-disable allowlist"
export QUALITY_SKIP_ENSURE_NODE="${QUALITY_SKIP_ENSURE_NODE:-1}"
bash "$SCRIPT_DIR/check-complexity-disable.sh"

echo "==> complexity index (xenon/radon)"
bash "$SCRIPT_DIR/check-xenon.sh"

echo "==> cognitive complexity (complexipy)"
bash "$SCRIPT_DIR/check-complexipy.sh"

echo "==> knip + vulture"
# knip needs Node
export QUALITY_SKIP_ENSURE_NODE=0
bash "$SCRIPT_DIR/check-knip-vulture.sh"

echo "==> jscpd"
bash "$SCRIPT_DIR/check-jscpd.sh"

echo "==> quality gates passed"
echo "    (run check-pytest separately / CI Pytest job)"
