#!/usr/bin/env bash
# Tests for actions/upload-pages-artifact/scripts/package.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/upload-pages-artifact" && pwd)"
source "${ACTION_DIR}/scripts/package.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# Mock GITHUB_OUTPUT
GITHUB_OUTPUT="${tmp_dir}/github_output"
touch "${GITHUB_OUTPUT}"

# ============================================================
test_suite "package_pages_artifact"
# ============================================================

# Test: creates tar.gz archive
mkdir -p "${tmp_dir}/site"
echo "<html>hello</html>" > "${tmp_dir}/site/index.html"
echo "body{}" > "${tmp_dir}/site/style.css"
INPUT_PATH="${tmp_dir}/site"
GITHUB_OUTPUT="${tmp_dir}/github_output"
true > "${GITHUB_OUTPUT}"

package_pages_artifact

artifact_path="$(grep '^artifact-path=' "${GITHUB_OUTPUT}" | cut -d= -f2-)"
assert_not_empty "${artifact_path}" "artifact-path output is set"
assert_file_exists "${artifact_path}" "tar.gz archive exists"

# Test: .nojekyll is added if missing
assert_file_exists "${tmp_dir}/site/.nojekyll" ".nojekyll created in source directory"

# Test: archive contents are flat (no parent directory wrapper)
extract_dir="${tmp_dir}/extracted"
mkdir -p "${extract_dir}"
tar -xzf "${artifact_path}" -C "${extract_dir}"

assert_file_exists "${extract_dir}/index.html" "index.html at root of archive"
assert_file_exists "${extract_dir}/style.css" "style.css at root of archive"
assert_file_exists "${extract_dir}/.nojekyll" ".nojekyll in archive"

# Test: .nojekyll not duplicated if already present
mkdir -p "${tmp_dir}/site2"
echo "<html></html>" > "${tmp_dir}/site2/index.html"
touch "${tmp_dir}/site2/.nojekyll"
INPUT_PATH="${tmp_dir}/site2"
true > "${GITHUB_OUTPUT}"

package_pages_artifact

artifact_path2="$(grep '^artifact-path=' "${GITHUB_OUTPUT}" | cut -d= -f2-)"
assert_file_exists "${artifact_path2}" "tar.gz created when .nojekyll already exists"

# Verify no ::notice:: about creating .nojekyll (it already existed)
extract_dir2="${tmp_dir}/extracted2"
mkdir -p "${extract_dir2}"
tar -xzf "${artifact_path2}" -C "${extract_dir2}"
assert_file_exists "${extract_dir2}/.nojekyll" ".nojekyll preserved in archive"

# ============================================================
test_summary
