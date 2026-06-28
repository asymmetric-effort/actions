#!/usr/bin/env bash
# Tests for actions/configure-pages/scripts/parse-url.sh and configure.sh

# shellcheck disable=SC1091,SC2034,SC2030,SC2031,SC2317
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/configure-pages" && pwd)"
source "${ACTION_DIR}/scripts/parse-url.sh"
source "${ACTION_DIR}/scripts/configure.sh"

GITHUB_OUTPUT="$(mktemp)"
trap 'rm -f "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "extract_origin"
# ============================================================

result="$(extract_origin "https://user.github.io/repo")"
assert_eq "https://user.github.io" "${result}" "origin from project site URL"

result="$(extract_origin "https://user.github.io")"
assert_eq "https://user.github.io" "${result}" "origin from user site URL"

result="$(extract_origin "https://custom-domain.com")"
assert_eq "https://custom-domain.com" "${result}" "origin from custom domain"

result="$(extract_origin "https://custom-domain.com/sub")"
assert_eq "https://custom-domain.com" "${result}" "origin from custom domain with path"

# ============================================================
test_suite "extract_host"
# ============================================================

result="$(extract_host "https://user.github.io/repo")"
assert_eq "user.github.io" "${result}" "host from project site URL"

result="$(extract_host "https://user.github.io")"
assert_eq "user.github.io" "${result}" "host from user site URL"

result="$(extract_host "https://custom-domain.com")"
assert_eq "custom-domain.com" "${result}" "host from custom domain"

result="$(extract_host "https://custom-domain.com/sub")"
assert_eq "custom-domain.com" "${result}" "host from custom domain with path"

# ============================================================
test_suite "extract_base_path"
# ============================================================

result="$(extract_base_path "https://user.github.io/repo")"
assert_eq "/repo" "${result}" "base_path from project site URL"

result="$(extract_base_path "https://user.github.io")"
assert_eq "/" "${result}" "base_path from user site (no path)"

result="$(extract_base_path "https://custom-domain.com")"
assert_eq "/" "${result}" "base_path from custom domain (no path)"

result="$(extract_base_path "https://custom-domain.com/sub")"
assert_eq "/sub" "${result}" "base_path from custom domain with path"

result="$(extract_base_path "https://user.github.io/")"
assert_eq "/" "${result}" "base_path from URL with trailing slash"

# ============================================================
test_suite "parse_pages_url — project site"
# ============================================================

parse_pages_url "https://user.github.io/repo"
assert_eq "https://user.github.io/repo" "${PAGES_BASE_URL}" "base_url for project site"
assert_eq "https://user.github.io" "${PAGES_ORIGIN}" "origin for project site"
assert_eq "user.github.io" "${PAGES_HOST}" "host for project site"
assert_eq "/repo" "${PAGES_BASE_PATH}" "base_path for project site"

# ============================================================
test_suite "parse_pages_url — user site"
# ============================================================

parse_pages_url "https://user.github.io"
assert_eq "https://user.github.io" "${PAGES_BASE_URL}" "base_url for user site"
assert_eq "https://user.github.io" "${PAGES_ORIGIN}" "origin for user site"
assert_eq "user.github.io" "${PAGES_HOST}" "host for user site"
assert_eq "/" "${PAGES_BASE_PATH}" "base_path for user site"

# ============================================================
test_suite "parse_pages_url — custom domain"
# ============================================================

parse_pages_url "https://custom-domain.com"
assert_eq "https://custom-domain.com" "${PAGES_BASE_URL}" "base_url for custom domain"
assert_eq "https://custom-domain.com" "${PAGES_ORIGIN}" "origin for custom domain"
assert_eq "custom-domain.com" "${PAGES_HOST}" "host for custom domain"
assert_eq "/" "${PAGES_BASE_PATH}" "base_path for custom domain"

# ============================================================
test_suite "parse_pages_url — custom domain with path"
# ============================================================

parse_pages_url "https://custom-domain.com/sub"
assert_eq "https://custom-domain.com/sub" "${PAGES_BASE_URL}" "base_url for custom domain with path"
assert_eq "https://custom-domain.com" "${PAGES_ORIGIN}" "origin for custom domain with path"
assert_eq "custom-domain.com" "${PAGES_HOST}" "host for custom domain with path"
assert_eq "/sub" "${PAGES_BASE_PATH}" "base_path for custom domain with path"

# ============================================================
test_suite "parse_pages_url — trailing slash normalization"
# ============================================================

parse_pages_url "https://user.github.io/repo/"
assert_eq "https://user.github.io/repo" "${PAGES_BASE_URL}" "trailing slash removed from base_url"
assert_eq "/repo" "${PAGES_BASE_PATH}" "base_path correct after trailing slash removal"

# ============================================================
test_suite "enable_pages_payload"
# ============================================================

payload="$(enable_pages_payload)"
assert_contains "${payload}" '"build_type":"workflow"' "payload has build_type"
assert_contains "${payload}" '"branch":"main"' "payload has branch"
assert_contains "${payload}" '"path":"/"' "payload has path"

# ============================================================
test_summary
