#!/usr/bin/env bash
# Tests for actions/deploy-pages-api/scripts/deploy.sh and poll-status.sh

# shellcheck disable=SC1091,SC2034,SC2030,SC2031,SC2317
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/deploy-pages-api" && pwd)"
source "${ACTION_DIR}/scripts/deploy.sh"
source "${ACTION_DIR}/scripts/poll-status.sh"

tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "find_artifact"
# ============================================================

# Create a fake artifact directory with a tar.gz
mkdir -p "${tmp_dir}/artifact1"
echo "fake-data" > "${tmp_dir}/artifact1/github-pages.tar.gz"

ARTIFACT_DIR="${tmp_dir}/artifact1"
result="$(find_artifact)"
assert_contains "${result}" "github-pages.tar.gz" "finds tar.gz artifact"

# Missing artifact
mkdir -p "${tmp_dir}/artifact-empty"
ARTIFACT_DIR="${tmp_dir}/artifact-empty"
if find_artifact 2>/dev/null; then
  assert_eq "should fail" "did not fail" "find_artifact should fail on empty dir"
else
  assert_eq "1" "1" "find_artifact fails when no tar.gz present"
fi

# Reset
ARTIFACT_DIR="${tmp_dir}/artifact1"

# ============================================================
test_suite "build_deployment_payload"
# ============================================================

GITHUB_SHA="abc1234567890"

result="$(build_deployment_payload "test-oidc-token")"
assert_contains "${result}" "abc1234567890" "payload contains pages_build_version"
assert_contains "${result}" "test-oidc-token" "payload contains oidc_token"

# Verify it's valid JSON
echo "${result}" | jq . > /dev/null 2>&1
assert_eq "0" "$?" "payload is valid JSON"

# Extract fields
version="$(echo "${result}" | jq -r '.pages_build_version')"
assert_eq "abc1234567890" "${version}" "pages_build_version matches GITHUB_SHA"

token_val="$(echo "${result}" | jq -r '.oidc_token')"
assert_eq "test-oidc-token" "${token_val}" "oidc_token matches input"

# ============================================================
test_suite "parse_deployment_response"
# ============================================================

# Valid response
response='{"id":"12345","page_url":"https://owner.github.io/repo","status_url":"https://api.github.com/repos/owner/repo/pages/deployments/12345"}'
result="$(parse_deployment_response "${response}")"
assert_contains "${result}" "id=12345" "extracts deployment id"
assert_contains "${result}" "page_url=https://owner.github.io/repo" "extracts page_url"
assert_contains "${result}" "status_url=" "extracts status_url"

# Missing id
bad_response='{"page_url":"https://owner.github.io/repo"}'
if parse_deployment_response "${bad_response}" 2>/dev/null; then
  assert_eq "should fail" "did not fail" "parse should fail without id"
else
  assert_eq "1" "1" "parse_deployment_response fails when id is missing"
fi

# Numeric id
numeric_response='{"id":99999,"page_url":"https://example.github.io","status_url":"https://api.github.com/status"}'
result="$(parse_deployment_response "${numeric_response}")"
assert_contains "${result}" "id=99999" "handles numeric id"

# ============================================================
test_suite "ms_to_seconds"
# ============================================================

result="$(ms_to_seconds 5000)"
assert_eq "5" "${result}" "5000ms = 5s"

result="$(ms_to_seconds 600000)"
assert_eq "600" "${result}" "600000ms = 600s"

result="$(ms_to_seconds 1500)"
assert_eq "1" "${result}" "1500ms = 1s (integer division)"

result="$(ms_to_seconds 500)"
assert_eq "0" "${result}" "500ms = 0s (integer division)"

# ============================================================
test_suite "is_terminal_status"
# ============================================================

assert_success "succeed is terminal" is_terminal_status "succeed"
assert_success "deployment_failed is terminal" is_terminal_status "deployment_failed"
assert_success "deployment_content_failed is terminal" is_terminal_status "deployment_content_failed"
assert_success "cancelled is terminal" is_terminal_status "cancelled"
assert_failure "deployment_in_progress is not terminal" is_terminal_status "deployment_in_progress"
assert_failure "queued is not terminal" is_terminal_status "queued"
assert_failure "unknown is not terminal" is_terminal_status "unknown"

# ============================================================
test_suite "is_success_status"
# ============================================================

assert_success "succeed is success" is_success_status "succeed"
assert_failure "deployment_failed is not success" is_success_status "deployment_failed"
assert_failure "cancelled is not success" is_success_status "cancelled"

# ============================================================
test_suite "parse_status"
# ============================================================

result="$(parse_status '{"status":"succeed"}')"
assert_eq "succeed" "${result}" "parses succeed status"

result="$(parse_status '{"status":"deployment_in_progress"}')"
assert_eq "deployment_in_progress" "${result}" "parses in-progress status"

result="$(parse_status '{}')"
assert_eq "unknown" "${result}" "defaults to unknown when status missing"

# ============================================================
test_summary
