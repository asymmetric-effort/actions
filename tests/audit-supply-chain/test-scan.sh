#!/usr/bin/env bash
# Tests for actions/audit-supply-chain/scripts/scan.sh

# shellcheck disable=SC1091
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the script under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/audit-supply-chain" && pwd)"
source "${ACTION_DIR}/scripts/scan.sh"

# ============================================================
test_suite "parse_allowed_orgs"
# ============================================================

parse_allowed_orgs "actions,github,asymmetric-effort"
assert_eq "3" "${#ALLOWED_ORGS_ARRAY[@]}" "parses three orgs"
assert_eq "actions" "${ALLOWED_ORGS_ARRAY[0]}" "first org is actions"
assert_eq "github" "${ALLOWED_ORGS_ARRAY[1]}" "second org is github"
assert_eq "asymmetric-effort" "${ALLOWED_ORGS_ARRAY[2]}" "third org is asymmetric-effort"

parse_allowed_orgs "actions , github , asymmetric-effort"
assert_eq "actions" "${ALLOWED_ORGS_ARRAY[0]}" "trims whitespace from first"
assert_eq "github" "${ALLOWED_ORGS_ARRAY[1]}" "trims whitespace from second"
assert_eq "asymmetric-effort" "${ALLOWED_ORGS_ARRAY[2]}" "trims whitespace from third"

parse_allowed_orgs "single-org"
assert_eq "1" "${#ALLOWED_ORGS_ARRAY[@]}" "handles single org"
assert_eq "single-org" "${ALLOWED_ORGS_ARRAY[0]}" "single org value"

# ============================================================
test_suite "is_allowed_org"
# ============================================================

parse_allowed_orgs "actions,github,asymmetric-effort"

assert_success "actions is allowed" is_allowed_org "actions"
assert_success "github is allowed" is_allowed_org "github"
assert_success "asymmetric-effort is allowed" is_allowed_org "asymmetric-effort"
assert_failure "softprops is not allowed" is_allowed_org "softprops"
assert_failure "docker is not allowed" is_allowed_org "docker"
assert_failure "empty string is not allowed" is_allowed_org ""

# ============================================================
test_suite "extract_org"
# ============================================================

assert_eq "softprops" "$(extract_org "softprops/action-gh-release@v2")" "extracts org from action ref"
assert_eq "actions" "$(extract_org "actions/checkout@v4")" "extracts actions org"
assert_eq "github" "$(extract_org "github/codeql-action/init@v3")" "extracts github org from subpath"
assert_eq "asymmetric-effort" "$(extract_org "asymmetric-effort/actions/actions/setup-bun@v1")" "extracts org from deep path"

# ============================================================
test_suite "extract_action_path"
# ============================================================

assert_eq "softprops/action-gh-release" "$(extract_action_path "softprops/action-gh-release@v2")" "extracts path without ref"
assert_eq "actions/checkout" "$(extract_action_path "actions/checkout@v4")" "extracts actions path"
assert_eq "github/codeql-action/init" "$(extract_action_path "github/codeql-action/init@v3")" "extracts subpath"

# ============================================================
test_suite "extract_uses_from_file"
# ============================================================

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# Create a test workflow file.
cat > "${tmp_dir}/test-workflow.yml" << 'WORKFLOW'
name: Test
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: softprops/action-gh-release@v2
      - uses: ./local-action
      - uses: docker://alpine:3.18
      - uses: asymmetric-effort/actions/actions/setup-bun@v1
WORKFLOW

result="$(extract_uses_from_file "${tmp_dir}/test-workflow.yml")"
assert_contains "$result" "actions/checkout@v4" "finds actions/checkout"
assert_contains "$result" "softprops/action-gh-release@v2" "finds softprops action"
assert_contains "$result" "asymmetric-effort/actions/actions/setup-bun@v1" "finds asymmetric-effort action"
assert_not_contains "$result" "./local-action" "skips local actions"
assert_not_contains "$result" "docker://" "skips docker references"

# Empty file.
touch "${tmp_dir}/empty.yml"
result="$(extract_uses_from_file "${tmp_dir}/empty.yml")"
assert_eq "" "$result" "empty file returns nothing"

# ============================================================
test_suite "scan_workflows"
# ============================================================

# Set up a fake .github/workflows directory.
mkdir -p "${tmp_dir}/repo/.github/workflows"
cat > "${tmp_dir}/repo/.github/workflows/ci.yml" << 'WORKFLOW'
name: CI
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: softprops/action-gh-release@v2
      - uses: docker/build-push-action@v5
      - uses: asymmetric-effort/actions/actions/setup-bun@v1
WORKFLOW

cat > "${tmp_dir}/repo/.github/workflows/deploy.yml" << 'WORKFLOW'
name: Deploy
on: push
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: softprops/action-gh-release@v2
      - uses: peaceiris/actions-gh-pages@v3
WORKFLOW

parse_allowed_orgs "actions,github,asymmetric-effort"

# Run from the fake repo root.
cd "${tmp_dir}/repo"
result="$(scan_workflows)"

assert_contains "$result" "softprops/action-gh-release" "finds softprops action"
assert_contains "$result" "docker/build-push-action" "finds docker action"
assert_contains "$result" "peaceiris/actions-gh-pages" "finds peaceiris action"
assert_not_contains "$result" "actions/checkout" "skips allowed org: actions"
assert_not_contains "$result" "asymmetric-effort" "skips allowed org: asymmetric-effort"

# Check deduplication — softprops appears in both files but should appear once.
dup_count="$(echo "$result" | grep -c "softprops/action-gh-release" || true)"
assert_eq "1" "$dup_count" "deduplicates across workflow files"

# ============================================================
test_summary
