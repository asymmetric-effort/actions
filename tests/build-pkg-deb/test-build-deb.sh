#!/usr/bin/env bash
# Tests for actions/build-pkg-deb/scripts/build-deb.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/build-pkg-deb" && pwd)"
source "${ACTION_DIR}/scripts/build-deb.sh"

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
test_suite "validate_control_file"
# ============================================================

echo "Package: test" > "${tmp_dir}/control"
assert_success "existing control file passes" validate_control_file "${tmp_dir}/control"

assert_failure "missing control file fails" validate_control_file "${tmp_dir}/nonexistent"

# ============================================================
test_suite "calculate_installed_size"
# ============================================================

result="$(calculate_installed_size "${tmp_dir}/src")"
assert_not_empty "${result}" "returns a size value"
# Size should be a positive number
assert_success "size is numeric" bash -c "[[ '${result}' =~ ^[0-9]+$ ]]"

# ============================================================
test_suite "generate_control"
# ============================================================

ctrl="$(generate_control "myapp" "1.0.0" "amd64" "Test User <test@example.com>" \
  "My Application" "A test application for CI." "utils" "optional" \
  "https://example.com" "libc6, bash" "42")"

assert_contains "${ctrl}" "Package: myapp" "control has Package"
assert_contains "${ctrl}" "Version: 1.0.0" "control has Version"
assert_contains "${ctrl}" "Architecture: amd64" "control has Architecture"
assert_contains "${ctrl}" "Maintainer: Test User <test@example.com>" "control has Maintainer"
assert_contains "${ctrl}" "Installed-Size: 42" "control has Installed-Size"
assert_contains "${ctrl}" "Section: utils" "control has Section"
assert_contains "${ctrl}" "Priority: optional" "control has Priority"
assert_contains "${ctrl}" "Depends: libc6, bash" "control has Depends"
assert_contains "${ctrl}" "Homepage: https://example.com" "control has Homepage"
assert_contains "${ctrl}" "Description: My Application" "control has Description"
assert_contains "${ctrl}" " A test application for CI." "control has long description"

# ============================================================
test_suite "generate_control (default maintainer)"
# ============================================================

ctrl="$(generate_control "pkg" "1.0" "all" "" "Summary" "" "devel" "optional" "" "" "10")"
assert_contains "${ctrl}" "Maintainer: Unknown" "defaults maintainer"

# ============================================================
test_suite "generate_control (no depends)"
# ============================================================

ctrl="$(generate_control "pkg" "1.0" "all" "" "Summary" "" "utils" "optional" "" "" "10")"
assert_not_contains "${ctrl}" "Depends:" "no Depends when empty"

# ============================================================
test_suite "generate_control (no homepage)"
# ============================================================

ctrl="$(generate_control "pkg" "1.0" "all" "" "Summary" "" "utils" "optional" "" "" "10")"
assert_not_contains "${ctrl}" "Homepage:" "no Homepage when empty"

# ============================================================
test_suite "generate_control (multiline description)"
# ============================================================

ctrl="$(generate_control "pkg" "1.0" "all" "" "Summary" "$(printf 'Line one\n\nLine three')" \
  "utils" "optional" "" "" "10")"
assert_contains "${ctrl}" " Line one" "first description line indented"
assert_contains "${ctrl}" " ." "empty line becomes ' .'"
assert_contains "${ctrl}" " Line three" "third description line indented"

# ============================================================
test_suite "setup_deb_tree"
# ============================================================

pkg_dir="${tmp_dir}/debpkg-test"
setup_deb_tree "${pkg_dir}" "${tmp_dir}/src" "/opt/myapp"

assert_success "DEBIAN dir exists" test -d "${pkg_dir}/DEBIAN"
assert_success "install dir exists" test -d "${pkg_dir}/opt/myapp"
assert_success "binary copied" test -f "${pkg_dir}/opt/myapp/bin/myapp"
assert_success "config copied" test -f "${pkg_dir}/opt/myapp/bin/myapp.conf"

# ============================================================
test_suite "write_maintainer_script"
# ============================================================

script_pkg="${tmp_dir}/script-test"
mkdir -p "${script_pkg}/DEBIAN"

write_maintainer_script "${script_pkg}" "postinst" "echo installed"
assert_file_exists "${script_pkg}/DEBIAN/postinst" "postinst script created"
assert_success "postinst is executable" test -x "${script_pkg}/DEBIAN/postinst"

# Read the script content
script_content="$(cat "${script_pkg}/DEBIAN/postinst")"
assert_contains "${script_content}" "#!/usr/bin/env bash" "has shebang"
assert_contains "${script_content}" "set -euo pipefail" "has strict mode"
assert_contains "${script_content}" "echo installed" "has user content"

# ============================================================
test_suite "write_maintainer_script (empty content)"
# ============================================================

write_maintainer_script "${script_pkg}" "preinst" ""
assert_failure "preinst not created when content empty" test -f "${script_pkg}/DEBIAN/preinst"

# ============================================================
test_suite "build_deb (end-to-end)"
# ============================================================

INPUT_CONTROL_FILE=""
INPUT_NAME="testpkg"
INPUT_VERSION="2.0.0"
INPUT_ARCH="amd64"
INPUT_MAINTAINER="CI <ci@example.com>"
INPUT_SUMMARY="Test Package"
INPUT_DESCRIPTION="A test package"
INPUT_SECTION="utils"
INPUT_PRIORITY="optional"
INPUT_HOMEPAGE=""
INPUT_SOURCE_DIR="${tmp_dir}/src"
INPUT_INSTALL_PREFIX="/opt/testpkg"
INPUT_OUTPUT_DIR="${tmp_dir}/deb-output"
INPUT_DEPENDS=""
INPUT_SCRIPTS_PREINST=""
INPUT_SCRIPTS_POSTINST=""

true > "${GITHUB_OUTPUT}"
build_deb

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "deb-path=" "sets deb-path output"
assert_contains "${output}" "deb-name=testpkg_2.0.0_amd64.deb" "sets correct deb-name"

deb_path="$(grep 'deb-path=' "${GITHUB_OUTPUT}" | cut -d= -f2)"
assert_success "DEB file exists" test -f "${deb_path}"

# Verify the DEB contents
deb_info="$(dpkg-deb --info "${deb_path}" 2>/dev/null || true)"
if [[ -n "${deb_info}" ]]; then
  assert_contains "${deb_info}" "Package: testpkg" "DEB has correct package name"
  assert_contains "${deb_info}" "Version: 2.0.0" "DEB has correct version"
fi

# ============================================================
test_suite "build_deb (with control file)"
# ============================================================

cat > "${tmp_dir}/custom-control" << 'CTRL'
Package: custompkg
Version: 3.0.0
Architecture: all
Maintainer: Test <test@test.com>
Description: Custom package
CTRL

INPUT_CONTROL_FILE="${tmp_dir}/custom-control"
INPUT_NAME=""
INPUT_VERSION=""
INPUT_OUTPUT_DIR="${tmp_dir}/deb-output-custom"

true > "${GITHUB_OUTPUT}"
build_deb

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "deb-name=custompkg_3.0.0_all.deb" "uses control file metadata for filename"

# ============================================================
test_summary
