#!/usr/bin/env bash
# Tests for actions/codeql-init/scripts/init.sh and shared.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the scripts under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/codeql-init" && pwd)"
COMMON_DIR="$(cd "${SCRIPT_DIR}/../../actions/codeql-common" && pwd)"
source "${COMMON_DIR}/scripts/shared.sh"
source "${ACTION_DIR}/scripts/init.sh"

# ============================================================
# Setup: stub GITHUB_OUTPUT and GITHUB_PATH
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
GITHUB_PATH="$(mktemp)"
GITHUB_ENV="$(mktemp)"
trap 'rm -f "${GITHUB_OUTPUT}" "${GITHUB_PATH}" "${GITHUB_ENV}"' EXIT

# ============================================================
test_suite "list_codeql_languages"
# ============================================================

result="$(list_codeql_languages "go,javascript")"
assert_eq "go,javascript" "${result}" "basic two-language list"

result="$(list_codeql_languages "  go , javascript , python  ")"
assert_eq "go,javascript,python" "${result}" "strips whitespace"

result="$(list_codeql_languages "Go,JavaScript,Python")"
assert_eq "go,javascript,python" "${result}" "lowercases languages"

result="$(list_codeql_languages "js")"
assert_eq "javascript" "${result}" "normalizes js to javascript"

result="$(list_codeql_languages "ts")"
assert_eq "javascript" "${result}" "normalizes ts to javascript"

result="$(list_codeql_languages "py")"
assert_eq "python" "${result}" "normalizes py to python"

result="$(list_codeql_languages "golang")"
assert_eq "go" "${result}" "normalizes golang to go"

result="$(list_codeql_languages "go,,python")"
assert_eq "go,python" "${result}" "handles empty entries"

result="$(list_codeql_languages "csharp")"
assert_eq "csharp" "${result}" "csharp passes through"

result="$(list_codeql_languages "cpp")"
assert_eq "cpp" "${result}" "cpp passes through"

# ============================================================
test_suite "build_codeql_download_url"
# ============================================================

url="$(build_codeql_download_url "latest")"
assert_eq "https://github.com/github/codeql-action/releases/latest/download/codeql-bundle-linux64.tar.gz" "${url}" "latest URL"

url="$(build_codeql_download_url "2.16.0")"
assert_eq "https://github.com/github/codeql-action/releases/download/codeql-bundle-v2.16.0/codeql-bundle-linux64.tar.gz" "${url}" "specific version URL"

url="$(build_codeql_download_url "2.15.3")"
assert_contains "${url}" "codeql-bundle-v2.15.3" "version embedded in URL"

# ============================================================
test_suite "get_codeql_databases_dir"
# ============================================================

# With CODEQL_DATABASES set
CODEQL_DATABASES="/tmp/test-dbs"
result="$(get_codeql_databases_dir)"
assert_eq "/tmp/test-dbs" "${result}" "returns CODEQL_DATABASES when set"
unset CODEQL_DATABASES

# Without CODEQL_DATABASES set (falls back to default)
result="$(get_codeql_databases_dir)"
assert_not_empty "${result}" "returns non-empty default path"

# ============================================================
test_suite "get_codeql_path"
# ============================================================

# With CODEQL_TOOL_DIR set
CODEQL_TOOL_DIR="/tmp/test-codeql"
result="$(get_codeql_path)"
assert_eq "/tmp/test-codeql/codeql" "${result}" "returns correct binary path"
unset CODEQL_TOOL_DIR

# Without CODEQL_TOOL_DIR set
result="$(get_codeql_path)"
assert_not_empty "${result}" "returns non-empty default path"
assert_contains "${result}" "codeql" "path contains codeql"

# ============================================================
test_summary
