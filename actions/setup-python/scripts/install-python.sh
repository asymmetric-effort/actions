#!/usr/bin/env bash
# install-python.sh — Install and configure Python.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Install Python: from tool cache, apt (deadsnakes PPA), or build from source
install_python() {
  local version="${RESOLVED_VERSION:?RESOLVED_VERSION is required}"
  local download_url="${DOWNLOAD_URL:?DOWNLOAD_URL is required}"
  local architecture="${INPUT_ARCHITECTURE:-x64}"
  local cache_type="${INPUT_CACHE:-}"
  local tool_cache="${TOOL_CACHE:-${RUNNER_TOOL_CACHE:-/opt/hostedtoolcache}}"
  local cache_dir

  # Check tool cache first
  cache_dir="$(find_python_in_tool_cache "${version}" "${architecture}" 2>/dev/null || true)"
  if [[ -n "${cache_dir}" ]]; then
    echo "::notice::Python ${version} found in tool cache at ${cache_dir}"
    if [[ -d "${cache_dir}/bin" ]]; then
      configure_python "${cache_dir}/bin" "${version}" "${cache_type}"
    else
      configure_python "${cache_dir}" "${version}" "${cache_type}"
    fi
    return 0
  fi

  # Try installing via apt (deadsnakes PPA) on Ubuntu
  if install_python_apt "${version}"; then
    echo "::notice::Python ${version} installed via apt (deadsnakes PPA)"
    local python_path
    python_path="$(which "python${version%.*}" 2>/dev/null || which python3 2>/dev/null || true)"
    if [[ -n "${python_path}" ]]; then
      configure_python "$(dirname "${python_path}")" "${version}" "${cache_type}"
      return 0
    fi
  fi

  # Fallback: build from source
  echo "::notice::Building Python ${version} from source"
  install_python_from_source "${version}" "${download_url}" "${tool_cache}" "${architecture}"
  cache_dir="${tool_cache}/Python/${version}/${architecture}"
  configure_python "${cache_dir}/bin" "${version}" "${cache_type}"
}

# Install Python via apt using the deadsnakes PPA
install_python_apt() {
  local version="$1"
  local major_minor="${version%.*}"

  # Only works on Ubuntu/Debian
  if [[ ! -f /etc/os-release ]]; then
    return 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "ubuntu" && "${ID:-}" != "debian" ]]; then
    return 1
  fi

  echo "Adding deadsnakes PPA..."
  if ! command -v add-apt-repository &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq software-properties-common >/dev/null 2>&1
  fi

  sudo add-apt-repository -y ppa:deadsnakes/ppa >/dev/null 2>&1
  sudo apt-get update -qq

  echo "Installing python${major_minor} via apt..."
  if sudo apt-get install -y -qq "python${major_minor}" "python${major_minor}-venv" "python${major_minor}-dev" >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

# Build and install Python from source
install_python_from_source() {
  local version="$1"
  local download_url="$2"
  local tool_cache="$3"
  local architecture="$4"
  local install_dir="${tool_cache}/Python/${version}/${architecture}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  echo "Downloading Python ${version} source from ${download_url}"
  curl -fsSL -o "${tmp_dir}/Python.tgz" "${download_url}"

  echo "Extracting source..."
  tar -xzf "${tmp_dir}/Python.tgz" -C "${tmp_dir}"

  local src_dir="${tmp_dir}/Python-${version}"
  if [[ ! -d "${src_dir}" ]]; then
    echo "::error::Source directory not found after extraction: ${src_dir}" >&2
    rm -rf "${tmp_dir}"
    return 1
  fi

  echo "Configuring Python ${version}..."
  mkdir -p "${install_dir}"
  (
    cd "${src_dir}"
    ./configure --prefix="${install_dir}" --enable-optimizations --with-ensurepip=install >/dev/null 2>&1
    echo "Building Python ${version} (this may take a few minutes)..."
    make -j"$(nproc)" >/dev/null 2>&1
    make install >/dev/null 2>&1
  )

  rm -rf "${tmp_dir}"

  if [[ ! -f "${install_dir}/bin/python3" ]]; then
    echo "::error::Python binary not found after build at ${install_dir}/bin/python3" >&2
    return 1
  fi

  echo "::notice::Python ${version} built and installed to ${install_dir}"
}

# Configure Python: add to PATH and set outputs
configure_python() {
  local python_dir="$1"
  local version="$2"
  local cache_type="${3:-}"

  # Add Python to PATH
  echo "${python_dir}" >> "${GITHUB_PATH}"
  echo "::notice::Added ${python_dir} to PATH"

  # Find the python binary
  local python_path=""
  local major_minor="${version%.*}"
  for candidate in "${python_dir}/python${version}" "${python_dir}/python${major_minor}" "${python_dir}/python3" "${python_dir}/python"; do
    if [[ -x "${candidate}" ]]; then
      python_path="${candidate}"
      break
    fi
  done

  if [[ -z "${python_path}" ]]; then
    echo "::error::Could not find Python executable in ${python_dir}" >&2
    return 1
  fi

  # Set PYTHONPATH
  local site_packages
  site_packages="$("${python_path}" -c 'import site; print(site.getsitepackages()[0])' 2>/dev/null || true)"
  if [[ -n "${site_packages}" ]]; then
    echo "PYTHONPATH=${site_packages}" >> "${GITHUB_ENV}"
  fi

  # Ensure pip is available
  if ! "${python_path}" -m pip --version &>/dev/null; then
    echo "::warning::pip not found, attempting to install via ensurepip"
    "${python_path}" -m ensurepip --upgrade 2>/dev/null || true
  fi

  # Determine pip cache directory for output
  local cache_dir=""
  if [[ -n "${cache_type}" ]]; then
    cache_dir="$(get_python_cache_dir "${cache_type}" "${python_path}")"
    echo "cache-dir=${cache_dir}" >> "${GITHUB_OUTPUT}"
  fi

  local installed_version
  installed_version="$("${python_path}" --version 2>&1 | awk '{print $2}' || echo "${version}")"
  echo "::notice::Python ${installed_version} configured at ${python_path}"

  echo "python-version=${installed_version}" >> "${GITHUB_OUTPUT}"
  echo "python-path=${python_path}" >> "${GITHUB_OUTPUT}"
}
