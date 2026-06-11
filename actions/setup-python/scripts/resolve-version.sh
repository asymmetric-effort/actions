#!/usr/bin/env bash
# resolve-version.sh — Determine the Python version to install and the download URL.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Read Python version from a .python-version file (plain text, one version per line)
read_python_version_from_file() {
  local file_path="$1"

  if [[ ! -f "${file_path}" ]]; then
    echo "::warning::Version file not found: ${file_path}" >&2
    return 1
  fi

  local content
  content="$(head -n 1 "${file_path}" | tr -d '[:space:]')"

  if [[ -z "${content}" ]]; then
    echo "::warning::Version file is empty: ${file_path}" >&2
    return 1
  fi

  # Strip leading 'python-' prefix if present (e.g., pyenv style)
  content="${content#python-}"

  echo "${content}"
}

# Check for an existing Python installation in the tool cache
find_python_in_tool_cache() {
  local version="$1"
  local architecture="${2:-x64}"
  local tool_cache="${TOOL_CACHE:-${RUNNER_TOOL_CACHE:-/opt/hostedtoolcache}}"
  local cache_dir="${tool_cache}/Python/${version}/${architecture}"

  if [[ -d "${cache_dir}" ]]; then
    echo "${cache_dir}"
    return 0
  fi

  # Try matching a patch version when only major.minor is specified
  if [[ "${version}" =~ ^[0-9]+\.[0-9]+$ ]]; then
    local match
    match="$(find "${tool_cache}/Python/" -maxdepth 1 -type d -name "${version}.*" 2>/dev/null | sort -V | tail -n 1 || true)"
    if [[ -n "${match}" && -d "${match}/${architecture}" ]]; then
      echo "${match}/${architecture}"
      return 0
    fi
  fi

  return 1
}

# Build the download URL for building Python from source
build_python_download_url() {
  local version="$1"
  echo "https://www.python.org/ftp/python/${version}/Python-${version}.tgz"
}

# Main entry point: resolve version and set outputs
resolve_python_version() {
  local version="${INPUT_PYTHON_VERSION:-}"
  local version_file="${INPUT_PYTHON_VERSION_FILE:-.python-version}"
  local architecture="${INPUT_ARCHITECTURE:-x64}"

  # Priority: explicit version > version file
  if [[ -z "${version}" ]]; then
    if [[ -n "${version_file}" ]]; then
      local file_version
      if file_version="$(read_python_version_from_file "${version_file}")"; then
        version="${file_version}"
        echo "::notice::Resolved Python version from file: ${version}"
      fi
    fi
  fi

  if [[ -z "${version}" ]]; then
    echo "::error::No Python version specified and no version file found" >&2
    return 1
  fi

  # Strip leading 'v' if present
  version="${version#v}"

  local download_url
  download_url="$(build_python_download_url "${version}")"

  echo "python-version=${version}" >> "${GITHUB_OUTPUT}"
  echo "download-url=${download_url}" >> "${GITHUB_OUTPUT}"
}
