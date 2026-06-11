#!/usr/bin/env bash
# install-node.sh — Download, extract, and configure Node.js.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Install Node.js: either from cache or by downloading
install_node() {
  local version="${RESOLVED_VERSION:?RESOLVED_VERSION is required}"
  local download_url="${DOWNLOAD_URL:?DOWNLOAD_URL is required}"
  local cache_hit="${CACHE_HIT:-false}"
  local tool_cache="${TOOL_CACHE:-${RUNNER_TOOL_CACHE:-/tmp/node-cache}}"
  local install_dir="${tool_cache}/node/${version}"

  if [[ "${cache_hit}" == "true" ]]; then
    echo "::notice::Node.js ${version} restored from cache"
    configure_node "${install_dir}"
    return 0
  fi

  echo "Downloading Node.js ${version} from ${download_url}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local tarball_path="${tmp_dir}/node.tar.gz"

  curl -fsSL -o "${tarball_path}" "${download_url}"

  echo "Extracting archive..."
  mkdir -p "${tmp_dir}/extract"
  tar -xzf "${tarball_path}" -C "${tmp_dir}/extract" --strip-components=1

  rm -f "${tarball_path}"

  # Move to tool cache location
  mkdir -p "${install_dir}"
  cp -r "${tmp_dir}/extract/"* "${install_dir}/"

  rm -rf "${tmp_dir}"

  configure_node "${install_dir}"
}

# Add node/npm to PATH, configure registry, and set outputs
configure_node() {
  local install_dir="$1"
  local bin_dir="${install_dir}/bin"
  local registry_url="${INPUT_REGISTRY_URL:-}"

  # Add to PATH
  echo "${bin_dir}" >> "${GITHUB_PATH}"
  echo "::notice::Added ${bin_dir} to PATH"

  # Configure registry URL if provided
  if [[ -n "${registry_url}" ]]; then
    configure_registry "${registry_url}"
  fi

  # Get and report the installed version
  local installed_version
  if [[ -x "${bin_dir}/node" ]]; then
    installed_version="$("${bin_dir}/node" --version 2>/dev/null || echo "v${RESOLVED_VERSION}")"
  else
    installed_version="v${RESOLVED_VERSION}"
  fi
  # Strip leading 'v'
  installed_version="${installed_version#v}"

  echo "::notice::Node.js ${installed_version} installed at ${install_dir}"
  echo "node-version=${installed_version}" >> "${GITHUB_OUTPUT}"
}

# Write .npmrc with the given registry URL
configure_registry() {
  local registry_url="$1"
  local npmrc_path="${HOME}/.npmrc"

  # Ensure registry URL ends without a trailing slash for the scope
  local registry_clean="${registry_url%/}"

  echo "registry=${registry_clean}" > "${npmrc_path}"
  echo "::notice::Configured npm registry: ${registry_clean}"
}
