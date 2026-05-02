#!/usr/bin/env bash
# Tests for actions/deploy-pages/scripts/deploy.sh

# shellcheck disable=SC1091,SC2034,SC2030,SC2031,SC2317
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/deploy-pages" && pwd)"
source "${ACTION_DIR}/scripts/deploy.sh"

tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "build_commit_message"
# ============================================================

GITHUB_SHA="abc1234567890"

# Default message
INPUT_COMMIT_MESSAGE=""
INPUT_FULL_COMMIT_MESSAGE=""
result="$(build_commit_message)"
assert_contains "${result}" "deploy:" "default message has deploy prefix"
assert_contains "${result}" "abc1234567890" "default message has source SHA"

# Custom message with SHA appended
INPUT_COMMIT_MESSAGE="custom deploy:"
result="$(build_commit_message)"
assert_contains "${result}" "custom deploy:" "custom message used"
assert_contains "${result}" "abc1234567890" "SHA appended to custom message"

# Full commit message (no SHA appended)
INPUT_FULL_COMMIT_MESSAGE="Full message, no SHA"
result="$(build_commit_message)"
assert_eq "Full message, no SHA" "${result}" "full_commit_message used as-is"
assert_not_contains "${result}" "abc1234567890" "no SHA in full_commit_message"

# Reset
INPUT_FULL_COMMIT_MESSAGE=""

# ============================================================
test_suite "get_remote_url"
# ============================================================

GITHUB_REPOSITORY="owner/repo"
GITHUB_SERVER_URL="https://github.com"

# Token auth
INPUT_TOKEN="test-token"
INPUT_DEPLOY_KEY=""
INPUT_EXTERNAL_REPOSITORY=""
result="$(get_remote_url)"
assert_contains "${result}" "x-access-token:test-token" "token in HTTPS URL"
assert_contains "${result}" "owner/repo.git" "repo in URL"

# Deploy key auth
INPUT_TOKEN=""
INPUT_DEPLOY_KEY="key-data"
result="$(get_remote_url)"
assert_contains "${result}" "git@github.com:owner/repo.git" "SSH URL for deploy key"

# External repository
INPUT_TOKEN="test-token"
INPUT_DEPLOY_KEY=""
INPUT_EXTERNAL_REPOSITORY="other-org/other-repo"
result="$(get_remote_url)"
assert_contains "${result}" "other-org/other-repo.git" "external repo in URL"

# Reset
INPUT_EXTERNAL_REPOSITORY=""

# ============================================================
test_suite "prepare_contents"
# ============================================================

# Create a publish directory
mkdir -p "${tmp_dir}/src"
echo "<html>" > "${tmp_dir}/src/index.html"
echo "body{}" > "${tmp_dir}/src/style.css"
mkdir -p "${tmp_dir}/src/.github"
echo "workflow" > "${tmp_dir}/src/.github/ci.yml"

# Prepare into a work directory
work_dir="${tmp_dir}/work1"
mkdir -p "${work_dir}"

INPUT_DESTINATION_DIR=""
INPUT_ENABLE_JEKYLL="false"
INPUT_CNAME=""
INPUT_EXCLUDE_ASSETS=".github"

prepare_contents "${tmp_dir}/src" "${work_dir}"

assert_success "index.html copied" test -f "${work_dir}/index.html"
assert_success "style.css copied" test -f "${work_dir}/style.css"
assert_success ".nojekyll created" test -f "${work_dir}/.nojekyll"
assert_failure ".github excluded" test -d "${work_dir}/.github"

# ============================================================
test_suite "prepare_contents (with CNAME)"
# ============================================================

work_dir="${tmp_dir}/work2"
mkdir -p "${work_dir}"
INPUT_CNAME="example.com"

prepare_contents "${tmp_dir}/src" "${work_dir}"

assert_success "CNAME file created" test -f "${work_dir}/CNAME"
cname_content="$(cat "${work_dir}/CNAME")"
assert_eq "example.com" "${cname_content}" "CNAME has correct domain"

INPUT_CNAME=""

# ============================================================
test_suite "prepare_contents (enable_jekyll)"
# ============================================================

work_dir="${tmp_dir}/work3"
mkdir -p "${work_dir}"
INPUT_ENABLE_JEKYLL="true"

prepare_contents "${tmp_dir}/src" "${work_dir}"

assert_failure "no .nojekyll when Jekyll enabled" test -f "${work_dir}/.nojekyll"

INPUT_ENABLE_JEKYLL="false"

# ============================================================
test_suite "prepare_contents (destination_dir)"
# ============================================================

work_dir="${tmp_dir}/work4"
mkdir -p "${work_dir}"
INPUT_DESTINATION_DIR="subsite"

prepare_contents "${tmp_dir}/src" "${work_dir}"

assert_success "subdir created" test -d "${work_dir}/subsite"
assert_success "index.html in subdir" test -f "${work_dir}/subsite/index.html"

INPUT_DESTINATION_DIR=""

# ============================================================
test_suite "prepare_contents (multiple exclude patterns)"
# ============================================================

mkdir -p "${tmp_dir}/src2"
echo "keep" > "${tmp_dir}/src2/index.html"
echo "remove" > "${tmp_dir}/src2/temp.log"
mkdir -p "${tmp_dir}/src2/.git"
echo "gitdata" > "${tmp_dir}/src2/.git/config"

work_dir="${tmp_dir}/work5"
mkdir -p "${work_dir}"
INPUT_EXCLUDE_ASSETS="$(printf '.git\n*.log')"

prepare_contents "${tmp_dir}/src2" "${work_dir}"

assert_success "index.html kept" test -f "${work_dir}/index.html"
assert_failure ".git excluded" test -d "${work_dir}/.git"
assert_failure "*.log excluded" test -f "${work_dir}/temp.log"

INPUT_EXCLUDE_ASSETS=".github"

# ============================================================
test_suite "deploy_to_pages (local git integration)"
# ============================================================

# Test a full deploy to a local bare repo
bare_repo="${tmp_dir}/bare.git"
git init --bare -q "${bare_repo}"

# Create publish content
mkdir -p "${tmp_dir}/deploy-src"
echo "<h1>Hello</h1>" > "${tmp_dir}/deploy-src/index.html"

INPUT_TOKEN="unused"
INPUT_DEPLOY_KEY=""
INPUT_PUBLISH_DIR="${tmp_dir}/deploy-src"
INPUT_PUBLISH_BRANCH="gh-pages"
INPUT_FORCE_ORPHAN="true"
INPUT_KEEP_FILES="false"
INPUT_ALLOW_EMPTY_COMMIT="false"
INPUT_USER_NAME="Test User"
INPUT_USER_EMAIL="test@test.com"
INPUT_COMMIT_MESSAGE=""
INPUT_FULL_COMMIT_MESSAGE="Test deploy"
INPUT_TAG_NAME=""
INPUT_TAG_MESSAGE=""
INPUT_ENABLE_JEKYLL="false"
INPUT_CNAME=""
INPUT_EXCLUDE_ASSETS=""
INPUT_EXTERNAL_REPOSITORY=""
INPUT_DESTINATION_DIR=""
GITHUB_SHA="deadbeef"
GITHUB_REPOSITORY="test/repo"
GITHUB_SERVER_URL="https://github.com"

# Run deploy in a subshell with overridden remote URL
(
  source "${ACTION_DIR}/scripts/deploy.sh"
  # Override get_remote_url to use our local bare repo
  get_remote_url() { echo "${bare_repo}"; }
  export GITHUB_OUTPUT="${GITHUB_OUTPUT}"
  true > "${GITHUB_OUTPUT}"
  deploy_to_pages
)

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "deploy_branch=gh-pages" "outputs deploy_branch"
assert_contains "${output}" "commit_hash=" "outputs commit_hash"

# Verify the content was pushed
verify_dir="${tmp_dir}/verify"
git clone -q -b gh-pages "${bare_repo}" "${verify_dir}"
assert_success "index.html deployed" test -f "${verify_dir}/index.html"
assert_success ".nojekyll created" test -f "${verify_dir}/.nojekyll"

deployed_content="$(cat "${verify_dir}/index.html")"
assert_eq "<h1>Hello</h1>" "${deployed_content}" "correct content deployed"

# ============================================================
test_suite "deploy_to_pages (with tag)"
# ============================================================

echo "<h1>v2</h1>" > "${tmp_dir}/deploy-src/index.html"
INPUT_TAG_NAME="v1.0.0"
INPUT_TAG_MESSAGE="Release 1.0.0"
INPUT_FULL_COMMIT_MESSAGE="Deploy v2"

(
  source "${ACTION_DIR}/scripts/deploy.sh"
  get_remote_url() { echo "${bare_repo}"; }
  export GITHUB_OUTPUT="${GITHUB_OUTPUT}"
  true > "${GITHUB_OUTPUT}"
  deploy_to_pages
)

# Verify tag was created
tag_output="$(cd "${verify_dir}" && git fetch -q origin 2>/dev/null; git tag -l 2>/dev/null || true)"
assert_contains "${tag_output}" "v1.0.0" "tag pushed"

INPUT_TAG_NAME=""
INPUT_TAG_MESSAGE=""

# ============================================================
test_summary
