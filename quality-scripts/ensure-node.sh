#!/usr/bin/env bash
# Refuse to run quality/tooling scripts on a Node major that does not match .nvmrc.
# Expects QUALITY_REPO_ROOT (consumer repo root). Safe to source.

_ENSURE_REPO="${QUALITY_REPO_ROOT:-}"
if [[ -z "$_ENSURE_REPO" ]]; then
  echo "ensure-node: QUALITY_REPO_ROOT is not set" >&2
  return 1 2>/dev/null || exit 1
fi

_ENSURE_NVMRC="$_ENSURE_REPO/.nvmrc"
if [[ ! -f "$_ENSURE_NVMRC" ]]; then
  echo "ensure-node: missing $_ENSURE_NVMRC" >&2
  return 1 2>/dev/null || exit 1
fi

_ENSURE_WANTED="$(tr -d '[:space:]' <"$_ENSURE_NVMRC")"
_ENSURE_WANTED="${_ENSURE_WANTED#v}"
_ENSURE_WANTED_MAJOR="${_ENSURE_WANTED%%.*}"

if ! command -v node >/dev/null 2>&1; then
  echo "ensure-node: node not found on PATH. Activate .nvmrc (e.g. nvm use) first." >&2
  return 1 2>/dev/null || exit 1
fi

_ENSURE_HAVE="$(node -v 2>/dev/null || true)"
_ENSURE_HAVE="${_ENSURE_HAVE#v}"
_ENSURE_HAVE_MAJOR="${_ENSURE_HAVE%%.*}"

if [[ -z "$_ENSURE_HAVE_MAJOR" || "$_ENSURE_HAVE_MAJOR" != "$_ENSURE_WANTED_MAJOR" ]]; then
  echo "ensure-node: Node major mismatch." >&2
  echo "  .nvmrc wants v${_ENSURE_WANTED} (major ${_ENSURE_WANTED_MAJOR})" >&2
  echo "  active node is v${_ENSURE_HAVE:-unknown}" >&2
  echo "  From repo root: source ~/.nvm/nvm.sh && nvm use" >&2
  return 1 2>/dev/null || exit 1
fi

unset _ENSURE_REPO _ENSURE_NVMRC
unset _ENSURE_WANTED _ENSURE_WANTED_MAJOR _ENSURE_HAVE _ENSURE_HAVE_MAJOR
