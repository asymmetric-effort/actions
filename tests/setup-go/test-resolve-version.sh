#!/usr/bin/env bash
# Tests for actions/setup-go/scripts/resolve-version.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-go" && pwd)"
source "${ACTION_DIR}/scripts/resolve-version.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "get_go_platform"
# ============================================================

RUNNER_OS="Linux"
assert_eq "linux" "$(get_go_platform)" "Linux maps to linux"

RUNNER_OS="macOS"
assert_eq "darwin" "$(get_go_platform)" "macOS maps to darwin"

RUNNER_OS="Windows"
assert_eq "windows" "$(get_go_platform)" "Windows maps to windows"

RUNNER_OS="unsupported_os"
assert_failure "unsupported OS fails" get_go_platform

unset RUNNER_OS

# ============================================================
test_suite "get_go_arch"
# ============================================================

INPUT_ARCHITECTURE=""

RUNNER_ARCH="X64"
assert_eq "amd64" "$(get_go_arch)" "X64 maps to amd64"

RUNNER_ARCH="ARM64"
assert_eq "arm64" "$(get_go_arch)" "ARM64 maps to arm64"

RUNNER_ARCH="unsupported"
assert_failure "unsupported arch fails" get_go_arch

# architecture override
INPUT_ARCHITECTURE="arm64"
RUNNER_ARCH="X64"
assert_eq "arm64" "$(get_go_arch)" "architecture override takes precedence"

INPUT_ARCHITECTURE=""
unset RUNNER_ARCH

# ============================================================
test_suite "build_go_download_url"
# ============================================================

RUNNER_OS="Linux"
RUNNER_ARCH="X64"

url="$(build_go_download_url "1.26.2")"
assert_contains "${url}" "go1.26.2" "URL contains version"
assert_contains "${url}" "linux-amd64" "URL contains linux-amd64"
assert_contains "${url}" ".tar.gz" "Linux uses tar.gz"
assert_contains "${url}" "go.dev/dl/" "URL points to go.dev"

RUNNER_OS="macOS"
RUNNER_ARCH="ARM64"
url="$(build_go_download_url "1.22.0")"
assert_contains "${url}" "darwin-arm64" "macOS ARM64 correct"
assert_contains "${url}" ".tar.gz" "macOS uses tar.gz"

RUNNER_OS="Windows"
RUNNER_ARCH="X64"
url="$(build_go_download_url "1.22.0")"
assert_contains "${url}" "windows-amd64" "Windows x64 correct"
assert_contains "${url}" ".zip" "Windows uses zip"

unset RUNNER_OS RUNNER_ARCH

# ============================================================
test_suite "read_go_version_from_file (go.mod)"
# ============================================================

cat > "${tmp_dir}/go.mod" << 'GOMOD'
module example.com/test

go 1.26.2

require (
	github.com/something v1.0.0
)
GOMOD
result="$(read_go_version_from_file "${tmp_dir}/go.mod")"
assert_eq "1.26.2" "${result}" "reads 3-part version from go.mod"

cat > "${tmp_dir}/go2.mod" << 'GOMOD'
module example.com/test

go 1.22
GOMOD
# rename to go.mod for the function to detect it
cp "${tmp_dir}/go2.mod" "${tmp_dir}/gomod2/go.mod" 2>/dev/null || {
  mkdir -p "${tmp_dir}/gomod2"
  cp "${tmp_dir}/go2.mod" "${tmp_dir}/gomod2/go.mod"
}
result="$(read_go_version_from_file "${tmp_dir}/gomod2/go.mod")"
assert_eq "1.22" "${result}" "reads 2-part version from go.mod"

# ============================================================
test_suite "read_go_version_from_file (.go-version)"
# ============================================================

echo "1.25.0" > "${tmp_dir}/.go-version"
result="$(read_go_version_from_file "${tmp_dir}/.go-version")"
assert_eq "1.25.0" "${result}" "reads from .go-version file"

echo "go1.24.0" > "${tmp_dir}/.go-version-prefixed"
result="$(read_go_version_from_file "${tmp_dir}/.go-version-prefixed")"
assert_eq "1.24.0" "${result}" "strips go prefix from .go-version"

# nonexistent file
assert_failure "nonexistent file fails" read_go_version_from_file "${tmp_dir}/nonexistent"

# empty file
touch "${tmp_dir}/empty"
assert_failure "empty file fails" read_go_version_from_file "${tmp_dir}/empty"

# ============================================================
test_suite "resolve_setup_go_version (explicit)"
# ============================================================

INPUT_GO_VERSION="1.26.2"
INPUT_GO_VERSION_FILE=""
INPUT_CHECK_LATEST="false"
INPUT_ARCHITECTURE=""
INPUT_TOKEN=""
RUNNER_OS="Linux"
RUNNER_ARCH="X64"

true > "${GITHUB_OUTPUT}"
resolve_setup_go_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "go-version=1.26.2" "explicit version set"
assert_contains "${output}" "download-url=" "download URL set"
assert_contains "${output}" "linux-amd64" "correct platform in URL"

# ============================================================
test_suite "resolve_setup_go_version (strips go prefix)"
# ============================================================

INPUT_GO_VERSION="go1.25.0"
true > "${GITHUB_OUTPUT}"
resolve_setup_go_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "go-version=1.25.0" "go prefix stripped"

# ============================================================
test_suite "resolve_setup_go_version (from go.mod)"
# ============================================================

INPUT_GO_VERSION=""
INPUT_GO_VERSION_FILE="${tmp_dir}/go.mod"

true > "${GITHUB_OUTPUT}"
resolve_setup_go_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "go-version=1.26.2" "version from go.mod"

# ============================================================
test_suite "resolve_setup_go_version (darwin arm64 URL)"
# ============================================================

INPUT_GO_VERSION="1.22.0"
INPUT_GO_VERSION_FILE=""
RUNNER_OS="macOS"
RUNNER_ARCH="ARM64"

true > "${GITHUB_OUTPUT}"
resolve_setup_go_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "darwin-arm64" "darwin arm64 in URL"

# ============================================================
test_suite "resolve_setup_go_version (windows zip)"
# ============================================================

INPUT_GO_VERSION="1.22.0"
RUNNER_OS="Windows"
RUNNER_ARCH="X64"

true > "${GITHUB_OUTPUT}"
resolve_setup_go_version
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" ".zip" "windows uses zip extension"

# Cleanup
unset INPUT_GO_VERSION INPUT_GO_VERSION_FILE INPUT_CHECK_LATEST INPUT_ARCHITECTURE INPUT_TOKEN RUNNER_OS RUNNER_ARCH

# ============================================================
test_summary
