#!/usr/bin/env bash
# Tests for actions/checkout/scripts/validate.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/checkout" && pwd)"
source "${ACTION_DIR}/scripts/validate.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT so we don't write to real files
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -f "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "validate_token"
# ============================================================

assert_success "valid token passes" validate_token "ghp_abc123"
assert_success "any non-empty token passes" validate_token "some-token"
assert_failure "empty token fails" validate_token ""
assert_failure "missing token fails" validate_token

# ============================================================
test_suite "validate_fetch_depth"
# ============================================================

assert_success "fetch-depth 0 passes" validate_fetch_depth "0"
assert_success "fetch-depth 1 passes" validate_fetch_depth "1"
assert_success "fetch-depth 100 passes" validate_fetch_depth "100"
assert_failure "non-numeric fetch-depth fails" validate_fetch_depth "abc"
assert_failure "negative fetch-depth fails" validate_fetch_depth "-1"
assert_failure "decimal fetch-depth fails" validate_fetch_depth "1.5"
assert_failure "empty fetch-depth fails" validate_fetch_depth ""

# ============================================================
test_suite "validate_submodules"
# ============================================================

assert_success "submodules false passes" validate_submodules "false"
assert_success "submodules true passes" validate_submodules "true"
assert_success "submodules recursive passes" validate_submodules "recursive"
assert_failure "invalid submodules value fails" validate_submodules "yes"
assert_failure "empty submodules fails" validate_submodules ""

# ============================================================
test_suite "validate_checkout_inputs (integration)"
# ============================================================

INPUT_TOKEN="ghp_test123"
INPUT_FETCH_DEPTH="1"
INPUT_SUBMODULES="false"
assert_success "valid inputs pass" validate_checkout_inputs

INPUT_TOKEN=""
INPUT_FETCH_DEPTH="1"
INPUT_SUBMODULES="false"
assert_failure "missing token fails validation" validate_checkout_inputs

INPUT_TOKEN="ghp_test123"
INPUT_FETCH_DEPTH="abc"
INPUT_SUBMODULES="false"
assert_failure "non-numeric depth fails validation" validate_checkout_inputs

INPUT_TOKEN="ghp_test123"
INPUT_FETCH_DEPTH="1"
INPUT_SUBMODULES="invalid"
assert_failure "invalid submodules fails validation" validate_checkout_inputs

# Cleanup
unset INPUT_TOKEN INPUT_FETCH_DEPTH INPUT_SUBMODULES

# ============================================================
test_summary
