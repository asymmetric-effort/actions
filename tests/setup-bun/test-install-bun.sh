#!/usr/bin/env bash
# Tests for actions/setup-bun/scripts/install-bun.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-bun" && pwd)"
source "${ACTION_DIR}/scripts/install-bun.sh"

# ============================================================
# Setup
# ============================================================
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
GITHUB_PATH="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}" "${GITHUB_PATH}"' EXIT

# ============================================================
test_suite "find_extracted_dir"
# ============================================================

# Create a mock extracted zip structure
mkdir -p "${tmp_dir}/extract1/bun-linux-x64"
touch "${tmp_dir}/extract1/bun-linux-x64/bun"

result="$(find_extracted_dir "${tmp_dir}/extract1")"
assert_contains "${result}" "bun-linux-x64" "finds bun-* subdirectory"

# No subdirectory — returns parent
mkdir -p "${tmp_dir}/extract2"
touch "${tmp_dir}/extract2/bun"

result="$(find_extracted_dir "${tmp_dir}/extract2")"
assert_eq "${tmp_dir}/extract2" "${result}" "returns parent when no subdirectory"

# ============================================================
test_suite "find_bun_binary"
# ============================================================

# Linux binary
mkdir -p "${tmp_dir}/bin1"
touch "${tmp_dir}/bin1/bun"
chmod +x "${tmp_dir}/bin1/bun"

result="$(find_bun_binary "${tmp_dir}/bin1")"
assert_eq "${tmp_dir}/bin1/bun" "${result}" "finds linux bun binary"

# Windows binary
mkdir -p "${tmp_dir}/bin2"
touch "${tmp_dir}/bin2/bun.exe"
chmod +x "${tmp_dir}/bin2/bun.exe"

result="$(find_bun_binary "${tmp_dir}/bin2")"
assert_eq "${tmp_dir}/bin2/bun.exe" "${result}" "finds windows bun.exe binary"

# bun.exe takes priority over bun
mkdir -p "${tmp_dir}/bin3"
touch "${tmp_dir}/bin3/bun" "${tmp_dir}/bin3/bun.exe"
result="$(find_bun_binary "${tmp_dir}/bin3")"
assert_eq "${tmp_dir}/bin3/bun.exe" "${result}" "bun.exe takes priority"

# Missing binary
mkdir -p "${tmp_dir}/bin4"
assert_failure "missing binary fails" find_bun_binary "${tmp_dir}/bin4"

# ============================================================
test_suite "configure_bun"
# ============================================================

# Create a fake bun that prints a version
mkdir -p "${tmp_dir}/fake-bun"
cat > "${tmp_dir}/fake-bun/bun" << 'SCRIPT'
#!/usr/bin/env bash
echo "1.0.5"
SCRIPT
chmod +x "${tmp_dir}/fake-bun/bun"

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"

configure_bun "${tmp_dir}/fake-bun/bun" "${tmp_dir}/fake-bun"

output="$(cat "${GITHUB_OUTPUT}")"
path_output="$(cat "${GITHUB_PATH}")"

assert_contains "${output}" "bun-version=1.0.5" "sets bun-version output"
assert_contains "${output}" "bun-path=${tmp_dir}/fake-bun/bun" "sets bun-path output"
assert_contains "${path_output}" "${tmp_dir}/fake-bun" "adds to GITHUB_PATH"

# ============================================================
test_suite "install_bun (cache hit)"
# ============================================================

# Set up a cached bun installation
mkdir -p "${tmp_dir}/tool-cache/bun/1.0.5"
cp "${tmp_dir}/fake-bun/bun" "${tmp_dir}/tool-cache/bun/1.0.5/bun"
chmod +x "${tmp_dir}/tool-cache/bun/1.0.5/bun"

# shellcheck disable=SC2034  # Variables consumed by sourced install-bun.sh
RESOLVED_VERSION="1.0.5"
DOWNLOAD_URL="https://example.com/bun.zip"
CACHE_HIT="true"
TOOL_CACHE="${tmp_dir}/tool-cache"

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"

install_bun

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "bun-version=1.0.5" "cache hit: version output set"
assert_contains "${output}" "bun-path=" "cache hit: path output set"

# ============================================================
test_summary
