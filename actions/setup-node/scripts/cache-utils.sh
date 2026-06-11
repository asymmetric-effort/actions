#!/usr/bin/env bash
# cache-utils.sh — Utilities for detecting and managing package manager caches.
# Sourced by action.yml and resolve-version.sh; all logic is in functions for testability.

set -euo pipefail

# Get the cache directory for a given package manager
get_cache_dir() {
  local manager="$1"

  case "${manager}" in
    npm)
      local npm_cache
      npm_cache="$(npm config get cache 2>/dev/null || echo "${HOME}/.npm")"
      echo "${npm_cache}"
      ;;
    yarn)
      local yarn_cache
      yarn_cache="$(yarn cache dir 2>/dev/null || echo "${HOME}/.cache/yarn")"
      echo "${yarn_cache}"
      ;;
    pnpm)
      local pnpm_cache
      pnpm_cache="$(pnpm store path 2>/dev/null || echo "${HOME}/.local/share/pnpm/store")"
      echo "${pnpm_cache}"
      ;;
    *)
      echo "::error::Unsupported package manager for caching: ${manager}" >&2
      return 1
      ;;
  esac
}

# Build a cache key from the lockfile hash
get_cache_key() {
  local manager="$1"
  local lockfile=""
  local hash=""

  case "${manager}" in
    npm)
      lockfile="package-lock.json"
      ;;
    yarn)
      lockfile="yarn.lock"
      ;;
    pnpm)
      lockfile="pnpm-lock.yaml"
      ;;
    *)
      echo "::error::Unsupported package manager for cache key: ${manager}" >&2
      return 1
      ;;
  esac

  if [[ -f "${lockfile}" ]]; then
    hash="$(sha256sum "${lockfile}" | cut -d' ' -f1)"
  else
    echo "::warning::Lockfile not found: ${lockfile}. Using fallback cache key." >&2
    hash="no-lockfile"
  fi

  local os="${RUNNER_OS:-linux}"
  echo "node-${manager}-${os}-${hash}"
}
