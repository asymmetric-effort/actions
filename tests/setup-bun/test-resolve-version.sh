#!/usr/bin/env bash
# Tests for actions/setup-bun/scripts/resolve-version.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-bun" && pwd)"
source "${ACTION_DIR}/scripts/resolve-version.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT so we don't write to real files
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -f "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "get_platform"
# ============================================================

RUNNER_OS="Linux"
assert_eq "linux" "$(get_platform)" "Linux maps to linux"

RUNNER_OS="macOS"
assert_eq "darwin" "$(get_platform)" "macOS maps to darwin"

RUNNER_OS="Windows"
assert_eq "windows" "$(get_platform)" "Windows maps to windows"

RUNNER_OS="unsupported_os"
assert_failure "unsupported OS fails" get_platform

# Reset
unset RUNNER_OS

# ============================================================
test_suite "get_arch"
# ============================================================

RUNNER_ARCH="X64"
assert_eq "x64" "$(get_arch)" "X64 maps to x64"

RUNNER_ARCH="ARM64"
assert_eq "aarch64" "$(get_arch)" "ARM64 maps to aarch64"

RUNNER_ARCH="unsupported_arch"
assert_failure "unsupported arch fails" get_arch

# Reset
unset RUNNER_ARCH

# ============================================================
test_suite "build_download_url"
# ============================================================

RUNNER_OS="Linux"
RUNNER_ARCH="X64"

url="$(build_download_url "1.0.5")"
assert_contains "${url}" "bun-v1.0.5" "URL contains versioned tag"
assert_contains "${url}" "linux-x64" "URL contains platform-arch"
assert_contains "${url}" ".zip" "URL ends with .zip"

url="$(build_download_url "canary")"
assert_contains "${url}" "/canary/" "Canary URL uses canary path"
assert_contains "${url}" "linux-x64" "Canary URL has platform-arch"

RUNNER_OS="macOS"
RUNNER_ARCH="ARM64"
url="$(build_download_url "1.2.0")"
assert_contains "${url}" "darwin-aarch64" "macOS ARM64 URL correct"

# Reset
unset RUNNER_OS RUNNER_ARCH

# ============================================================
test_suite "read_version_from_package_json"
# ============================================================

result="$(echo '{"packageManager":"bun@1.1.0"}' | read_version_from_package_json)"
assert_eq "1.1.0" "${result}" "reads from packageManager"

result="$(echo '{"engines":{"bun":">=1.0.0"}}' | read_version_from_package_json)"
assert_eq ">=1.0.0" "${result}" "reads from engines.bun"

result="$(echo '{"packageManager":"bun@1.2.0","engines":{"bun":">=1.0.0"}}' | read_version_from_package_json)"
assert_eq "1.2.0" "${result}" "packageManager takes priority"

assert_failure "returns failure for no bun" bash -c 'echo "{\"name\":\"test\"}" | read_version_from_package_json'

assert_failure "returns failure for npm packageManager" bash -c 'echo "{\"packageManager\":\"npm@9.0.0\"}" | read_version_from_package_json'

# ============================================================
test_suite "read_version_from_tool_versions"
# ============================================================

result="$(printf 'nodejs 20.0.0\nbun 1.0.5\npython 3.11' | read_version_from_tool_versions)"
assert_eq "1.0.5" "${result}" "reads bun from .tool-versions"

assert_failure "no bun listed" bash -c 'echo "nodejs 20.0.0" | read_version_from_tool_versions'

result="$(echo "  bun   1.0.5  " | read_version_from_tool_versions)"
assert_eq "1.0.5" "${result}" "handles extra whitespace"

result="$(echo "bun 1.2.3" | read_version_from_tool_versions)"
assert_eq "1.2.3" "${result}" "single entry"

# ============================================================
test_suite "read_version_from_file"
# ============================================================

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"; rm -f "${GITHUB_OUTPUT}"' EXIT

# package.json
echo '{"packageManager":"bun@1.3.0"}' > "${tmp_dir}/package.json"
result="$(read_version_from_file "${tmp_dir}/package.json")"
assert_eq "1.3.0" "${result}" "reads from package.json file"

# .tool-versions
printf 'bun 1.4.0\n' > "${tmp_dir}/.tool-versions"
result="$(read_version_from_file "${tmp_dir}/.tool-versions")"
assert_eq "1.4.0" "${result}" "reads from .tool-versions file"

# plain text
echo "1.5.0" > "${tmp_dir}/.bun-version"
result="$(read_version_from_file "${tmp_dir}/.bun-version")"
assert_eq "1.5.0" "${result}" "reads from plain text file"

# nonexistent file
assert_failure "nonexistent file fails" read_version_from_file "${tmp_dir}/nonexistent"

# empty file
touch "${tmp_dir}/empty"
assert_failure "empty file fails" read_version_from_file "${tmp_dir}/empty"

# ============================================================
test_suite "resolve_version (explicit)"
# ============================================================

# Mock environment for resolve_version
# shellcheck disable=SC2034  # Variables consumed by sourced resolve-version.sh
INPUT_BUN_VERSION="1.0.5"
INPUT_BUN_VERSION_FILE=""
INPUT_TOKEN=""
RUNNER_OS="Linux"
RUNNER_ARCH="X64"

true > "${GITHUB_OUTPUT}"
resolve_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "bun-version=1.0.5" "explicit version set in output"
assert_contains "${output}" "download-url=" "download URL set in output"
assert_contains "${output}" "linux-x64" "correct platform in URL"

# ============================================================
test_suite "resolve_version (canary)"
# ============================================================

INPUT_BUN_VERSION="canary"
true > "${GITHUB_OUTPUT}"
resolve_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "bun-version=canary" "canary version in output"
assert_contains "${output}" "/canary/" "canary in download URL"

# ============================================================
test_suite "resolve_version (strips v prefix)"
# ============================================================

INPUT_BUN_VERSION="v1.2.3"
true > "${GITHUB_OUTPUT}"
resolve_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "bun-version=1.2.3" "v prefix stripped"

# ============================================================
test_suite "resolve_version (from file)"
# ============================================================

# shellcheck disable=SC2034
INPUT_BUN_VERSION="latest"
# shellcheck disable=SC2034
INPUT_BUN_VERSION_FILE="${tmp_dir}/package.json"
echo '{"packageManager":"bun@1.6.0"}' > "${tmp_dir}/package.json"

true > "${GITHUB_OUTPUT}"
resolve_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "bun-version=1.6.0" "version resolved from file"

# Cleanup
unset INPUT_BUN_VERSION INPUT_BUN_VERSION_FILE INPUT_TOKEN RUNNER_OS RUNNER_ARCH

# ============================================================
test_summary
