#!/usr/bin/env bash
# Tests for actions/npm-publish/scripts/validate.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/npm-publish" && pwd)"
source "${ACTION_DIR}/scripts/validate.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "check_node_npm"
# ============================================================

assert_success "node and npm are available" check_node_npm

# ============================================================
test_suite "check_package_json"
# ============================================================

# Valid package.json
cat > "${tmp_dir}/package.json" << 'JSON'
{
  "name": "@asymmetric-effort/test-pkg",
  "version": "1.0.0",
  "description": "test"
}
JSON

assert_success "valid package.json passes" check_package_json "${tmp_dir}"

# Missing package.json
assert_failure "missing package.json fails" check_package_json "${tmp_dir}/nonexistent"

# Missing name field
cat > "${tmp_dir}/no-name/package.json" 2>/dev/null || {
  mkdir -p "${tmp_dir}/no-name"
  echo '{"version": "1.0.0"}' > "${tmp_dir}/no-name/package.json"
}
assert_failure "package.json without name fails" check_package_json "${tmp_dir}/no-name"

# Missing version field
mkdir -p "${tmp_dir}/no-version"
echo '{"name": "test"}' > "${tmp_dir}/no-version/package.json"
assert_failure "package.json without version fails" check_package_json "${tmp_dir}/no-version"

# ============================================================
test_suite "check_oidc_available"
# ============================================================

# With OIDC available
ACTIONS_ID_TOKEN_REQUEST_URL="https://token.actions.githubusercontent.com"
assert_success "OIDC available passes" check_oidc_available

# Without OIDC
unset ACTIONS_ID_TOKEN_REQUEST_URL
assert_failure "OIDC not available fails" check_oidc_available

# ============================================================
test_suite "validate_environment"
# ============================================================

# Full valid environment
ACTIONS_ID_TOKEN_REQUEST_URL="https://token.actions.githubusercontent.com"
INPUT_PACKAGE_DIR="${tmp_dir}"

assert_success "full valid environment passes" validate_environment

# Missing OIDC
unset ACTIONS_ID_TOKEN_REQUEST_URL
assert_failure "validate fails without OIDC" validate_environment

# Cleanup
unset INPUT_PACKAGE_DIR

# ============================================================
test_summary
