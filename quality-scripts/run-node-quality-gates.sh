#!/usr/bin/env bash
# Full Node PASS/FAIL gates (CI Quality gates + agent stop hook).
# Env from quality-env: QUALITY_REPO_ROOT, QUALITY_CHECK_COMMAND, QUALITY_FORMAT_COMMAND (optional)
set -euo pipefail

: "${QUALITY_REPO_ROOT:?QUALITY_REPO_ROOT required}"
: "${QUALITY_CHECK_COMMAND:?QUALITY_CHECK_COMMAND required}"

ROOT="$QUALITY_REPO_ROOT"
cd "$ROOT"

if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
  nvm use >/dev/null 2>&1 || true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ensure-node.sh
source "$SCRIPT_DIR/ensure-node.sh"

echo "==> ${QUALITY_CHECK_COMMAND}"
# shellcheck disable=SC2086
eval "$QUALITY_CHECK_COMMAND"

if [[ -n "${QUALITY_FORMAT_COMMAND:-}" ]]; then
  echo "==> ${QUALITY_FORMAT_COMMAND}"
  # shellcheck disable=SC2086
  eval "$QUALITY_FORMAT_COMMAND"
fi

echo "==> quality gates passed"
