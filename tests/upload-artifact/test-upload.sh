#!/usr/bin/env bash
# Tests for actions/upload-artifact/scripts/upload.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/upload-artifact" && pwd)"
source "${ACTION_DIR}/scripts/upload.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# Mock GITHUB_OUTPUT
GITHUB_OUTPUT="${tmp_dir}/github_output"
touch "${GITHUB_OUTPUT}"

# ============================================================
test_suite "build_artifact_url"
# ============================================================

ACTIONS_RUNTIME_URL="https://pipelines.actions.githubusercontent.com/abc123/"
GITHUB_RUN_ID="12345"

result="$(build_artifact_url)"
assert_contains "${result}" "_apis/pipelines/workflows/12345/artifacts" "URL contains workflow artifacts path"
assert_contains "${result}" "api-version=6.0-preview" "URL contains API version"
url_path="${result#https://}"
assert_not_contains "${url_path}" "//" "no double slashes in path (after protocol)"

# Test with trailing slash removed
ACTIONS_RUNTIME_URL="https://pipelines.actions.githubusercontent.com/abc123"
result2="$(build_artifact_url)"
assert_contains "${result2}" "_apis/pipelines/workflows/12345/artifacts" "URL correct without trailing slash"

# ============================================================
test_suite "resolve_glob_paths"
# ============================================================

# Test: single file
mkdir -p "${tmp_dir}/resolve_test"
echo "hello" > "${tmp_dir}/resolve_test/file1.txt"
echo "world" > "${tmp_dir}/resolve_test/file2.txt"

result="$(resolve_glob_paths "${tmp_dir}/resolve_test/file1.txt")"
assert_contains "${result}" "file1.txt" "resolves single file"
assert_not_contains "${result}" "file2.txt" "does not include other files"

# Test: directory resolves all files
result="$(resolve_glob_paths "${tmp_dir}/resolve_test")"
assert_contains "${result}" "file1.txt" "directory includes file1.txt"
assert_contains "${result}" "file2.txt" "directory includes file2.txt"

# Test: glob pattern
mkdir -p "${tmp_dir}/glob_test"
echo "a" > "${tmp_dir}/glob_test/app.js"
echo "b" > "${tmp_dir}/glob_test/app.css"
echo "c" > "${tmp_dir}/glob_test/readme.md"

result="$(resolve_glob_paths "${tmp_dir}/glob_test/*.js")"
assert_contains "${result}" "app.js" "glob matches .js file"
assert_not_contains "${result}" "app.css" "glob does not match .css file"

# Test: no matches returns empty
result="$(resolve_glob_paths "${tmp_dir}/glob_test/*.xyz")"
assert_eq "" "${result}" "non-matching glob returns empty"

# Test: multiple paths (newline-separated)
multi_paths="${tmp_dir}/resolve_test/file1.txt
${tmp_dir}/glob_test/app.js"
result="$(resolve_glob_paths "${multi_paths}")"
assert_contains "${result}" "file1.txt" "multi-path includes first file"
assert_contains "${result}" "app.js" "multi-path includes second file"

# ============================================================
test_suite "create_archive"
# ============================================================

mkdir -p "${tmp_dir}/archive_src"
echo "content1" > "${tmp_dir}/archive_src/a.txt"
echo "content2" > "${tmp_dir}/archive_src/b.txt"

archive_path="${tmp_dir}/test_archive.tar.gz"
file_list="${tmp_dir}/archive_src/a.txt
${tmp_dir}/archive_src/b.txt"

create_archive "${archive_path}" "6" "${file_list}"
assert_file_exists "${archive_path}" "archive file created"

# Verify archive contents
extract_dir="${tmp_dir}/archive_extracted"
mkdir -p "${extract_dir}"
tar -xzf "${archive_path}" -C "${extract_dir}"
assert_file_exists "${extract_dir}/a.txt" "archive contains a.txt"
assert_file_exists "${extract_dir}/b.txt" "archive contains b.txt"

# Verify content
content_a="$(cat "${extract_dir}/a.txt")"
assert_eq "content1" "${content_a}" "a.txt has correct content"

# Test: different compression levels create valid archives
archive_path_0="${tmp_dir}/test_archive_0.tar.gz"
create_archive "${archive_path_0}" "0" "${file_list}"
assert_file_exists "${archive_path_0}" "archive with compression=0 created"

archive_path_9="${tmp_dir}/test_archive_9.tar.gz"
create_archive "${archive_path_9}" "9" "${file_list}"
assert_file_exists "${archive_path_9}" "archive with compression=9 created"

# ============================================================
test_summary
