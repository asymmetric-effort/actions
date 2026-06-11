#!/usr/bin/env bash
# Tests for actions/checkout/scripts/checkout.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/checkout" && pwd)"
source "${ACTION_DIR}/scripts/checkout.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT so we don't write to real files
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -f "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "build_clone_url"
# ============================================================

url="$(build_clone_url "ghp_abc123" "owner/repo")"
assert_eq "https://x-access-token:ghp_abc123@github.com/owner/repo.git" "${url}" "builds correct clone URL"

url="$(build_clone_url "mytoken" "org/my-project")"
assert_contains "${url}" "x-access-token:mytoken" "URL contains token"
assert_contains "${url}" "org/my-project.git" "URL contains repo"

# ============================================================
test_suite "get_clone_args"
# ============================================================

args="$(get_clone_args "1" "false")"
assert_eq "--depth=1" "${args}" "depth=1, no submodules"

args="$(get_clone_args "10" "false")"
assert_eq "--depth=10" "${args}" "depth=10, no submodules"

args="$(get_clone_args "0" "false")"
assert_eq "" "${args}" "depth=0 means full clone (no --depth flag)"

args="$(get_clone_args "1" "true")"
assert_eq "--depth=1 --recurse-submodules" "${args}" "depth=1 with submodules=true"

args="$(get_clone_args "1" "recursive")"
assert_eq "--depth=1 --recurse-submodules" "${args}" "depth=1 with submodules=recursive"

args="$(get_clone_args "0" "true")"
assert_eq "--recurse-submodules" "${args}" "full clone with submodules"

# ============================================================
test_suite "get_checkout_ref"
# ============================================================

# Explicit ref takes priority
GITHUB_SHA="abc123"
GITHUB_REF="refs/heads/main"
result="$(get_checkout_ref "v1.0.0")"
assert_eq "v1.0.0" "${result}" "explicit ref takes priority"

# Falls back to GITHUB_SHA
result="$(get_checkout_ref "")"
assert_eq "abc123" "${result}" "falls back to GITHUB_SHA"

# Falls back to GITHUB_REF when GITHUB_SHA is empty
unset GITHUB_SHA
result="$(get_checkout_ref "")"
assert_eq "refs/heads/main" "${result}" "falls back to GITHUB_REF"

# Returns empty when nothing is set
unset GITHUB_REF
result="$(get_checkout_ref "")"
assert_eq "" "${result}" "returns empty when no ref available"

# Cleanup
unset GITHUB_SHA GITHUB_REF

# ============================================================
test_suite "clean_workspace"
# ============================================================

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"; rm -f "${GITHUB_OUTPUT}"' EXIT

# Create files in the workspace
mkdir -p "${tmp_dir}/.git/objects"
echo "git data" > "${tmp_dir}/.git/HEAD"
echo "source" > "${tmp_dir}/main.go"
mkdir -p "${tmp_dir}/src"
echo "more source" > "${tmp_dir}/src/lib.go"

clean_workspace "${tmp_dir}" >/dev/null 2>&1

assert_success ".git preserved after clean" test -d "${tmp_dir}/.git"
assert_success ".git/HEAD preserved" test -f "${tmp_dir}/.git/HEAD"
assert_failure "main.go removed" test -f "${tmp_dir}/main.go"
assert_failure "src dir removed" test -d "${tmp_dir}/src"

# Cleaning nonexistent dir should not fail
assert_success "clean nonexistent dir succeeds" clean_workspace "/tmp/nonexistent_checkout_test_dir"

# ============================================================
test_summary
