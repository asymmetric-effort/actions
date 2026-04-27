#!/usr/bin/env bash
# Tests for actions/build-pkg-rpm/scripts/build-rpm.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/build-pkg-rpm" && pwd)"
source "${ACTION_DIR}/scripts/build-rpm.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# Create test source files
mkdir -p "${tmp_dir}/src/bin"
echo '#!/bin/bash' > "${tmp_dir}/src/bin/myapp"
echo 'echo hello' >> "${tmp_dir}/src/bin/myapp"
chmod +x "${tmp_dir}/src/bin/myapp"
echo "config=value" > "${tmp_dir}/src/bin/myapp.conf"

# ============================================================
test_suite "validate_inline_inputs"
# ============================================================

assert_success "valid inputs pass" validate_inline_inputs "myapp" "1.0.0" "${tmp_dir}/src"

assert_failure "empty name fails" validate_inline_inputs "" "1.0.0" "${tmp_dir}/src"

assert_failure "empty version fails" validate_inline_inputs "myapp" "" "${tmp_dir}/src"

assert_failure "nonexistent source-dir fails" validate_inline_inputs "myapp" "1.0.0" "/nonexistent"

# ============================================================
test_suite "validate_spec_file"
# ============================================================

echo "Name: test" > "${tmp_dir}/test.spec"
assert_success "existing spec file passes" validate_spec_file "${tmp_dir}/test.spec"

assert_failure "missing spec file fails" validate_spec_file "${tmp_dir}/nonexistent.spec"

# ============================================================
test_suite "generate_file_list"
# ============================================================

result="$(generate_file_list "${tmp_dir}/src" "/usr/local/bin")"
assert_contains "${result}" "/usr/local/bin/bin/myapp" "lists myapp binary"
assert_contains "${result}" "/usr/local/bin/bin/myapp.conf" "lists myapp.conf"

# ============================================================
test_suite "generate_spec"
# ============================================================

spec="$(generate_spec "myapp" "1.0.0" "1" "My Application" "A test application" \
  "MIT" "https://example.com" "x86_64" "/usr/local" "${tmp_dir}/src" "" "" "")"

assert_contains "${spec}" "Name:           myapp" "spec has Name"
assert_contains "${spec}" "Version:        1.0.0" "spec has Version"
assert_contains "${spec}" "Release:        1%{?dist}" "spec has Release"
assert_contains "${spec}" "Summary:        My Application" "spec has Summary"
assert_contains "${spec}" "License:        MIT" "spec has License"
assert_contains "${spec}" "URL:            https://example.com" "spec has URL"
assert_contains "${spec}" "BuildArch:      x86_64" "spec has BuildArch"
assert_contains "${spec}" "%description" "spec has description section"
assert_contains "${spec}" "A test application" "spec has description text"
assert_contains "${spec}" "%install" "spec has install section"
assert_contains "${spec}" "%files" "spec has files section"

# ============================================================
test_suite "generate_spec (with requires)"
# ============================================================

spec="$(generate_spec "myapp" "1.0.0" "1" "" "" "MIT" "" "noarch" "/usr/bin" \
  "${tmp_dir}/src" "$(printf 'bash\ncurl >= 7.0')" "" "")"

assert_contains "${spec}" "Requires:       bash" "spec has bash dependency"
assert_contains "${spec}" "Requires:       curl >= 7.0" "spec has curl dependency"

# ============================================================
test_suite "generate_spec (with scripts)"
# ============================================================

spec="$(generate_spec "myapp" "1.0.0" "1" "" "" "MIT" "" "noarch" "/usr/bin" \
  "${tmp_dir}/src" "" "echo pre-install" "echo post-install")"

assert_contains "${spec}" "%pre" "spec has pre section"
assert_contains "${spec}" "echo pre-install" "spec has pre-install content"
assert_contains "${spec}" "%post" "spec has post section"
assert_contains "${spec}" "echo post-install" "spec has post-install content"

# ============================================================
test_suite "generate_spec (no URL when empty)"
# ============================================================

spec="$(generate_spec "myapp" "1.0.0" "1" "Summary" "" "MIT" "" "noarch" \
  "/usr/bin" "${tmp_dir}/src" "" "" "")"

assert_not_contains "${spec}" "URL:" "no URL line when url is empty"

# ============================================================
test_suite "generate_spec (default summary)"
# ============================================================

spec="$(generate_spec "myapp" "1.0.0" "1" "" "" "MIT" "" "noarch" \
  "/usr/bin" "${tmp_dir}/src" "" "" "")"

assert_contains "${spec}" "Summary:        myapp" "defaults summary to package name"

# ============================================================
test_suite "setup_rpmbuild_tree"
# ============================================================

rpmbuild_dir="${tmp_dir}/rpmbuild-test"
setup_rpmbuild_tree "${rpmbuild_dir}"

assert_success "BUILD dir exists" test -d "${rpmbuild_dir}/BUILD"
assert_success "RPMS dir exists" test -d "${rpmbuild_dir}/RPMS"
assert_success "SOURCES dir exists" test -d "${rpmbuild_dir}/SOURCES"
assert_success "SPECS dir exists" test -d "${rpmbuild_dir}/SPECS"
assert_success "SRPMS dir exists" test -d "${rpmbuild_dir}/SRPMS"

# ============================================================
test_suite "find_built_rpm (no RPM)"
# ============================================================

result="$(find_built_rpm "${rpmbuild_dir}")"
assert_eq "" "${result}" "returns empty when no RPM exists"

# ============================================================
test_suite "find_built_rpm (with RPM)"
# ============================================================

mkdir -p "${rpmbuild_dir}/RPMS/x86_64"
touch "${rpmbuild_dir}/RPMS/x86_64/myapp-1.0.0-1.x86_64.rpm"

result="$(find_built_rpm "${rpmbuild_dir}")"
assert_contains "${result}" "myapp-1.0.0-1.x86_64.rpm" "finds the built RPM"

# ============================================================
test_suite "build_rpm (end-to-end with rpmbuild)"
# ============================================================

# Only run if rpmbuild is available
if command -v rpmbuild >/dev/null 2>&1; then
  INPUT_SPEC_FILE=""
  INPUT_NAME="testpkg"
  INPUT_VERSION="2.0.0"
  INPUT_RELEASE="1"
  INPUT_ARCH="noarch"
  INPUT_SUMMARY="Test Package"
  INPUT_DESCRIPTION="A test package for CI"
  INPUT_LICENSE="MIT"
  INPUT_URL=""
  INPUT_SOURCE_DIR="${tmp_dir}/src"
  INPUT_INSTALL_PREFIX="/opt/testpkg"
  INPUT_OUTPUT_DIR="${tmp_dir}/rpm-output"
  INPUT_REQUIRES=""
  INPUT_SCRIPTS_PRE=""
  INPUT_SCRIPTS_POST=""

  true > "${GITHUB_OUTPUT}"
  build_rpm

  output="$(cat "${GITHUB_OUTPUT}")"
  assert_contains "${output}" "rpm-path=" "sets rpm-path output"
  assert_contains "${output}" "rpm-name=" "sets rpm-name output"
  assert_contains "${output}" ".rpm" "output is an rpm file"

  # Verify the RPM file exists
  rpm_path="$(grep 'rpm-path=' "${GITHUB_OUTPUT}" | cut -d= -f2)"
  assert_success "RPM file exists" test -f "${rpm_path}"
else
  echo "  SKIP: rpmbuild not available (tests will run in CI)"
fi

# ============================================================
test_summary
