#!/usr/bin/env bash
# cache-utils.sh — Cache utilities for Python package managers.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Get the cache directory for a given package manager
get_python_cache_dir() {
  local cache_type="$1"
  local python_path="${2:-python3}"

  case "${cache_type}" in
    pip)
      "${python_path}" -m pip cache dir 2>/dev/null || echo "${HOME}/.cache/pip"
      ;;
    pipenv)
      if command -v pipenv &>/dev/null; then
        pipenv --venv 2>/dev/null || echo "${HOME}/.local/share/virtualenvs"
      else
        echo "${HOME}/.local/share/virtualenvs"
      fi
      ;;
    poetry)
      if command -v poetry &>/dev/null; then
        poetry config cache-dir 2>/dev/null || echo "${HOME}/.cache/pypoetry"
      else
        echo "${HOME}/.cache/pypoetry"
      fi
      ;;
    *)
      echo "::warning::Unknown cache type '${cache_type}', defaulting to pip cache" >&2
      echo "${HOME}/.cache/pip"
      ;;
  esac
}

# Get the cache key based on lock/requirements files
get_python_cache_key() {
  local cache_type="$1"
  local prefix="${2:-python}"

  local hash_file=""
  case "${cache_type}" in
    pip)
      # Look for requirements files
      for f in requirements.txt requirements/*.txt requirements-*.txt; do
        if [[ -f "${f}" ]]; then
          hash_file="${f}"
          break
        fi
      done
      ;;
    pipenv)
      hash_file="Pipfile.lock"
      ;;
    poetry)
      hash_file="poetry.lock"
      ;;
  esac

  if [[ -n "${hash_file}" && -f "${hash_file}" ]]; then
    local file_hash
    file_hash="$(sha256sum "${hash_file}" | awk '{print $1}')"
    echo "${prefix}-${cache_type}-${file_hash}"
  else
    echo "${prefix}-${cache_type}-no-lockfile"
  fi
}
