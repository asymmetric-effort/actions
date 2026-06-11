#!/usr/bin/env bash
# Tests for actions/upload-pages-artifact/scripts/validate.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/upload-pages-artifact" && pwd)"
source "${ACTION_DIR}/scripts/validate.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# ============================================================
test_suite "validate_pages_inputs"
# ============================================================

# Valid directory passes
mkdir -p "${tmp_dir}/site"
echo "<html></html>" > "${tmp_dir}/site/index.html"
INPUT_PATH="${tmp_dir}/site"
INPUT_RETENTION_DAYS="1"

assert_success "valid directory passes" validate_pages_inputs

# Valid with higher retention
INPUT_RETENTION_DAYS="30"
assert_success "valid retention-days passes" validate_pages_inputs

# Missing directory fails
INPUT_PATH="${tmp_dir}/nonexistent"
INPUT_RETENTION_DAYS="1"
assert_failure "missing directory fails" validate_pages_inputs

# File instead of directory fails
touch "${tmp_dir}/afile.txt"
INPUT_PATH="${tmp_dir}/afile.txt"
assert_failure "file instead of directory fails" validate_pages_inputs

# Non-numeric retention-days fails
INPUT_PATH="${tmp_dir}/site"
INPUT_RETENTION_DAYS="abc"
assert_failure "non-numeric retention-days fails" validate_pages_inputs

# Zero retention-days fails
INPUT_RETENTION_DAYS="0"
assert_failure "zero retention-days fails" validate_pages_inputs

# Negative retention-days fails
INPUT_RETENTION_DAYS="-5"
assert_failure "negative retention-days fails" validate_pages_inputs

# ============================================================
test_summary
