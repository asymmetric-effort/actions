#!/usr/bin/env bash
# init.sh — Download CodeQL CLI and initialize databases.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Build the download URL for the CodeQL bundle.
# Args: version (e.g., "2.16.0" or "latest")
build_codeql_download_url() {
  local version="$1"
  if [[ "${version}" == "latest" ]]; then
    echo "https://github.com/github/codeql-action/releases/latest/download/codeql-bundle-linux64.tar.gz"
  else
    echo "https://github.com/github/codeql-action/releases/download/codeql-bundle-v${version}/codeql-bundle-linux64.tar.gz"
  fi
}

# Resolve the "latest" version tag from the GitHub API.
# Returns the version string (e.g., "2.16.0").
resolve_latest_version() {
  local token="${1:-}"
  local auth_header=""
  if [[ -n "${token}" ]]; then
    auth_header="Authorization: token ${token}"
  fi

  local release_url="https://api.github.com/repos/github/codeql-action/releases/latest"
  local tag_name
  if [[ -n "${auth_header}" ]]; then
    tag_name="$(curl -fsSL -H "${auth_header}" "${release_url}" | jq -r '.tag_name')"
  else
    tag_name="$(curl -fsSL "${release_url}" | jq -r '.tag_name')"
  fi

  # Strip "codeql-bundle-v" prefix if present
  tag_name="${tag_name#codeql-bundle-v}"
  echo "${tag_name}"
}

# Download and extract the CodeQL CLI bundle.
# Args: url, install_dir, token
download_codeql_cli() {
  local url="$1"
  local install_dir="$2"
  local token="${3:-}"

  mkdir -p "${install_dir}"

  echo "::notice::Downloading CodeQL CLI from ${url}"
  local curl_args=(-fsSL)
  if [[ -n "${token}" ]]; then
    curl_args+=(-H "Authorization: token ${token}")
  fi

  curl "${curl_args[@]}" "${url}" | tar -xz -C "${install_dir}"

  if [[ ! -x "${install_dir}/codeql/codeql" ]]; then
    echo "::error::CodeQL CLI binary not found after extraction"
    return 1
  fi

  echo "::notice::CodeQL CLI installed to ${install_dir}/codeql"
}

# Initialize CodeQL databases for each language.
# Args: languages (comma-separated), source_root, db_dir, codeql_bin
init_databases() {
  local languages="$1"
  local source_root="$2"
  local db_dir="$3"
  local codeql_bin="$4"

  mkdir -p "${db_dir}"

  local IFS=','
  for lang in ${languages}; do
    local db_path="${db_dir}/${lang}"
    echo "::notice::Initializing CodeQL database for language: ${lang}"

    local init_args=(database init --language="${lang}" --source-root="${source_root}")

    "${codeql_bin}" "${init_args[@]}" "${db_path}"
    echo "::notice::Database initialized at ${db_path}"
  done
}

# Main entry point: download CodeQL CLI and initialize databases.
init_codeql() {
  local languages="${INPUT_LANGUAGES:-}"
  # shellcheck disable=SC2034
  local config_file="${INPUT_CONFIG_FILE:-}"
  # shellcheck disable=SC2034
  local queries="${INPUT_QUERIES:-}"
  local tools="${INPUT_TOOLS:-latest}"
  local token="${INPUT_TOKEN:-}"

  if [[ -z "${languages}" ]]; then
    echo "::error::Input 'languages' is required but was not provided"
    return 1
  fi

  # Normalize languages
  local normalized_languages
  normalized_languages="$(list_codeql_languages "${languages}")"
  echo "::notice::Languages to analyze: ${normalized_languages}"

  # Determine install directory
  local install_dir="${RUNNER_TOOL_CACHE:-${HOME}}/codeql-tools"

  # Build download URL
  local download_url
  download_url="$(build_codeql_download_url "${tools}")"

  # Download and extract CodeQL CLI
  download_codeql_cli "${download_url}" "${install_dir}" "${token}"

  # Add codeql to PATH
  local codeql_bin_dir="${install_dir}/codeql"
  echo "${codeql_bin_dir}" >> "${GITHUB_PATH}"
  export PATH="${codeql_bin_dir}:${PATH}"

  local codeql_bin="${codeql_bin_dir}/codeql"

  # Initialize databases
  local db_dir
  db_dir="$(get_codeql_databases_dir)"
  init_databases "${normalized_languages}" "." "${db_dir}" "${codeql_bin}"

  # Export CODEQL_DATABASES for subsequent steps
  echo "CODEQL_DATABASES=${db_dir}" >> "${GITHUB_ENV}"

  # Also export the tool directory for shared.sh
  echo "CODEQL_TOOL_DIR=${codeql_bin_dir}" >> "${GITHUB_ENV}"

  # Set outputs
  echo "codeql-path=${codeql_bin}" >> "${GITHUB_OUTPUT}"

  echo "::notice::CodeQL initialization complete"
}
