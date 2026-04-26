#!/usr/bin/env bash
# Tests for actions/gh-release/scripts/create-release.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/gh-release" && pwd)"
source "${ACTION_DIR}/scripts/create-release.sh"

# ============================================================
# Setup
# ============================================================
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "resolve_body (inline text)"
# ============================================================

# shellcheck disable=SC2034  # Variables consumed by sourced create-release.sh
INPUT_BODY="Release notes here"
INPUT_BODY_PATH=""
INPUT_WORKING_DIRECTORY="${tmp_dir}"

result="$(resolve_body)"
assert_eq "Release notes here" "${result}" "returns inline body text"

# ============================================================
test_suite "resolve_body (empty)"
# ============================================================

# shellcheck disable=SC2034
INPUT_BODY=""
# shellcheck disable=SC2034
INPUT_BODY_PATH=""

result="$(resolve_body)"
assert_eq "" "${result}" "returns empty when no body"

# ============================================================
test_suite "resolve_body (from file, relative path)"
# ============================================================

echo "# Changelog" > "${tmp_dir}/NOTES.md"
# shellcheck disable=SC2034
INPUT_BODY=""
# shellcheck disable=SC2034
INPUT_BODY_PATH="NOTES.md"
# shellcheck disable=SC2034
INPUT_WORKING_DIRECTORY="${tmp_dir}"

result="$(resolve_body)"
assert_eq "# Changelog" "${result}" "reads body from relative file"

# ============================================================
test_suite "resolve_body (from file, absolute path)"
# ============================================================

echo "Absolute notes" > "${tmp_dir}/abs-notes.md"
# shellcheck disable=SC2034
INPUT_BODY_PATH="${tmp_dir}/abs-notes.md"

result="$(resolve_body)"
assert_eq "Absolute notes" "${result}" "reads body from absolute path"

# ============================================================
test_suite "resolve_body (file not found)"
# ============================================================

# shellcheck disable=SC2034
INPUT_BODY_PATH="${tmp_dir}/nonexistent.md"
assert_failure "missing body_path fails" resolve_body

# Reset
# shellcheck disable=SC2034
INPUT_BODY_PATH=""

# ============================================================
test_suite "parse_json_field"
# ============================================================

json='{"id": 12345, "html_url": "https://github.com/releases/1", "upload_url": "https://uploads.github.com/test"}'

result="$(parse_json_field "${json}" "id")"
assert_eq "12345" "${result}" "parses numeric id"

result="$(parse_json_field "${json}" "html_url")"
assert_eq "https://github.com/releases/1" "${result}" "parses html_url"

result="$(parse_json_field "${json}" "upload_url")"
assert_eq "https://uploads.github.com/test" "${result}" "parses upload_url"

# Multiple id fields — returns first
json2='{"id": 111, "nested": {"id": 222}}'
result="$(parse_json_field "${json2}" "id")"
assert_eq "111" "${result}" "returns first id match"

# ============================================================
test_summary
