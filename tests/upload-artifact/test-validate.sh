#!/usr/bin/env bash
# Tests for actions/upload-artifact/scripts/validate.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/upload-artifact" && pwd)"
source "${ACTION_DIR}/scripts/validate.sh"

# ============================================================
test_suite "validate_upload_inputs — name"
# ============================================================

# Valid name passes
INPUT_NAME="my-artifact"
INPUT_PATH="."
INPUT_IF_NO_FILES_FOUND="warn"
INPUT_COMPRESSION_LEVEL="6"
INPUT_RETENTION_DAYS=""

assert_success "valid name passes" validate_upload_inputs

# Empty name fails
INPUT_NAME=""
assert_failure "empty name fails" validate_upload_inputs

# ============================================================
test_suite "validate_upload_inputs — path"
# ============================================================

# Valid path passes
INPUT_NAME="my-artifact"
INPUT_PATH="/tmp"
assert_success "valid path passes" validate_upload_inputs

# Empty path fails
INPUT_NAME="my-artifact"
INPUT_PATH=""
assert_failure "empty path fails" validate_upload_inputs

# ============================================================
test_suite "validate_upload_inputs — if-no-files-found"
# ============================================================

INPUT_NAME="my-artifact"
INPUT_PATH="."

INPUT_IF_NO_FILES_FOUND="warn"
assert_success "if-no-files-found=warn passes" validate_upload_inputs

INPUT_IF_NO_FILES_FOUND="error"
assert_success "if-no-files-found=error passes" validate_upload_inputs

INPUT_IF_NO_FILES_FOUND="ignore"
assert_success "if-no-files-found=ignore passes" validate_upload_inputs

INPUT_IF_NO_FILES_FOUND="invalid"
assert_failure "if-no-files-found=invalid fails" validate_upload_inputs

INPUT_IF_NO_FILES_FOUND=""
assert_failure "if-no-files-found=empty fails" validate_upload_inputs

# ============================================================
test_suite "validate_upload_inputs — compression-level"
# ============================================================

INPUT_IF_NO_FILES_FOUND="warn"

INPUT_COMPRESSION_LEVEL="0"
assert_success "compression-level=0 passes" validate_upload_inputs

INPUT_COMPRESSION_LEVEL="9"
assert_success "compression-level=9 passes" validate_upload_inputs

INPUT_COMPRESSION_LEVEL="5"
assert_success "compression-level=5 passes" validate_upload_inputs

INPUT_COMPRESSION_LEVEL="10"
assert_failure "compression-level=10 fails" validate_upload_inputs

INPUT_COMPRESSION_LEVEL="-1"
assert_failure "compression-level=-1 fails" validate_upload_inputs

INPUT_COMPRESSION_LEVEL="abc"
assert_failure "compression-level=abc fails" validate_upload_inputs

INPUT_COMPRESSION_LEVEL=""
assert_failure "compression-level=empty fails" validate_upload_inputs

# ============================================================
test_suite "validate_upload_inputs — retention-days"
# ============================================================

INPUT_COMPRESSION_LEVEL="6"

INPUT_RETENTION_DAYS=""
assert_success "retention-days=empty passes (repo default)" validate_upload_inputs

INPUT_RETENTION_DAYS="1"
assert_success "retention-days=1 passes" validate_upload_inputs

INPUT_RETENTION_DAYS="90"
assert_success "retention-days=90 passes" validate_upload_inputs

INPUT_RETENTION_DAYS="45"
assert_success "retention-days=45 passes" validate_upload_inputs

INPUT_RETENTION_DAYS="0"
assert_failure "retention-days=0 fails" validate_upload_inputs

INPUT_RETENTION_DAYS="91"
assert_failure "retention-days=91 fails" validate_upload_inputs

INPUT_RETENTION_DAYS="-5"
assert_failure "retention-days=-5 fails" validate_upload_inputs

INPUT_RETENTION_DAYS="abc"
assert_failure "retention-days=abc fails" validate_upload_inputs

# ============================================================
test_summary
