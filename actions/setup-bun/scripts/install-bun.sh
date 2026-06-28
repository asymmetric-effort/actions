#!/usr/bin/env bash
# install-bun.sh — Download, extract, and configure Bun.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Install Bun: either from cache or by downloading
install_bun() {
  local version="${RESOLVED_VERSION:?RESOLVED_VERSION is required}"
  local download_url="${DOWNLOAD_URL:?DOWNLOAD_URL is required}"
  local cache_hit="${CACHE_HIT:-false}"
  local tool_cache="${TOOL_CACHE:-${RUNNER_TOOL_CACHE:-/tmp/bun-cache}}"
  local install_dir="${tool_cache}/bun/${version}"

  if [[ "${cache_hit}" == "true" ]]; then
    echo "::notice::Bun ${version} restored from cache"
    local bun_path
    bun_path="$(find_bun_binary "${install_dir}")"
    configure_bun "${bun_path}" "${install_dir}"
    return 0
  fi

  echo "Downloading Bun ${version} from ${download_url}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local zip_path="${tmp_dir}/bun.zip"

  curl -fsSL -o "${zip_path}" "${download_url}"

  echo "Extracting archive..."
  unzip -o -q "${zip_path}" -d "${tmp_dir}"
  rm -f "${zip_path}"

  # Find the extracted bun directory (e.g., bun-linux-x64/)
  local extracted_dir
  extracted_dir="$(find_extracted_dir "${tmp_dir}")"

  # Move to tool cache location
  mkdir -p "${install_dir}"
  cp -r "${extracted_dir}/"* "${install_dir}/"
  chmod +x "${install_dir}/bun" 2>/dev/null || true
  chmod +x "${install_dir}/bun.exe" 2>/dev/null || true

  rm -rf "${tmp_dir}"

  local bun_path
  bun_path="$(find_bun_binary "${install_dir}")"
  configure_bun "${bun_path}" "${install_dir}"
}

# Find the extracted bun-* subdirectory
find_extracted_dir() {
  local parent="$1"
  local dir
  for dir in "${parent}"/bun-*; do
    if [[ -d "${dir}" ]]; then
      echo "${dir}"
      return 0
    fi
  done
  # No subdirectory — binary is in root
  echo "${parent}"
}

# Find the bun binary in the install directory
find_bun_binary() {
  local dir="$1"
  if [[ -f "${dir}/bun.exe" ]]; then
    echo "${dir}/bun.exe"
  elif [[ -f "${dir}/bun" ]]; then
    echo "${dir}/bun"
  else
    echo "::error::Bun binary not found in ${dir}" >&2
    return 1
  fi
}

# Add bun to PATH and set outputs
configure_bun() {
  local bun_path="$1"
  local install_dir="$2"

  # Create bunx symlink if it doesn't exist (bunx is bun in disguise)
  if [[ ! -f "${install_dir}/bunx" && ! -f "${install_dir}/bunx.exe" ]]; then
    if [[ -f "${install_dir}/bun" ]]; then
      ln -sf bun "${install_dir}/bunx"
      echo "::notice::Created bunx symlink"
    elif [[ -f "${install_dir}/bun.exe" ]]; then
      ln -sf bun.exe "${install_dir}/bunx.exe"
      echo "::notice::Created bunx.exe symlink"
    fi
  fi

  echo "${install_dir}" >> "${GITHUB_PATH}"
  echo "::notice::Added ${install_dir} to PATH"

  local installed_version
  installed_version="$("${bun_path}" --version 2>/dev/null || echo "unknown")"
  echo "::notice::Bun ${installed_version} installed at ${bun_path}"

  echo "bun-version=${installed_version}" >> "${GITHUB_OUTPUT}"
  echo "bun-path=${bun_path}" >> "${GITHUB_OUTPUT}"
}
