#!/usr/bin/env bash
# Tests for actions/setup-node/scripts/install-node.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-node" && pwd)"
source "${ACTION_DIR}/scripts/install-node.sh"

# ============================================================
# Setup
# ============================================================
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
GITHUB_PATH="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}" "${GITHUB_PATH}"' EXIT

# ============================================================
test_suite "configure_node"
# ============================================================

# Create a fake node installation
mkdir -p "${tmp_dir}/fake-node/bin"
cat > "${tmp_dir}/fake-node/bin/node" << 'SCRIPT'
#!/usr/bin/env bash
echo "v20.11.0"
SCRIPT
chmod +x "${tmp_dir}/fake-node/bin/node"

RESOLVED_VERSION="20.11.0"
INPUT_REGISTRY_URL=""

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"

configure_node "${tmp_dir}/fake-node"

output="$(cat "${GITHUB_OUTPUT}")"
path_output="$(cat "${GITHUB_PATH}")"

assert_contains "${output}" "node-version=20.11.0" "sets node-version output"
assert_contains "${path_output}" "${tmp_dir}/fake-node/bin" "adds bin dir to GITHUB_PATH"

# ============================================================
test_suite "configure_node (with registry URL)"
# ============================================================

INPUT_REGISTRY_URL="https://npm.pkg.github.com"
RESOLVED_VERSION="20.11.0"

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"

configure_node "${tmp_dir}/fake-node"

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "node-version=20.11.0" "sets node-version with registry"

# Verify .npmrc was written
assert_file_exists "${HOME}/.npmrc" ".npmrc file created"
npmrc_content="$(cat "${HOME}/.npmrc")"
assert_contains "${npmrc_content}" "registry=https://npm.pkg.github.com" ".npmrc contains registry URL"

# Cleanup .npmrc
rm -f "${HOME}/.npmrc"

# ============================================================
test_suite "configure_registry"
# ============================================================

configure_registry "https://registry.npmjs.org/"

assert_file_exists "${HOME}/.npmrc" ".npmrc created by configure_registry"
npmrc_content="$(cat "${HOME}/.npmrc")"
assert_contains "${npmrc_content}" "registry=https://registry.npmjs.org" "registry URL written (trailing slash stripped)"

rm -f "${HOME}/.npmrc"

# ============================================================
test_suite "install_node (cache hit)"
# ============================================================

# Set up a cached node installation
mkdir -p "${tmp_dir}/tool-cache/node/20.11.0/bin"
cp "${tmp_dir}/fake-node/bin/node" "${tmp_dir}/tool-cache/node/20.11.0/bin/node"
chmod +x "${tmp_dir}/tool-cache/node/20.11.0/bin/node"

RESOLVED_VERSION="20.11.0"
DOWNLOAD_URL="https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.gz"
CACHE_HIT="true"
TOOL_CACHE="${tmp_dir}/tool-cache"
INPUT_REGISTRY_URL=""

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"

install_node

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "node-version=20.11.0" "cache hit: version output set"

path_output="$(cat "${GITHUB_PATH}")"
assert_contains "${path_output}" "tool-cache/node/20.11.0/bin" "cache hit: PATH output set"

# ============================================================
test_summary
