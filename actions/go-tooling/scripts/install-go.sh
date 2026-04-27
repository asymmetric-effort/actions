#!/usr/bin/env bash
# install-go.sh — Download, extract, and configure the Go toolchain.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Install Go: either from cache or by downloading
install_go() {
  local version="${RESOLVED_VERSION:?RESOLVED_VERSION is required}"
  local download_url="${DOWNLOAD_URL:?DOWNLOAD_URL is required}"
  local cache_hit="${CACHE_HIT:-false}"
  local go_install_dir="${HOME}/sdk/go${version}"
  local gopath="${HOME}/go"

  if [[ "${cache_hit}" == "true" ]] && [[ -x "${go_install_dir}/bin/go" ]]; then
    echo "::notice::Go ${version} restored from cache"
    configure_go "${go_install_dir}" "${gopath}" "${version}"
    return 0
  fi

  echo "Downloading Go ${version} from ${download_url}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  if [[ "${download_url}" == *.zip ]]; then
    local zip_path="${tmp_dir}/go.zip"
    curl -fsSL -o "${zip_path}" "${download_url}"
    unzip -o -q "${zip_path}" -d "${tmp_dir}"
    rm -f "${zip_path}"
  else
    local tar_path="${tmp_dir}/go.tar.gz"
    curl -fsSL -o "${tar_path}" "${download_url}"
    tar -xzf "${tar_path}" -C "${tmp_dir}"
    rm -f "${tar_path}"
  fi

  # Move to versioned SDK directory
  mkdir -p "${HOME}/sdk"
  rm -rf "${go_install_dir}"
  mv "${tmp_dir}/go" "${go_install_dir}"
  rm -rf "${tmp_dir}"

  # Create GOPATH structure
  mkdir -p "${gopath}/bin"
  mkdir -p "${gopath}/pkg"

  configure_go "${go_install_dir}" "${gopath}" "${version}"
}

# Configure Go environment and set outputs
configure_go() {
  local go_root="$1"
  local gopath="$2"
  local version="$3"

  # Add Go bin directories to PATH
  echo "${go_root}/bin" >> "${GITHUB_PATH}"
  echo "${gopath}/bin" >> "${GITHUB_PATH}"

  # Set environment variables
  echo "GOROOT=${go_root}" >> "${GITHUB_ENV}"
  echo "GOPATH=${gopath}" >> "${GITHUB_ENV}"

  echo "::notice::Added ${go_root}/bin and ${gopath}/bin to PATH"

  # Verify installation
  local installed_version
  installed_version="$("${go_root}/bin/go" version 2>/dev/null | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?' || echo "go${version}")"
  echo "::notice::Go ${installed_version} installed at ${go_root}"

  echo "go-version=${version}" >> "${GITHUB_OUTPUT}"
  echo "go-path=${gopath}" >> "${GITHUB_OUTPUT}"
}
