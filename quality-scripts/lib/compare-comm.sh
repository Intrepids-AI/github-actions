#!/usr/bin/env bash
# Compare two sorted line lists: fail if extra (in found, not allowed) or missing (in allowed, not found).
# Usage: compare_comm <found_file> <allowed_file> <label> <expand_hint> <extra_header> <missing_header>
# shellcheck shell=bash

compare_comm() {
  local found="$1" allowed="$2" label="$3" expand_hint="$4" extra_header="$5" missing_header="$6"
  local extra missing

  extra="$(LC_ALL=C comm -23 "$found" "$allowed" || true)"
  missing="$(LC_ALL=C comm -13 "$found" "$allowed" || true)"

  if [[ -n "$extra" || -n "$missing" ]]; then
    echo "${label} check FAILED." >&2
    echo "$expand_hint" >&2
    if [[ -n "$extra" ]]; then
      echo >&2
      echo "$extra_header" >&2
      echo "$extra" | sed 's/^/  /' >&2
    fi
    if [[ -n "$missing" ]]; then
      echo >&2
      echo "$missing_header" >&2
      echo "$missing" | sed 's/^/  /' >&2
    fi
    return 1
  fi
  return 0
}
