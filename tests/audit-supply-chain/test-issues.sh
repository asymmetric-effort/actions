#!/usr/bin/env bash
# Tests for actions/audit-supply-chain/scripts/issues.sh

# shellcheck disable=SC1091,SC2016
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the scripts under test (issues.sh depends on scan.sh for extract_action_path).
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/audit-supply-chain" && pwd)"
source "${ACTION_DIR}/scripts/scan.sh"
source "${ACTION_DIR}/scripts/issues.sh"

# ============================================================
# Setup
# ============================================================
export GITHUB_SERVER_URL="https://github.com"

# ============================================================
test_suite "build_upstream_url"
# ============================================================

assert_eq "https://github.com/softprops/action-gh-release" \
  "$(build_upstream_url "softprops/action-gh-release")" \
  "builds upstream URL"

assert_eq "https://github.com/docker/build-push-action" \
  "$(build_upstream_url "docker/build-push-action")" \
  "builds docker upstream URL"

assert_eq "https://github.com/peaceiris/actions-gh-pages" \
  "$(build_upstream_url "peaceiris/actions-gh-pages")" \
  "builds peaceiris upstream URL"

# ============================================================
test_suite "build_workflow_url"
# ============================================================

assert_eq "https://github.com/asymmetric-effort/myrepo/blob/main/.github/workflows/ci.yml" \
  "$(build_workflow_url "asymmetric-effort/myrepo" ".github/workflows/ci.yml")" \
  "builds workflow URL"

assert_eq "https://github.com/asymmetric-effort/other/blob/main/.github/workflows/deploy.yaml" \
  "$(build_workflow_url "asymmetric-effort/other" ".github/workflows/deploy.yaml")" \
  "builds workflow URL with yaml extension"

# ============================================================
test_suite "build_issue_title"
# ============================================================

assert_eq 'Replace `softprops/action-gh-release` with internal action' \
  "$(build_issue_title "softprops/action-gh-release")" \
  "builds issue title"

assert_eq 'Replace `docker/build-push-action` with internal action' \
  "$(build_issue_title "docker/build-push-action")" \
  "builds issue title for docker action"

# ============================================================
test_suite "build_issue_body"
# ============================================================

body="$(build_issue_body \
  "softprops/action-gh-release@v2" \
  "softprops/action-gh-release" \
  ".github/workflows/ci.yml" \
  "asymmetric-effort/myrepo" \
  "https://github.com/softprops/action-gh-release" \
  "https://github.com/asymmetric-effort/myrepo/blob/main/.github/workflows/ci.yml")"

assert_contains "$body" "Third-Party Action Replacement Request" "body has title"
assert_contains "$body" "softprops/action-gh-release@v2" "body has action ref"
assert_contains "$body" "https://github.com/softprops/action-gh-release" "body has upstream URL"
assert_contains "$body" ".github/workflows/ci.yml" "body has workflow file"
assert_contains "$body" "supply-chain dependency" "body mentions supply chain"

# ============================================================
test_suite "LABEL_NAME"
# ============================================================

assert_eq "github-action-request" "$LABEL_NAME" "label name is github-action-request"

# ============================================================
test_summary
