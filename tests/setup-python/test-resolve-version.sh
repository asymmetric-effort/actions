#!/usr/bin/env bash
# Tests for actions/setup-python/scripts/resolve-version.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-python" && pwd)"
source "${ACTION_DIR}/scripts/resolve-version.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT so we don't write to real files
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "read_python_version_from_file"
# ============================================================

# Plain .python-version file
echo "3.12.1" > "${tmp_dir}/.python-version"
result="$(read_python_version_from_file "${tmp_dir}/.python-version")"
assert_eq "3.12.1" "${result}" "reads plain version from .python-version"

# Version with python- prefix (pyenv style)
echo "python-3.11.5" > "${tmp_dir}/.python-version-pyenv"
result="$(read_python_version_from_file "${tmp_dir}/.python-version-pyenv")"
assert_eq "3.11.5" "${result}" "strips python- prefix"

# Version with whitespace/newline
printf "  3.10.0  \n" > "${tmp_dir}/.python-version-ws"
result="$(read_python_version_from_file "${tmp_dir}/.python-version-ws")"
assert_eq "3.10.0" "${result}" "strips whitespace"

# Nonexistent file
assert_failure "nonexistent file fails" read_python_version_from_file "${tmp_dir}/nonexistent"

# Empty file
touch "${tmp_dir}/empty"
assert_failure "empty file fails" read_python_version_from_file "${tmp_dir}/empty"

# ============================================================
test_suite "find_python_in_tool_cache"
# ============================================================

# Create mock tool cache
TOOL_CACHE="${tmp_dir}/tool-cache"
mkdir -p "${TOOL_CACHE}/Python/3.12.1/x64"
mkdir -p "${TOOL_CACHE}/Python/3.11.5/x64"
mkdir -p "${TOOL_CACHE}/Python/3.11.8/x64"

# Exact version match
result="$(find_python_in_tool_cache "3.12.1" "x64")"
assert_eq "${TOOL_CACHE}/Python/3.12.1/x64" "${result}" "finds exact version in tool cache"

# Exact version match, different architecture
assert_failure "wrong architecture fails" find_python_in_tool_cache "3.12.1" "arm64"

# Major.minor match (should find latest patch)
result="$(find_python_in_tool_cache "3.11" "x64")"
assert_contains "${result}" "3.11" "finds major.minor match"
assert_contains "${result}" "/x64" "includes architecture in path"

# Version not in cache
assert_failure "missing version fails" find_python_in_tool_cache "3.9.0" "x64"

# ============================================================
test_suite "build_python_download_url"
# ============================================================

url="$(build_python_download_url "3.12.1")"
assert_eq "https://www.python.org/ftp/python/3.12.1/Python-3.12.1.tgz" "${url}" "builds correct download URL"

url="$(build_python_download_url "3.11.5")"
assert_contains "${url}" "3.11.5" "URL contains version"
assert_contains "${url}" ".tgz" "URL ends with .tgz"

# ============================================================
test_suite "resolve_python_version (explicit version)"
# ============================================================

INPUT_PYTHON_VERSION="3.12.1"
INPUT_PYTHON_VERSION_FILE=""
INPUT_ARCHITECTURE="x64"

true > "${GITHUB_OUTPUT}"
resolve_python_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "python-version=3.12.1" "explicit version set in output"
assert_contains "${output}" "download-url=" "download URL set in output"
assert_contains "${output}" "Python-3.12.1.tgz" "correct version in URL"

# ============================================================
test_suite "resolve_python_version (strips v prefix)"
# ============================================================

INPUT_PYTHON_VERSION="v3.11.0"
true > "${GITHUB_OUTPUT}"
resolve_python_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "python-version=3.11.0" "v prefix stripped"

# ============================================================
test_suite "resolve_python_version (from file)"
# ============================================================

INPUT_PYTHON_VERSION=""
INPUT_PYTHON_VERSION_FILE="${tmp_dir}/.python-version"
echo "3.10.8" > "${tmp_dir}/.python-version"

true > "${GITHUB_OUTPUT}"
resolve_python_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "python-version=3.10.8" "version resolved from file"

# ============================================================
test_suite "resolve_python_version (explicit takes precedence over file)"
# ============================================================

INPUT_PYTHON_VERSION="3.12.0"
INPUT_PYTHON_VERSION_FILE="${tmp_dir}/.python-version"
echo "3.10.8" > "${tmp_dir}/.python-version"

true > "${GITHUB_OUTPUT}"
resolve_python_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "python-version=3.12.0" "explicit version takes precedence over file"

# ============================================================
test_suite "resolve_python_version (no version available)"
# ============================================================

INPUT_PYTHON_VERSION=""
INPUT_PYTHON_VERSION_FILE="${tmp_dir}/nonexistent"

true > "${GITHUB_OUTPUT}"
assert_failure "no version available fails" resolve_python_version

# Cleanup
unset INPUT_PYTHON_VERSION INPUT_PYTHON_VERSION_FILE INPUT_ARCHITECTURE TOOL_CACHE

# ============================================================
test_summary
