#!/usr/bin/env bash
# Tests for actions/release/scripts/assets.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/release" && pwd)"
source "${ACTION_DIR}/scripts/assets.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

mkdir -p "${tmp_dir}/dist"
echo "data" > "${tmp_dir}/dist/app.tar.gz"
echo "data" > "${tmp_dir}/dist/app.zip"
echo "data" > "${tmp_dir}/dist/readme.txt"

# ============================================================
test_suite "get_mime_type"
# ============================================================

assert_eq "application/zip" "$(get_mime_type "app.zip")" ".zip"
assert_eq "application/gzip" "$(get_mime_type "app.tar.gz")" ".gz"
assert_eq "application/gzip" "$(get_mime_type "app.tgz")" ".tgz"
assert_eq "application/x-tar" "$(get_mime_type "app.tar")" ".tar"
assert_eq "application/x-bzip2" "$(get_mime_type "app.bz2")" ".bz2"
assert_eq "application/x-xz" "$(get_mime_type "app.xz")" ".xz"
assert_eq "application/vnd.debian.binary-package" "$(get_mime_type "app.deb")" ".deb"
assert_eq "application/x-rpm" "$(get_mime_type "app.rpm")" ".rpm"
assert_eq "application/octet-stream" "$(get_mime_type "app.exe")" ".exe"
assert_eq "application/octet-stream" "$(get_mime_type "app.msi")" ".msi"
assert_eq "application/octet-stream" "$(get_mime_type "app.dmg")" ".dmg"
assert_eq "application/javascript" "$(get_mime_type "app.js")" ".js"
assert_eq "application/json" "$(get_mime_type "data.json")" ".json"
assert_eq "text/plain" "$(get_mime_type "readme.txt")" ".txt"
assert_eq "text/markdown" "$(get_mime_type "doc.md")" ".md"
assert_eq "text/plain" "$(get_mime_type "file.sha256")" ".sha256"
assert_eq "text/plain" "$(get_mime_type "file.sha512")" ".sha512"
assert_eq "application/pgp-signature" "$(get_mime_type "file.sig")" ".sig"
assert_eq "application/pgp-signature" "$(get_mime_type "file.asc")" ".asc"
assert_eq "application/octet-stream" "$(get_mime_type "binary.xyz")" "unknown ext"
assert_eq "application/zip" "$(get_mime_type "APP.ZIP")" "case insensitive"

# ============================================================
test_suite "resolve_files (basic)"
# ============================================================

resolve_files "dist/*.tar.gz" "${tmp_dir}" "false"
assert_eq "1" "${#_RESOLVED_FILES[@]}" "matches one .tar.gz file"
if [[ ${#_RESOLVED_FILES[@]} -gt 0 ]]; then
  assert_contains "${_RESOLVED_FILES[0]}" "app.tar.gz" "correct file matched"
fi

# ============================================================
test_suite "resolve_files (multiple patterns)"
# ============================================================

resolve_files "$(printf 'dist/*.tar.gz\ndist/*.zip')" "${tmp_dir}" "false"
assert_eq "2" "${#_RESOLVED_FILES[@]}" "matches two files"

# ============================================================
test_suite "resolve_files (wildcard all)"
# ============================================================

resolve_files "dist/*" "${tmp_dir}" "false"
assert_eq "3" "${#_RESOLVED_FILES[@]}" "matches three files"

# ============================================================
test_suite "resolve_files (no match, no fail)"
# ============================================================

resolve_files "dist/*.missing" "${tmp_dir}" "false"
assert_eq "0" "${#_RESOLVED_FILES[@]}" "no files matched"

# ============================================================
test_suite "resolve_files (no match, fail)"
# ============================================================

assert_failure "fails on unmatched with flag" bash -c "
  source '${ACTION_DIR}/scripts/assets.sh'
  resolve_files 'dist/*.missing' '${tmp_dir}' 'true'
"

# ============================================================
test_suite "resolve_files (absolute paths)"
# ============================================================

resolve_files "${tmp_dir}/dist/*.zip" "${tmp_dir}" "false"
assert_eq "1" "${#_RESOLVED_FILES[@]}" "absolute glob resolves"

# ============================================================
test_suite "resolve_files (empty lines ignored)"
# ============================================================

resolve_files "$(printf '\n  \ndist/*.zip\n\n')" "${tmp_dir}" "false"
assert_eq "1" "${#_RESOLVED_FILES[@]}" "empty lines skipped"

# ============================================================
test_suite "resolve_files (filters directories)"
# ============================================================

mkdir -p "${tmp_dir}/dist/subdir"
resolve_files "dist/*" "${tmp_dir}" "false"
has_dir=0
i=0
while [[ $i -lt ${#_RESOLVED_FILES[@]} ]]; do
  if [[ -d "${_RESOLVED_FILES[$i]}" ]]; then
    has_dir=1
  fi
  i=$((i + 1))
done
assert_eq "0" "${has_dir}" "directories filtered out"

# ============================================================
test_suite "deduplicate_files"
# ============================================================

# shellcheck disable=SC2034
input_files=("${tmp_dir}/dist/app.zip" "${tmp_dir}/dist/app.zip" "${tmp_dir}/dist/app.tar.gz")
output_files=()
deduplicate_files input_files output_files
assert_eq "2" "${#output_files[@]}" "deduplicates files"

# ============================================================
test_summary
