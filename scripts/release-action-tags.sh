#!/usr/bin/env bash
# Create (and optionally push) per-action version tags: <dir>/v<VERSION>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUSH=false
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--push] [action-dir ...]"
      echo "Default: all directories under repo root with a VERSION file (excluding scripts/)."
      exit 0
      ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  while IFS= read -r -d '' vf; do
    dir="$(dirname "$vf")"
    name="$(basename "$dir")"
    [[ "$name" == "scripts" ]] && continue
    TARGETS+=("$name")
  done < <(find "$ROOT" -maxdepth 2 -name VERSION -print0)
fi

cd "$ROOT"
git fetch origin main 2>/dev/null || true

for name in "${TARGETS[@]}"; do
  vf="$ROOT/$name/VERSION"
  if [[ ! -f "$vf" ]]; then
    echo "skip $name (no VERSION file)" >&2
    continue
  fi
  ver="$(tr -d '[:space:]' < "$vf")"
  tag="${name}/v${ver}"
  if git rev-parse "$tag" >/dev/null 2>&1; then
    echo "exists $tag @ $(git rev-parse --short "$tag")"
    continue
  fi
  echo "tag $tag @ HEAD"
  git tag -a "$tag" -m "${name} v${ver}"
  if [[ "$PUSH" == true ]]; then
    git push origin "$tag"
  fi
done
