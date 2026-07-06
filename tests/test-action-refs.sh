#!/usr/bin/env bash
# test-action-refs.sh — Verify that action.yml files don't reference local
# paths with ./actions/ which break when consumed from external repos.

# shellcheck disable=SC1091
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test-harness.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ============================================================
test_suite "action.yml files do not reference local ./actions/ paths"
# ============================================================

# Scan all action.yml files for uses: ./actions/ references.
# These break when the action is consumed from an external repository
# because the relative path resolves within the consumer's workspace,
# not the actions repo.

violations=""
while IFS= read -r action_file; do
  if grep -qP '^\s*uses:\s*\./actions/' "${action_file}" 2>/dev/null; then
    matches="$(grep -nP '^\s*uses:\s*\./actions/' "${action_file}")"
    violations="${violations}${action_file}:\n${matches}\n\n"
  fi
done < <(find "${REPO_ROOT}/actions" -name 'action.yml' -o -name 'action.yaml' 2>/dev/null)

if [[ -z "${violations}" ]]; then
  _TEST_TOTAL=$((_TEST_TOTAL + 1))
  _TEST_PASS=$((_TEST_PASS + 1))
  echo "  PASS: no action.yml files reference ./actions/ local paths"
else
  _TEST_TOTAL=$((_TEST_TOTAL + 1))
  _TEST_FAIL=$((_TEST_FAIL + 1))
  local_err="  FAIL: action.yml files reference ./actions/ local paths (breaks external consumers)"
  echo "${local_err}"
  echo -e "  Violations:\n${violations}"
  _TEST_ERRORS="${_TEST_ERRORS}${local_err}\n"
fi

# ============================================================
test_summary
