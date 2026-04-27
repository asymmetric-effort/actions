#!/usr/bin/env bash
# validate.sh — Validate the environment before publishing.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Verify Node.js and npm are available
check_node_npm() {
  if ! command -v node >/dev/null 2>&1; then
    echo "::error::Node.js is not installed. Use actions/setup-node or setup-bun before this action." >&2
    return 1
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "::error::npm is not installed. Use actions/setup-node before this action." >&2
    return 1
  fi

  echo "::notice::Node $(node --version), npm $(npm --version)"
}

# Verify package.json exists and has required fields
check_package_json() {
  local pkg_dir="$1"
  local pkg_file="${pkg_dir}/package.json"

  if [[ ! -f "${pkg_file}" ]]; then
    echo "::error::package.json not found in ${pkg_dir}" >&2
    return 1
  fi

  # Verify 'name' field exists
  local pkg_name
  pkg_name="$(grep -oP '"name"\s*:\s*"\K[^"]+' "${pkg_file}" | head -1 || true)"
  if [[ -z "${pkg_name}" ]]; then
    echo "::error::package.json is missing the 'name' field" >&2
    return 1
  fi

  # Verify 'version' field exists
  local pkg_version
  pkg_version="$(grep -oP '"version"\s*:\s*"\K[^"]+' "${pkg_file}" | head -1 || true)"
  if [[ -z "${pkg_version}" ]]; then
    echo "::error::package.json is missing the 'version' field" >&2
    return 1
  fi

  echo "::notice::Package: ${pkg_name}@${pkg_version}"
}

# Verify OIDC is available (ACTIONS_ID_TOKEN_REQUEST_URL must be set)
check_oidc_available() {
  if [[ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ]]; then
    echo "::error::OIDC token not available. Ensure the workflow has 'id-token: write' permission and the npm package has trusted publishing configured." >&2
    echo "::error::See https://docs.npmjs.com/generating-provenance-statements for setup instructions." >&2
    return 1
  fi

  echo "::notice::OIDC token endpoint available"
}

# Main entry point
validate_environment() {
  local pkg_dir="${INPUT_PACKAGE_DIR:-.}"

  check_node_npm
  check_package_json "${pkg_dir}"
  check_oidc_available
}
