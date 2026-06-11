#!/usr/bin/env bash
# resolve-version.sh — Determine the Node.js version to install and the download URL.
# Sourced by action.yml; all logic is in functions for testability.
# shellcheck disable=SC1091

set -euo pipefail

# Detect platform name for Node.js download URL
get_node_platform() {
  case "${RUNNER_OS:-$(uname -s)}" in
    Linux|linux)   echo "linux" ;;
    macOS|Darwin)  echo "darwin" ;;
    Windows|MINGW*|MSYS*|CYGWIN*) echo "win" ;;
    *) echo "::error::Unsupported platform: $(uname -s)" >&2; return 1 ;;
  esac
}

# Detect architecture name for Node.js download URL
get_node_arch() {
  local input_arch="${INPUT_ARCHITECTURE:-}"
  if [[ -n "${input_arch}" ]]; then
    case "${input_arch}" in
      x64)    echo "x64" ;;
      arm64)  echo "arm64" ;;
      *)      echo "::error::Unsupported architecture input: ${input_arch}" >&2; return 1 ;;
    esac
    return 0
  fi

  local raw="${RUNNER_ARCH:-$(uname -m)}"
  case "${raw}" in
    X64|x86_64)             echo "x64" ;;
    ARM64|aarch64|arm64)    echo "arm64" ;;
    *) echo "::error::Unsupported architecture: ${raw}" >&2; return 1 ;;
  esac
}

# Build the download URL for a given Node.js version
build_node_download_url() {
  local version="$1"
  local platform arch
  platform="$(get_node_platform)"
  arch="$(get_node_arch)"

  echo "https://nodejs.org/dist/v${version}/node-v${version}-${platform}-${arch}.tar.gz"
}

# Read Node.js version from a .nvmrc file (stdin)
read_version_from_nvmrc() {
  local content
  content="$(tr -d '[:space:]' < /dev/stdin)"
  # Strip leading 'v' if present
  content="${content#v}"
  if [[ -n "${content}" ]]; then
    echo "${content}"
    return 0
  fi
  return 1
}

# Read Node.js version from a .node-version file (stdin)
read_version_from_node_version() {
  local content
  content="$(tr -d '[:space:]' < /dev/stdin)"
  content="${content#v}"
  if [[ -n "${content}" ]]; then
    echo "${content}"
    return 0
  fi
  return 1
}

# Read Node.js version from package.json engines.node field (stdin)
read_version_from_package_json() {
  local content
  content="$(cat)"

  local eng
  eng="$(echo "${content}" | grep -oP '"node"\s*:\s*"\K[^"]+' 2>/dev/null || true)"
  if [[ -n "${eng}" ]]; then
    echo "${eng}"
    return 0
  fi

  return 1
}

# Read Node.js version from a file
read_node_version_from_file() {
  local file_path="$1"

  if [[ ! -f "${file_path}" ]]; then
    echo "::warning::Version file not found: ${file_path}" >&2
    return 1
  fi

  local basename
  basename="$(basename "${file_path}")"

  case "${basename}" in
    .nvmrc)
      read_version_from_nvmrc < "${file_path}"
      ;;
    .node-version)
      read_version_from_node_version < "${file_path}"
      ;;
    package.json)
      read_version_from_package_json < "${file_path}"
      ;;
    *)
      # Plain text version file
      local content
      content="$(tr -d '[:space:]' < "${file_path}")"
      content="${content#v}"
      if [[ -n "${content}" ]]; then
        echo "${content}"
        return 0
      fi
      return 1
      ;;
  esac
}

# Fetch the latest Node.js version from the dist index
fetch_latest_node_version() {
  local token="${1:-}"
  local response

  response="$(curl -fsSL "https://nodejs.org/dist/index.json")"

  # First entry is the latest version
  local version
  version="$(echo "${response}" | grep -oP '"version"\s*:\s*"v\K[^"]+' | head -1 || true)"

  if [[ -z "${version}" ]]; then
    echo "::error::Failed to fetch latest Node.js version from nodejs.org" >&2
    return 1
  fi

  echo "${version}"
}

# Resolve LTS codename to a version (e.g., lts/iron -> 20.x.x)
resolve_lts_version() {
  local lts_spec="$1"
  local response

  response="$(curl -fsSL "https://nodejs.org/dist/index.json")"

  local codename
  if [[ "${lts_spec}" == "lts/*" || "${lts_spec}" == "lts" ]]; then
    # Find the latest LTS version
    codename=""
    local version
    version="$(echo "${response}" | grep -oP '"version"\s*:\s*"v\K[^"]+' | while IFS= read -r v; do
      local lts_val
      lts_val="$(echo "${response}" | grep -oP "\"version\"\\s*:\\s*\"v${v}\"[^}]*\"lts\"\\s*:\\s*\"\\K[^\"]*" | head -1 || true)"
      if [[ -n "${lts_val}" && "${lts_val}" != "false" ]]; then
        echo "${v}"
        break
      fi
    done)"
    if [[ -n "${version}" ]]; then
      echo "${version}"
      return 0
    fi
  else
    # Extract codename from lts/codename
    codename="${lts_spec#lts/}"
    # Case-insensitive match
    local version
    version="$(echo "${response}" | grep -oiP "\"version\"\\s*:\\s*\"v\\K[^\"]+(?=\"[^}]*\"lts\"\\s*:\\s*\"${codename}\")" | head -1 || true)"
    if [[ -n "${version}" ]]; then
      echo "${version}"
      return 0
    fi
  fi

  echo "::error::Could not resolve LTS version: ${lts_spec}" >&2
  return 1
}

# Main entry point: resolve version and set outputs
resolve_node_version() {
  local version="${INPUT_NODE_VERSION:-}"
  local version_file="${INPUT_NODE_VERSION_FILE:-}"
  local token="${INPUT_TOKEN:-}"

  # Priority: explicit version > version file > latest LTS
  if [[ -n "${version_file}" ]] && [[ -z "${version}" ]]; then
    local file_version
    if file_version="$(read_node_version_from_file "${version_file}")"; then
      version="${file_version}"
      echo "::notice::Resolved Node.js version from file: ${version}"
    fi
  fi

  if [[ -z "${version}" ]]; then
    version="lts/*"
  fi

  # Handle LTS specifiers
  if [[ "${version}" == lts/* || "${version}" == lts ]]; then
    version="$(resolve_lts_version "${version}")"
    echo "::notice::Resolved LTS Node.js version: ${version}"
  elif [[ "${version}" == "latest" ]]; then
    version="$(fetch_latest_node_version "${token}")"
    echo "::notice::Resolved latest Node.js version: ${version}"
  fi

  # Strip leading 'v' if present
  version="${version#v}"

  local url
  url="$(build_node_download_url "${version}")"

  echo "node-version=${version}" >> "${GITHUB_OUTPUT}"
  echo "download-url=${url}" >> "${GITHUB_OUTPUT}"

  # Set cache-related outputs if cache is requested
  local cache="${INPUT_CACHE:-}"
  if [[ -n "${cache}" ]]; then
    local cache_dir cache_key
    # shellcheck source=cache-utils.sh
    source "$(dirname "${BASH_SOURCE[0]}")/cache-utils.sh"
    cache_dir="$(get_cache_dir "${cache}")"
    cache_key="$(get_cache_key "${cache}")"
    echo "cache-dir=${cache_dir}" >> "${GITHUB_OUTPUT}"
    echo "cache-key=${cache_key}" >> "${GITHUB_OUTPUT}"
  fi
}
