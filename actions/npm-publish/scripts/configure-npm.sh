#!/usr/bin/env bash
# configure-npm.sh — Configure npm for OIDC-based publishing.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Extract the registry hostname from a full URL
# e.g., https://registry.npmjs.org -> registry.npmjs.org
get_registry_host() {
  local registry_url="$1"
  echo "${registry_url}" | sed 's|^https\?://||' | sed 's|/$||'
}

# Generate .npmrc content for OIDC auth
generate_npmrc() {
  local registry_url="$1"
  local registry_host
  registry_host="$(get_registry_host "${registry_url}")"

  # The //registry.npmjs.org/:_authToken line is set at publish time
  # via the NPM_CONFIG_PROVENANCE and npm's built-in OIDC flow.
  # We configure the registry here so npm knows where to publish.
  echo "registry=${registry_url}"
  echo "//${registry_host}/:_authToken=\${NODE_AUTH_TOKEN}"
}

# Write .npmrc to the package directory
write_npmrc() {
  local pkg_dir="$1"
  local registry_url="$2"
  local npmrc_path="${pkg_dir}/.npmrc"

  # Back up existing .npmrc if present
  if [[ -f "${npmrc_path}" ]]; then
    cp "${npmrc_path}" "${npmrc_path}.bak"
    echo "::notice::Backed up existing .npmrc to .npmrc.bak"
  fi

  generate_npmrc "${registry_url}" > "${npmrc_path}"
  echo "::notice::Wrote .npmrc to ${npmrc_path}"
}

# Main entry point
configure_npm_oidc() {
  local pkg_dir="${INPUT_PACKAGE_DIR:-.}"
  local registry="${INPUT_REGISTRY:-https://registry.npmjs.org}"

  # If actions/setup-node already configured npm auth (via NPM_CONFIG_USERCONFIG),
  # preserve it — it has the correct OIDC token setup.
  if [[ -n "${NPM_CONFIG_USERCONFIG:-}" ]] && [[ -f "${NPM_CONFIG_USERCONFIG}" ]]; then
    echo "::notice::Using existing .npmrc from NPM_CONFIG_USERCONFIG=${NPM_CONFIG_USERCONFIG}"
    return 0
  fi

  write_npmrc "${pkg_dir}" "${registry}"
}
