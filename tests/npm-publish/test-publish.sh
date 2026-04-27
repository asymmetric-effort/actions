#!/usr/bin/env bash
# Tests for actions/npm-publish/scripts/publish.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/npm-publish" && pwd)"
source "${ACTION_DIR}/scripts/publish.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# Create test package.json
mkdir -p "${tmp_dir}/pkg"
cat > "${tmp_dir}/pkg/package.json" << 'JSON'
{
  "name": "@asymmetric-effort/test-pkg",
  "version": "2.5.0",
  "description": "test package"
}
JSON

# ============================================================
test_suite "read_package_name"
# ============================================================

result="$(read_package_name "${tmp_dir}/pkg")"
assert_eq "@asymmetric-effort/test-pkg" "${result}" "reads scoped package name"

# Unscoped package
echo '{"name": "simple-pkg", "version": "1.0.0"}' > "${tmp_dir}/pkg/package.json"
result="$(read_package_name "${tmp_dir}/pkg")"
assert_eq "simple-pkg" "${result}" "reads unscoped package name"

# Restore scoped name
cat > "${tmp_dir}/pkg/package.json" << 'JSON'
{
  "name": "@asymmetric-effort/test-pkg",
  "version": "2.5.0"
}
JSON

# ============================================================
test_suite "read_package_version"
# ============================================================

result="$(read_package_version "${tmp_dir}/pkg")"
assert_eq "2.5.0" "${result}" "reads version"

# Pre-release version
echo '{"name": "pkg", "version": "3.0.0-beta.1"}' > "${tmp_dir}/pkg/package.json"
result="$(read_package_version "${tmp_dir}/pkg")"
assert_eq "3.0.0-beta.1" "${result}" "reads pre-release version"

# Restore
cat > "${tmp_dir}/pkg/package.json" << 'JSON'
{
  "name": "@asymmetric-effort/test-pkg",
  "version": "2.5.0"
}
JSON

# ============================================================
test_suite "check_version_exists"
# ============================================================

# This tests against the real registry — a package that definitely exists
assert_success "existing package version found" \
  check_version_exists "@asymmetric-effort/specifyjs" "0.0.6" "https://registry.npmjs.org"

# Non-existent version
assert_failure "non-existent version returns failure" \
  check_version_exists "@asymmetric-effort/specifyjs" "99.99.99" "https://registry.npmjs.org"

# Non-existent package
assert_failure "non-existent package returns failure" \
  check_version_exists "@asymmetric-effort/this-does-not-exist-xyz" "1.0.0" "https://registry.npmjs.org"

# ============================================================
test_suite "build_publish_args"
# ============================================================

result="$(build_publish_args "latest" "public" "false" "true")"
assert_contains "${result}" "--tag latest" "has tag"
assert_contains "${result}" "--access public" "has access"
assert_contains "${result}" "--provenance" "has provenance"
assert_not_contains "${result}" "--dry-run" "no dry-run when false"

result="$(build_publish_args "next" "restricted" "true" "false")"
assert_contains "${result}" "--tag next" "custom tag"
assert_contains "${result}" "--access restricted" "restricted access"
assert_contains "${result}" "--dry-run" "has dry-run"
assert_not_contains "${result}" "--provenance" "no provenance when false"

result="$(build_publish_args "beta" "public" "true" "true")"
assert_contains "${result}" "--tag beta" "beta tag"
assert_contains "${result}" "--provenance" "provenance with dry-run"
assert_contains "${result}" "--dry-run" "dry-run with provenance"

# ============================================================
test_suite "npm_publish (duplicate version detection)"
# ============================================================

# Test that publishing an already-existing version fails
INPUT_PACKAGE_DIR="${tmp_dir}/pkg"
INPUT_TAG="latest"
INPUT_ACCESS="public"
INPUT_DRY_RUN="false"
INPUT_PROVENANCE="false"
INPUT_REGISTRY="https://registry.npmjs.org"

# Use a package/version known to exist
cat > "${tmp_dir}/pkg/package.json" << 'JSON'
{
  "name": "@asymmetric-effort/specifyjs",
  "version": "0.0.6"
}
JSON

true > "${GITHUB_OUTPUT}"
assert_failure "refuses to publish already-existing version" bash -c "
  export GITHUB_OUTPUT='${GITHUB_OUTPUT}'
  export INPUT_PACKAGE_DIR='${tmp_dir}/pkg'
  export INPUT_TAG='latest'
  export INPUT_ACCESS='public'
  export INPUT_DRY_RUN='false'
  export INPUT_PROVENANCE='false'
  export INPUT_REGISTRY='https://registry.npmjs.org'
  source '${ACTION_DIR}/scripts/publish.sh'
  npm_publish
"

# ============================================================
test_summary
