#!/usr/bin/env bash
# test-harness.sh — Minimal bash test harness for composite GitHub Actions.
# No external dependencies. Tracks pass/fail counts and exits non-zero on failure.

set -euo pipefail

_TEST_PASS=0
_TEST_FAIL=0
_TEST_TOTAL=0
_TEST_SUITE=""
_TEST_ERRORS=""

# Set the current test suite name
test_suite() {
  _TEST_SUITE="$1"
  echo ""
  echo "=== ${_TEST_SUITE} ==="
}

# Assert that two values are equal
assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"
  _TEST_TOTAL=$((_TEST_TOTAL + 1))

  if [[ "${expected}" == "${actual}" ]]; then
    _TEST_PASS=$((_TEST_PASS + 1))
    echo "  PASS: ${message:-assert_eq}"
  else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    local err="  FAIL: ${message:-assert_eq} — expected '${expected}', got '${actual}'"
    echo "${err}"
    _TEST_ERRORS="${_TEST_ERRORS}${err}\n"
  fi
}

# Assert that a value is not empty
assert_not_empty() {
  local actual="$1"
  local message="${2:-}"
  _TEST_TOTAL=$((_TEST_TOTAL + 1))

  if [[ -n "${actual}" ]]; then
    _TEST_PASS=$((_TEST_PASS + 1))
    echo "  PASS: ${message:-assert_not_empty}"
  else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    local err="  FAIL: ${message:-assert_not_empty} — value was empty"
    echo "${err}"
    _TEST_ERRORS="${_TEST_ERRORS}${err}\n"
  fi
}

# Assert that a string contains a substring
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-}"
  _TEST_TOTAL=$((_TEST_TOTAL + 1))

  if [[ "${haystack}" == *"${needle}"* ]]; then
    _TEST_PASS=$((_TEST_PASS + 1))
    echo "  PASS: ${message:-assert_contains}"
  else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    local err="  FAIL: ${message:-assert_contains} — '${haystack}' does not contain '${needle}'"
    echo "${err}"
    _TEST_ERRORS="${_TEST_ERRORS}${err}\n"
  fi
}

# Assert that a string does NOT contain a substring
assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-}"
  _TEST_TOTAL=$((_TEST_TOTAL + 1))

  if [[ "${haystack}" != *"${needle}"* ]]; then
    _TEST_PASS=$((_TEST_PASS + 1))
    echo "  PASS: ${message:-assert_not_contains}"
  else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    local err="  FAIL: ${message:-assert_not_contains} — '${haystack}' contains '${needle}'"
    echo "${err}"
    _TEST_ERRORS="${_TEST_ERRORS}${err}\n"
  fi
}

# Assert that a command exits with code 0
assert_success() {
  local message="${1:-}"
  shift
  _TEST_TOTAL=$((_TEST_TOTAL + 1))

  if "$@" >/dev/null 2>&1; then
    _TEST_PASS=$((_TEST_PASS + 1))
    echo "  PASS: ${message:-assert_success}"
  else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    local err="  FAIL: ${message:-assert_success} — command failed: $*"
    echo "${err}"
    _TEST_ERRORS="${_TEST_ERRORS}${err}\n"
  fi
}

# Assert that a command exits with a non-zero code
assert_failure() {
  local message="${1:-}"
  shift
  _TEST_TOTAL=$((_TEST_TOTAL + 1))

  if "$@" >/dev/null 2>&1; then
    _TEST_FAIL=$((_TEST_FAIL + 1))
    local err="  FAIL: ${message:-assert_failure} — command succeeded but should have failed: $*"
    echo "${err}"
    _TEST_ERRORS="${_TEST_ERRORS}${err}\n"
  else
    _TEST_PASS=$((_TEST_PASS + 1))
    echo "  PASS: ${message:-assert_failure}"
  fi
}

# Assert a file exists
assert_file_exists() {
  local path="$1"
  local message="${2:-}"
  _TEST_TOTAL=$((_TEST_TOTAL + 1))

  if [[ -f "${path}" ]]; then
    _TEST_PASS=$((_TEST_PASS + 1))
    echo "  PASS: ${message:-file exists: ${path}}"
  else
    _TEST_FAIL=$((_TEST_FAIL + 1))
    local err="  FAIL: ${message:-file not found: ${path}}"
    echo "${err}"
    _TEST_ERRORS="${_TEST_ERRORS}${err}\n"
  fi
}

# Print summary and exit
test_summary() {
  echo ""
  echo "================================"
  echo "Results: ${_TEST_PASS} passed, ${_TEST_FAIL} failed, ${_TEST_TOTAL} total"
  echo "================================"

  if [[ ${_TEST_FAIL} -gt 0 ]]; then
    echo ""
    echo "Failures:"
    echo -e "${_TEST_ERRORS}"
    exit 1
  fi

  exit 0
}
