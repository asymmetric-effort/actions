#!/usr/bin/env bash
# Tests for actions/npm-publish/scripts/configure-npm.sh

# shellcheck disable=SC1091,SC2034,SC2016
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/npm-publish" && pwd)"
source "${ACTION_DIR}/scripts/configure-npm.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "get_registry_host"
# ============================================================

assert_eq "registry.npmjs.org" "$(get_registry_host "https://registry.npmjs.org")" "strips https://"
assert_eq "registry.npmjs.org" "$(get_registry_host "https://registry.npmjs.org/")" "strips trailing slash"
assert_eq "npm.pkg.github.com" "$(get_registry_host "https://npm.pkg.github.com")" "GitHub packages registry"
assert_eq "custom.registry.com" "$(get_registry_host "https://custom.registry.com/")" "custom registry"
assert_eq "registry.npmjs.org" "$(get_registry_host "http://registry.npmjs.org")" "strips http://"

# ============================================================
test_suite "generate_npmrc"
# ============================================================

result="$(generate_npmrc "https://registry.npmjs.org")"
assert_contains "${result}" "registry=https://registry.npmjs.org" "sets registry"
assert_contains "${result}" "//registry.npmjs.org/:_authToken" "sets auth token placeholder"
assert_contains "${result}" '${NODE_AUTH_TOKEN}' "uses NODE_AUTH_TOKEN env var"

# GitHub Packages registry
result="$(generate_npmrc "https://npm.pkg.github.com")"
assert_contains "${result}" "registry=https://npm.pkg.github.com" "sets GitHub registry"
assert_contains "${result}" "//npm.pkg.github.com/:_authToken" "sets GitHub auth token"

# ============================================================
test_suite "write_npmrc"
# ============================================================

mkdir -p "${tmp_dir}/pkg1"
write_npmrc "${tmp_dir}/pkg1" "https://registry.npmjs.org"
assert_file_exists "${tmp_dir}/pkg1/.npmrc" ".npmrc created"

content="$(cat "${tmp_dir}/pkg1/.npmrc")"
assert_contains "${content}" "registry=https://registry.npmjs.org" ".npmrc has registry"

# ============================================================
test_suite "write_npmrc (backs up existing)"
# ============================================================

mkdir -p "${tmp_dir}/pkg2"
echo "old-content" > "${tmp_dir}/pkg2/.npmrc"

write_npmrc "${tmp_dir}/pkg2" "https://registry.npmjs.org"
assert_file_exists "${tmp_dir}/pkg2/.npmrc.bak" "backup created"

backup="$(cat "${tmp_dir}/pkg2/.npmrc.bak")"
assert_eq "old-content" "${backup}" "backup has original content"

new_content="$(cat "${tmp_dir}/pkg2/.npmrc")"
assert_contains "${new_content}" "registry=https://registry.npmjs.org" "new .npmrc written"

# ============================================================
test_suite "configure_npm_oidc"
# ============================================================

mkdir -p "${tmp_dir}/pkg3"
echo '{"name":"test","version":"1.0.0"}' > "${tmp_dir}/pkg3/package.json"

INPUT_PACKAGE_DIR="${tmp_dir}/pkg3"
INPUT_REGISTRY="https://registry.npmjs.org"

configure_npm_oidc
assert_file_exists "${tmp_dir}/pkg3/.npmrc" "configure_npm_oidc writes .npmrc"

# ============================================================
test_summary
