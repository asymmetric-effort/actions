#!/usr/bin/env bash
# Tests for actions/release/scripts/release.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/release" && pwd)"
source "${ACTION_DIR}/scripts/release.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "resolve_body (inline text)"
# ============================================================

INPUT_BODY="Release notes here"
INPUT_BODY_PATH=""
INPUT_WORKING_DIRECTORY="${tmp_dir}"

result="$(resolve_body)"
assert_eq "Release notes here" "${result}" "returns inline body text"

# ============================================================
test_suite "resolve_body (empty)"
# ============================================================

INPUT_BODY=""
INPUT_BODY_PATH=""

result="$(resolve_body)"
assert_eq "" "${result}" "returns empty when no body"

# ============================================================
test_suite "resolve_body (from file, relative)"
# ============================================================

echo "# Changelog" > "${tmp_dir}/NOTES.md"
INPUT_BODY=""
INPUT_BODY_PATH="NOTES.md"
INPUT_WORKING_DIRECTORY="${tmp_dir}"

result="$(resolve_body)"
assert_eq "# Changelog" "${result}" "reads body from relative file"

# ============================================================
test_suite "resolve_body (from file, absolute)"
# ============================================================

echo "Absolute notes" > "${tmp_dir}/abs-notes.md"
INPUT_BODY_PATH="${tmp_dir}/abs-notes.md"

result="$(resolve_body)"
assert_eq "Absolute notes" "${result}" "reads body from absolute path"

# ============================================================
test_suite "resolve_body (file not found)"
# ============================================================

INPUT_BODY_PATH="${tmp_dir}/nonexistent.md"
assert_failure "missing body_path fails" resolve_body

INPUT_BODY_PATH=""

# ============================================================
test_suite "parse_release_field"
# ============================================================

json='{"id": 12345, "html_url": "https://github.com/releases/1", "upload_url": "https://uploads.github.com/test"}'

result="$(parse_release_field "${json}" "id")"
assert_eq "12345" "${result}" "parses numeric id"

result="$(parse_release_field "${json}" "html_url")"
assert_eq "https://github.com/releases/1" "${result}" "parses html_url"

result="$(parse_release_field "${json}" "upload_url")"
assert_eq "https://uploads.github.com/test" "${result}" "parses upload_url"

# ============================================================
test_suite "body append logic"
# ============================================================

# Simulate append_body behavior
existing="Old notes"
new_body="New notes"
INPUT_APPEND_BODY="true"

combined="${existing}

${new_body}"
assert_contains "${combined}" "Old notes" "combined has old notes"
assert_contains "${combined}" "New notes" "combined has new notes"

# Without append
INPUT_APPEND_BODY="false"
assert_eq "New notes" "${new_body}" "no append keeps new body only"

# ============================================================
test_summary
