#!/usr/bin/env bash
# Tests for actions/deploy-pages/scripts/validate.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/deploy-pages" && pwd)"
source "${ACTION_DIR}/scripts/validate.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# ============================================================
test_suite "validate_inputs"
# ============================================================

# Valid inputs
mkdir -p "${tmp_dir}/public"
echo "content" > "${tmp_dir}/public/index.html"
INPUT_PUBLISH_DIR="${tmp_dir}/public"
INPUT_TOKEN="test-token"
INPUT_DEPLOY_KEY=""

assert_success "valid inputs pass" validate_inputs

# Missing publish_dir
INPUT_PUBLISH_DIR="${tmp_dir}/nonexistent"
assert_failure "missing publish_dir fails" validate_inputs

# No auth
INPUT_PUBLISH_DIR="${tmp_dir}/public"
INPUT_TOKEN=""
INPUT_DEPLOY_KEY=""
assert_failure "no auth fails" validate_inputs

# Deploy key only
INPUT_TOKEN=""
INPUT_DEPLOY_KEY="ssh-key-data"
assert_success "deploy_key auth passes" validate_inputs

# Token only
INPUT_TOKEN="test-token"
INPUT_DEPLOY_KEY=""
assert_success "token auth passes" validate_inputs

# Empty publish_dir (warning but passes)
mkdir -p "${tmp_dir}/empty"
INPUT_PUBLISH_DIR="${tmp_dir}/empty"
assert_success "empty publish_dir warns but passes" validate_inputs

# ============================================================
test_summary
