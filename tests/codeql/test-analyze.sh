#!/usr/bin/env bash
# Tests for actions/codeql-analyze/scripts/analyze.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the scripts under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/codeql-analyze" && pwd)"
COMMON_DIR="$(cd "${SCRIPT_DIR}/../../actions/codeql-common" && pwd)"
source "${COMMON_DIR}/scripts/shared.sh"
source "${ACTION_DIR}/scripts/analyze.sh"

# ============================================================
# Setup
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
GITHUB_ENV="$(mktemp)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}" "${GITHUB_ENV}"' EXIT

# ============================================================
test_suite "build_sarif_payload"
# ============================================================

# Create a minimal SARIF file for testing
sarif_file="${tmp_dir}/test.sarif"
cat > "${sarif_file}" << 'SARIF'
{
  "version": "2.1.0",
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "runs": []
}
SARIF

GITHUB_SHA="abc123def456"
GITHUB_REF="refs/heads/main"

payload="$(build_sarif_payload "${sarif_file}" "test-category" "${GITHUB_SHA}" "${GITHUB_REF}")"

# Verify payload structure
assert_not_empty "${payload}" "payload is not empty"

commit_sha="$(echo "${payload}" | jq -r '.commit_sha')"
assert_eq "abc123def456" "${commit_sha}" "payload contains correct commit_sha"

ref="$(echo "${payload}" | jq -r '.ref')"
assert_eq "refs/heads/main" "${ref}" "payload contains correct ref"

sarif_content="$(echo "${payload}" | jq -r '.sarif')"
assert_not_empty "${sarif_content}" "payload contains compressed sarif"

tool_name="$(echo "${payload}" | jq -r '.tool_name')"
assert_eq "CodeQL" "${tool_name}" "payload contains tool_name"

category="$(echo "${payload}" | jq -r '.category')"
assert_eq "test-category" "${category}" "payload contains category"

# Test without category
payload_no_cat="$(build_sarif_payload "${sarif_file}" "" "${GITHUB_SHA}" "${GITHUB_REF}")"
has_category="$(echo "${payload_no_cat}" | jq 'has("category")')"
assert_eq "false" "${has_category}" "payload omits category when empty"

# Verify the SARIF data can be decoded
decoded="$(echo "${sarif_content}" | base64 -d | gzip -d)"
assert_contains "${decoded}" "2.1.0" "decoded SARIF contains version"

# ============================================================
test_suite "build_sarif_payload - compression roundtrip"
# ============================================================

# Create a larger SARIF file to test compression
large_sarif="${tmp_dir}/large.sarif"
cat > "${large_sarif}" << 'SARIF'
{
  "version": "2.1.0",
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "CodeQL",
          "version": "2.16.0"
        }
      },
      "results": [
        {
          "ruleId": "js/sql-injection",
          "message": { "text": "SQL injection vulnerability" },
          "level": "error"
        }
      ]
    }
  ]
}
SARIF

payload="$(build_sarif_payload "${large_sarif}" "security" "sha123" "refs/heads/main")"
sarif_b64="$(echo "${payload}" | jq -r '.sarif')"
decoded="$(echo "${sarif_b64}" | base64 -d | gzip -d)"
assert_contains "${decoded}" "sql-injection" "roundtrip preserves content"
assert_contains "${decoded}" "CodeQL" "roundtrip preserves tool name"

# ============================================================
test_suite "get_codeql_databases_dir (from analyze context)"
# ============================================================

CODEQL_DATABASES="${tmp_dir}/my-dbs"
result="$(get_codeql_databases_dir)"
assert_eq "${tmp_dir}/my-dbs" "${result}" "returns CODEQL_DATABASES path"
unset CODEQL_DATABASES

# ============================================================
test_summary
