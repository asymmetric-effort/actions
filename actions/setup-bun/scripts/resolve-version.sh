#!/usr/bin/env bash
# resolve-version.sh — Determine the Bun version to install and the download URL.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Detect platform name for download URL
get_platform() {
  case "${RUNNER_OS:-$(uname -s)}" in
    Linux|linux)   echo "linux" ;;
    macOS|Darwin)  echo "darwin" ;;
    Windows|MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "::error::Unsupported platform: $(uname -s)" >&2; return 1 ;;
  esac
}

# Detect architecture name for download URL
get_arch() {
  local raw="${RUNNER_ARCH:-$(uname -m)}"
  case "${raw}" in
    X64|x86_64)       echo "x64" ;;
    ARM64|aarch64|arm64) echo "aarch64" ;;
    *) echo "::error::Unsupported architecture: ${raw}" >&2; return 1 ;;
  esac
}

# Build the download URL for a given version
build_download_url() {
  local version="$1"
  local platform arch
  platform="$(get_platform)"
  arch="$(get_arch)"

  if [[ "${version}" == "canary" ]]; then
    echo "https://github.com/oven-sh/bun/releases/download/canary/bun-${platform}-${arch}.zip"
  else
    echo "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-${platform}-${arch}.zip"
  fi
}

# Read Bun version from package.json content (stdin)
read_version_from_package_json() {
  local content
  content="$(cat)"

  # Try packageManager field: "bun@1.0.0"
  local pm
  pm="$(echo "${content}" | grep -oP '"packageManager"\s*:\s*"bun@\K[^"]+' 2>/dev/null || true)"
  if [[ -n "${pm}" ]]; then
    echo "${pm}"
    return 0
  fi

  # Try engines.bun field
  local eng
  eng="$(echo "${content}" | grep -oP '"bun"\s*:\s*"\K[^"]+' 2>/dev/null || true)"
  if [[ -n "${eng}" ]]; then
    echo "${eng}"
    return 0
  fi

  return 1
}

# Read Bun version from .tool-versions content (stdin)
read_version_from_tool_versions() {
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    local trimmed
    trimmed="$(echo "${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [[ "${trimmed}" == bun\ * ]]; then
      echo "${trimmed}" | awk '{print $2}'
      return 0
    fi
  done
  return 1
}

# Read Bun version from a file
read_version_from_file() {
  local file_path="$1"

  if [[ ! -f "${file_path}" ]]; then
    echo "::warning::Version file not found: ${file_path}" >&2
    return 1
  fi

  local basename
  basename="$(basename "${file_path}")"

  case "${basename}" in
    package.json)
      read_version_from_package_json < "${file_path}"
      ;;
    .tool-versions)
      read_version_from_tool_versions < "${file_path}"
      ;;
    *)
      # Plain text version file
      local content
      content="$(tr -d '[:space:]' < "${file_path}")"
      if [[ -n "${content}" ]]; then
        echo "${content}"
        return 0
      fi
      return 1
      ;;
  esac
}

# Fetch the latest Bun release version from the GitHub API
fetch_latest_version() {
  local token="${1:-}"
  local auth_header=""
  if [[ -n "${token}" ]]; then
    auth_header="Authorization: token ${token}"
  fi

  local response
  if [[ -n "${auth_header}" ]]; then
    response="$(curl -fsSL -H "${auth_header}" -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/oven-sh/bun/releases/latest")"
  else
    response="$(curl -fsSL -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/oven-sh/bun/releases/latest")"
  fi

  local tag_name
  tag_name="$(printf '%s' "${response}" | jq -r '.tag_name // empty' 2>/dev/null || true)"

  if [[ -z "${tag_name}" ]]; then
    echo "::error::Failed to fetch latest Bun release from GitHub API" >&2
    return 1
  fi

  # Strip "bun-v" prefix
  echo "${tag_name#bun-v}"
}

# Main entry point: resolve version and set outputs
resolve_version() {
  local version="${INPUT_BUN_VERSION:-latest}"
  local version_file="${INPUT_BUN_VERSION_FILE:-}"
  local token="${INPUT_TOKEN:-}"

  # Priority: explicit version > version file > latest
  if [[ -n "${version_file}" ]] && [[ "${version}" == "latest" || -z "${version}" ]]; then
    local file_version
    if file_version="$(read_version_from_file "${version_file}")"; then
      version="${file_version}"
      echo "::notice::Resolved Bun version from file: ${version}"
    fi
  fi

  if [[ "${version}" == "canary" ]]; then
    local url
    url="$(build_download_url "canary")"
    echo "bun-version=canary" >> "${GITHUB_OUTPUT}"
    echo "download-url=${url}" >> "${GITHUB_OUTPUT}"
    return 0
  fi

  if [[ "${version}" == "latest" || -z "${version}" ]]; then
    version="$(fetch_latest_version "${token}")"
    echo "::notice::Resolved latest Bun version: ${version}"
  fi

  # Strip leading 'v' if present
  version="${version#v}"

  local url
  url="$(build_download_url "${version}")"

  echo "bun-version=${version}" >> "${GITHUB_OUTPUT}"
  echo "download-url=${url}" >> "${GITHUB_OUTPUT}"
}
