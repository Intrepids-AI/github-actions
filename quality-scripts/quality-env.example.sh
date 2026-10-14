#!/usr/bin/env bash
# Copy to scripts/quality-env.sh and set unconditional defaults for YOUR repo.
# shellcheck shell=bash

export QUALITY_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Unconditional defaults (do not use ${VAR:-default} — it leaks across checkouts).
export PACKAGE_EXEC="npx"                    # or: pnpm exec
export JSCPD_PATHS="src scripts"             # or: apps/api/src apps/web/src packages/db
export QUALITY_SCAN_PATHS="src scripts test" # or: apps
export QUALITY_GLOBS="*.ts *.tsx"
export QUALITY_CHECK_COMMAND="npm run check"
export QUALITY_FORMAT_COMMAND="npm run format:check"
unset QUALITY_SKIP_ENSURE_NODE KNIP_FINGERPRINT_PREFIX QUALITY_PATTERN QUALITY_LABEL

_resolve_quality_scripts() {
  if [[ -n "${QUALITY_SCRIPTS_ROOT:-}" && -d "${QUALITY_SCRIPTS_ROOT}" ]]; then
    export QUALITY_SCRIPTS_ROOT="$(cd "$QUALITY_SCRIPTS_ROOT" && pwd)"
    return 0
  fi
  unset QUALITY_SCRIPTS_ROOT
  local cand
  for cand in \
    "$QUALITY_REPO_ROOT/../github-actions/quality-scripts" \
    "$QUALITY_REPO_ROOT/vendor/github-actions/quality-scripts"; do
    if [[ -d "$cand" ]]; then
      export QUALITY_SCRIPTS_ROOT="$(cd "$cand" && pwd)"
      return 0
    fi
  done
  echo "quality-env: quality-scripts not found." >&2
  echo "  Clone Intrepids-AI/github-actions next to this repo, vendor it, or set QUALITY_SCRIPTS_ROOT." >&2
  return 1
}
_resolve_quality_scripts || return 1 2>/dev/null || exit 1
