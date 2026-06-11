#!/usr/bin/env bash
# Tests for actions/setup-node/scripts/resolve-version.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-node" && pwd)"
source "${ACTION_DIR}/scripts/resolve-version.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT so we don't write to real files
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -f "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "get_node_platform"
# ============================================================

RUNNER_OS="Linux"
assert_eq "linux" "$(get_node_platform)" "Linux maps to linux"

RUNNER_OS="macOS"
assert_eq "darwin" "$(get_node_platform)" "macOS maps to darwin"

RUNNER_OS="Windows"
assert_eq "win" "$(get_node_platform)" "Windows maps to win"

RUNNER_OS="unsupported_os"
assert_failure "unsupported OS fails" get_node_platform

# Reset
unset RUNNER_OS

# ============================================================
test_suite "get_node_arch"
# ============================================================

INPUT_ARCHITECTURE="x64"
assert_eq "x64" "$(get_node_arch)" "x64 input maps to x64"

INPUT_ARCHITECTURE="arm64"
assert_eq "arm64" "$(get_node_arch)" "arm64 input maps to arm64"

INPUT_ARCHITECTURE="unsupported_arch"
assert_failure "unsupported arch input fails" get_node_arch

# Test fallback to RUNNER_ARCH
INPUT_ARCHITECTURE=""

RUNNER_ARCH="X64"
assert_eq "x64" "$(get_node_arch)" "RUNNER_ARCH X64 maps to x64"

RUNNER_ARCH="ARM64"
assert_eq "arm64" "$(get_node_arch)" "RUNNER_ARCH ARM64 maps to arm64"

RUNNER_ARCH="unsupported_arch"
assert_failure "unsupported RUNNER_ARCH fails" get_node_arch

# Reset
unset RUNNER_ARCH INPUT_ARCHITECTURE

# ============================================================
test_suite "build_node_download_url"
# ============================================================

RUNNER_OS="Linux"
INPUT_ARCHITECTURE="x64"

url="$(build_node_download_url "20.11.0")"
assert_contains "${url}" "node-v20.11.0" "URL contains versioned name"
assert_contains "${url}" "linux-x64" "URL contains platform-arch"
assert_contains "${url}" ".tar.gz" "URL ends with .tar.gz"
assert_contains "${url}" "https://nodejs.org/dist/v20.11.0/" "URL uses correct dist path"

RUNNER_OS="macOS"
INPUT_ARCHITECTURE="arm64"
url="$(build_node_download_url "18.19.0")"
assert_contains "${url}" "darwin-arm64" "macOS ARM64 URL correct"
assert_contains "${url}" "node-v18.19.0" "version in URL"

# Reset
unset RUNNER_OS INPUT_ARCHITECTURE

# ============================================================
test_suite "read_version_from_package_json"
# ============================================================

result="$(echo '{"engines":{"node":">=18.0.0"}}' | read_version_from_package_json)"
assert_eq ">=18.0.0" "${result}" "reads from engines.node"

result="$(echo '{"engines":{"node":"20.11.0"}}' | read_version_from_package_json)"
assert_eq "20.11.0" "${result}" "reads exact version from engines.node"

assert_failure "returns failure for no node engine" bash -c 'echo "{\"name\":\"test\"}" | read_version_from_package_json'

assert_failure "returns failure for only npm engine" bash -c 'echo "{\"engines\":{\"npm\":\">=9.0.0\"}}" | read_version_from_package_json'

# ============================================================
test_suite "read_node_version_from_file"
# ============================================================

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"; rm -f "${GITHUB_OUTPUT}"' EXIT

# .nvmrc
echo "v20.11.0" > "${tmp_dir}/.nvmrc"
result="$(read_node_version_from_file "${tmp_dir}/.nvmrc")"
assert_eq "20.11.0" "${result}" "reads from .nvmrc (strips v prefix)"

# .nvmrc without v prefix
echo "18.19.0" > "${tmp_dir}/.nvmrc"
result="$(read_node_version_from_file "${tmp_dir}/.nvmrc")"
assert_eq "18.19.0" "${result}" "reads from .nvmrc without v prefix"

# .node-version
echo "v20.11.0" > "${tmp_dir}/.node-version"
result="$(read_node_version_from_file "${tmp_dir}/.node-version")"
assert_eq "20.11.0" "${result}" "reads from .node-version (strips v prefix)"

# package.json
echo '{"engines":{"node":"20.11.0"}}' > "${tmp_dir}/package.json"
result="$(read_node_version_from_file "${tmp_dir}/package.json")"
assert_eq "20.11.0" "${result}" "reads from package.json engines.node"

# nonexistent file
assert_failure "nonexistent file fails" read_node_version_from_file "${tmp_dir}/nonexistent"

# empty file
touch "${tmp_dir}/empty"
assert_failure "empty file fails" read_node_version_from_file "${tmp_dir}/empty"

# ============================================================
test_suite "resolve_node_version (explicit)"
# ============================================================

# Mock environment for resolve_node_version
INPUT_NODE_VERSION="20.11.0"
INPUT_NODE_VERSION_FILE=""
INPUT_TOKEN=""
INPUT_ARCHITECTURE="x64"
INPUT_CACHE=""
RUNNER_OS="Linux"

true > "${GITHUB_OUTPUT}"
resolve_node_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "node-version=20.11.0" "explicit version set in output"
assert_contains "${output}" "download-url=" "download URL set in output"
assert_contains "${output}" "linux-x64" "correct platform in URL"

# ============================================================
test_suite "resolve_node_version (strips v prefix)"
# ============================================================

INPUT_NODE_VERSION="v18.19.0"
true > "${GITHUB_OUTPUT}"
resolve_node_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "node-version=18.19.0" "v prefix stripped"

# ============================================================
test_suite "resolve_node_version (from file)"
# ============================================================

INPUT_NODE_VERSION=""
INPUT_NODE_VERSION_FILE="${tmp_dir}/.nvmrc"
echo "22.1.0" > "${tmp_dir}/.nvmrc"

true > "${GITHUB_OUTPUT}"
resolve_node_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "node-version=22.1.0" "version resolved from .nvmrc file"

# ============================================================
test_suite "resolve_node_version (from .node-version file)"
# ============================================================

INPUT_NODE_VERSION=""
INPUT_NODE_VERSION_FILE="${tmp_dir}/.node-version"
echo "v21.5.0" > "${tmp_dir}/.node-version"

true > "${GITHUB_OUTPUT}"
resolve_node_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "node-version=21.5.0" "version resolved from .node-version file"

# Cleanup
unset INPUT_NODE_VERSION INPUT_NODE_VERSION_FILE INPUT_TOKEN INPUT_ARCHITECTURE INPUT_CACHE RUNNER_OS

# ============================================================
test_summary
