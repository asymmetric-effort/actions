#!/usr/bin/env bash
# run-all.sh — Run all test suites. Exit non-zero if any fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

run_test() {
  local test_file="$1"
  local name
  name="$(basename "${test_file}")"
  echo ""
  echo "========================================"
  echo "Running: ${name}"
  echo "========================================"

  if bash "${test_file}"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "FAILED: ${name}"
  fi
}

# Discover and run all test scripts
while IFS= read -r test_file; do
  run_test "${test_file}"
done < <(find "${SCRIPT_DIR}" -name 'test-*.sh' -not -name 'test-harness.sh' | sort)

echo ""
echo "========================================"
echo "Test suites: ${PASS} passed, ${FAIL} failed"
echo "========================================"

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
