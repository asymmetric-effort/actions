#!/usr/bin/env bash
# Tests for actions/download-artifact/scripts/validate.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/download-artifact" && pwd)"
source "${ACTION_DIR}/scripts/validate.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT so we don't write to real files
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
GITHUB_WORKSPACE="$(mktemp -d)"
trap 'rm -f "${GITHUB_OUTPUT}"; rm -rf "${GITHUB_WORKSPACE}"' EXIT

# ============================================================
test_suite "validate_artifact_name"
# ============================================================

assert_success "non-empty name passes" validate_artifact_name "my-artifact"
assert_success "name with spaces passes" validate_artifact_name "my artifact"
assert_failure "empty name fails" validate_artifact_name ""
assert_failure "missing name fails" validate_artifact_name

# ============================================================
test_suite "validate_download_path"
# ============================================================

assert_success "current dir passes" validate_download_path "."
assert_success "relative path passes (created)" validate_download_path "output/artifacts"
assert_success "absolute path passes" validate_download_path "${GITHUB_WORKSPACE}/downloads"
assert_failure "empty path fails" validate_download_path ""

# Verify path that is a file fails
tmp_file="${GITHUB_WORKSPACE}/not-a-dir"
touch "${tmp_file}"
assert_failure "file path fails" validate_download_path "${tmp_file}"
rm -f "${tmp_file}"

# ============================================================
test_suite "validate_merge_multiple"
# ============================================================

assert_success "false passes" validate_merge_multiple "false"
assert_success "true passes" validate_merge_multiple "true"
assert_failure "invalid value fails" validate_merge_multiple "yes"
assert_failure "empty value fails" validate_merge_multiple ""

# ============================================================
test_suite "validate_download_inputs (integration)"
# ============================================================

INPUT_NAME="my-artifact"
INPUT_PATH="."
INPUT_MERGE_MULTIPLE="false"
assert_success "valid inputs pass" validate_download_inputs

INPUT_NAME=""
INPUT_PATH="."
INPUT_MERGE_MULTIPLE="false"
assert_failure "empty name fails validation" validate_download_inputs

INPUT_NAME="my-artifact"
INPUT_PATH="."
INPUT_MERGE_MULTIPLE="invalid"
assert_failure "invalid merge-multiple fails validation" validate_download_inputs

# Cleanup
unset INPUT_NAME INPUT_PATH INPUT_MERGE_MULTIPLE

# ============================================================
test_summary
