#!/usr/bin/env bash
# Tests for actions/download-artifact/scripts/download.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/download-artifact" && pwd)"
source "${ACTION_DIR}/scripts/download.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT so we don't write to real files
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
GITHUB_WORKSPACE="$(mktemp -d)"
trap 'rm -f "${GITHUB_OUTPUT}"; rm -rf "${GITHUB_WORKSPACE}"' EXIT

# ============================================================
test_suite "build_artifact_api_url"
# ============================================================

url="$(build_artifact_api_url "owner/repo" "12345")"
assert_eq "https://api.github.com/repos/owner/repo/actions/runs/12345/artifacts" "${url}" \
  "builds correct API URL"

url="$(build_artifact_api_url "my-org/my-repo" "99999")"
assert_contains "${url}" "my-org/my-repo" "URL contains owner/repo"
assert_contains "${url}" "99999" "URL contains run ID"

# ============================================================
test_suite "parse_artifact_id"
# ============================================================

sample_json='{
  "total_count": 2,
  "artifacts": [
    {"id": 100, "name": "build-output", "size_in_bytes": 1024},
    {"id": 200, "name": "test-results", "size_in_bytes": 2048}
  ]
}'

artifact_id="$(parse_artifact_id "${sample_json}" "build-output")"
assert_eq "100" "${artifact_id}" "finds build-output artifact ID"

artifact_id="$(parse_artifact_id "${sample_json}" "test-results")"
assert_eq "200" "${artifact_id}" "finds test-results artifact ID"

assert_failure "missing artifact returns error" parse_artifact_id "${sample_json}" "nonexistent"

empty_json='{"total_count": 0, "artifacts": []}'
assert_failure "empty artifact list returns error" parse_artifact_id "${empty_json}" "anything"

# ============================================================
test_suite "parse_matching_artifact_ids"
# ============================================================

multi_json='{
  "total_count": 3,
  "artifacts": [
    {"id": 100, "name": "build-linux", "size_in_bytes": 1024},
    {"id": 200, "name": "build-macos", "size_in_bytes": 2048},
    {"id": 300, "name": "test-results", "size_in_bytes": 512}
  ]
}'

ids="$(parse_matching_artifact_ids "${multi_json}" "build-")"
assert_contains "${ids}" "100" "matches build-linux"
assert_contains "${ids}" "200" "matches build-macos"
assert_not_contains "${ids}" "300" "does not match test-results"

assert_failure "no match returns error" parse_matching_artifact_ids "${multi_json}" "^deploy-"

# ============================================================
test_suite "extract_artifact"
# ============================================================

# Create a test zip file to simulate artifact download
extract_dir="${GITHUB_WORKSPACE}/extract-test"
mkdir -p "${extract_dir}"

test_zip="${GITHUB_WORKSPACE}/test-artifact.zip"
tmp_content_dir="$(mktemp -d)"
echo "hello world" > "${tmp_content_dir}/test-file.txt"
python3 -c "
import zipfile, sys
with zipfile.ZipFile(sys.argv[1], 'w') as zf:
    zf.write(sys.argv[2], 'test-file.txt')
" "${test_zip}" "${tmp_content_dir}/test-file.txt"
rm -rf "${tmp_content_dir}"

# We cannot test extract_artifact with a real API call, but we can
# verify the function exists and would fail gracefully with a bad URL
assert_failure "extract with invalid repo fails" \
  extract_artifact "invalid/repo" "99999" "bad-token" "${extract_dir}"

# Verify extraction works on our test zip (simulating what extract_artifact does internally)
python3 -c "
import zipfile, sys
with zipfile.ZipFile(sys.argv[1], 'r') as zf:
    zf.extractall(sys.argv[2])
" "${test_zip}" "${extract_dir}"
assert_file_exists "${extract_dir}/test-file.txt" "extracted file exists"

# Cleanup
rm -f "${test_zip}"

# ============================================================
test_summary
