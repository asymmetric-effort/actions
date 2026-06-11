#!/usr/bin/env bash
# resolve-version.sh — Determine the Go version to install and the download URL.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Detect platform for download URL
get_go_platform() {
  case "${RUNNER_OS:-$(uname -s)}" in
    Linux|linux)   echo "linux" ;;
    macOS|Darwin)  echo "darwin" ;;
    Windows|MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "::error::Unsupported platform: $(uname -s)" >&2; return 1 ;;
  esac
}

# Detect architecture for download URL
get_go_arch() {
  local override="${INPUT_ARCHITECTURE:-}"
  if [[ -n "${override}" ]]; then
    echo "${override}"
    return 0
  fi

  local raw="${RUNNER_ARCH:-$(uname -m)}"
  case "${raw}" in
    X64|x86_64)          echo "amd64" ;;
    ARM64|aarch64|arm64) echo "arm64" ;;
    *) echo "::error::Unsupported architecture: ${raw}" >&2; return 1 ;;
  esac
}

# Build the download URL for a given Go version
build_go_download_url() {
  local version="$1"
  local platform arch ext
  platform="$(get_go_platform)"
  arch="$(get_go_arch)"

  if [[ "${platform}" == "windows" ]]; then
    ext="zip"
  else
    ext="tar.gz"
  fi

  echo "https://go.dev/dl/go${version}.${platform}-${arch}.${ext}"
}

# Read Go version from go.mod (the 'go' directive line)
read_version_from_go_mod() {
  local content
  content="$(cat)"

  local version
  version="$(echo "${content}" | grep -oP '^go\s+\K[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)"

  if [[ -n "${version}" ]]; then
    echo "${version}"
    return 0
  fi

  return 1
}

# Read Go version from a file (go.mod or .go-version)
read_go_version_from_file() {
  local file_path="$1"

  if [[ ! -f "${file_path}" ]]; then
    echo "::warning::Version file not found: ${file_path}" >&2
    return 1
  fi

  local basename
  basename="$(basename "${file_path}")"

  case "${basename}" in
    go.mod)
      read_version_from_go_mod < "${file_path}"
      ;;
    *)
      # Plain text version file (e.g., .go-version)
      local content
      content="$(tr -d '[:space:]' < "${file_path}")"
      if [[ -n "${content}" ]]; then
        # Strip leading 'go' prefix if present
        echo "${content#go}"
        return 0
      fi
      return 1
      ;;
  esac
}

# Fetch the latest stable Go version from go.dev
fetch_latest_go_version() {
  local response
  response="$(curl -fsSL "https://go.dev/dl/?mode=json" 2>/dev/null)"

  local version
  version="$(echo "${response}" | grep -oP '"version"\s*:\s*"go\K[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)"

  if [[ -z "${version}" ]]; then
    echo "::error::Failed to fetch latest Go version from go.dev" >&2
    return 1
  fi

  echo "${version}"
}

# Main entry point: resolve Go version and set outputs
resolve_setup_go_version() {
  local version="${INPUT_GO_VERSION:-}"
  local version_file="${INPUT_GO_VERSION_FILE:-}"
  local check_latest="${INPUT_CHECK_LATEST:-false}"

  # Priority: explicit version > version file > latest stable
  if [[ -n "${version}" && "${version}" != "latest" && "${version}" != "stable" ]]; then
    # Strip leading 'go' prefix if present
    version="${version#go}"
    echo "::notice::Using explicit Go version: ${version}"
  elif [[ -n "${version_file}" ]]; then
    local file_version
    if file_version="$(read_go_version_from_file "${version_file}")"; then
      version="${file_version}"
      echo "::notice::Resolved Go version from file: ${version}"
    else
      echo "::error::Failed to read Go version from ${version_file}" >&2
      return 1
    fi
  fi

  if [[ -z "${version}" || "${version}" == "latest" || "${version}" == "stable" ]]; then
    version="$(fetch_latest_go_version)"
    echo "::notice::Resolved latest stable Go version: ${version}"
  fi

  if [[ "${check_latest}" == "true" ]]; then
    echo "::notice::check-latest enabled; using resolved version: ${version}"
  fi

  # Strip leading 'go' prefix if still present
  version="${version#go}"

  local url
  url="$(build_go_download_url "${version}")"

  echo "go-version=${version}" >> "${GITHUB_OUTPUT}"
  echo "download-url=${url}" >> "${GITHUB_OUTPUT}"
}
