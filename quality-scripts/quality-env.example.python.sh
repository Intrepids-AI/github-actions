#!/usr/bin/env bash
# Copy to scripts/quality-env.sh in a Python (uv) repo and adjust paths.
# shellcheck shell=bash

export QUALITY_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PACKAGE_EXEC="npx"
export JSCPD_PATHS="app"
export QUALITY_SCAN_PATHS="app tests"
export QUALITY_GLOBS="*.py"

# Ruff / xenon / complexipy / vulture
export PYTHON_LINT_PATHS="app tests"
export PYTHON_COMPLEXITY_PATHS="app"
export PYTHON_XENON_MAX_AVERAGE="C"
export PYTHON_XENON_MAX_MODULES="C"
export PYTHON_XENON_MAX_ABSOLUTE="F"
export PYTHON_XENON_EXCLUDE="*/migrations/*,*/tests/*,*/maintenance/*"
export COMPLEXIPY_PATHS="app"
export COMPLEXIPY_MAX="20"
export COMPLEXIPY_SNAPSHOT="complexipy-snapshot.json"
export PYTHON_VULTURE_PATHS="app"
export PYTHON_VULTURE_MIN_CONFIDENCE="80"
export PYTHON_ENABLE_VULTURE="1"
export PYTHON_PYTEST_ARGS="-q --tb=short"

# C901 allowlist (Ruff)
export QUALITY_ALLOWLIST_REL="scripts/complexity-disable-allowlist.txt"
export QUALITY_PATTERN="noqa:.*C901"
export QUALITY_LABEL="complexity-disable"
export QUALITY_FAIL_HINT="Never add '# noqa: C901' — extract helpers until cyclomatic complexity ≤20."
export QUALITY_ALLOWLIST_HINT="Leave existing grandfathered ignores alone; see scripts/complexity-disable-allowlist.txt"
export KNIP_FINGERPRINT_PREFIX="knip:"
unset QUALITY_FORMAT_COMMAND

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

  # Auto-cache clone (local/husky). CI sets QUALITY_SCRIPTS_ROOT via the Action.
  local cache_root cache_repo ref
  cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/intrepids-quality-scripts"
  cache_repo="$cache_root/github-actions"
  ref="${QUALITY_SCRIPTS_REF:-main}"
  if [[ ! -d "$cache_repo/.git" ]]; then
    mkdir -p "$cache_root"
    git clone --depth 1 --branch "$ref" \
      https://github.com/Intrepids-AI/github-actions.git "$cache_repo" >&2
  fi
  export QUALITY_SCRIPTS_ROOT="$cache_repo/quality-scripts"
  return 0
}
_resolve_quality_scripts || return 1 2>/dev/null || exit 1
