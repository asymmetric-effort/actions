#!/usr/bin/env bash
# Tests for actions/fossa-scan/action.yml structure and content

# shellcheck disable=SC1091
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_FILE="$(cd "${SCRIPT_DIR}/../../actions/fossa-scan" && pwd)/action.yml"

# ============================================================
test_suite "action.yml exists and has content"
# ============================================================

assert_file_exists "${ACTION_FILE}" "action.yml exists"

content="$(cat "${ACTION_FILE}")"
assert_not_empty "${content}" "action.yml is not empty"

# ============================================================
test_suite "metadata"
# ============================================================

assert_contains "${content}" 'name: "FOSSA Scan"' "has correct name"
assert_contains "${content}" 'using: "composite"' "uses composite runs"
assert_contains "${content}" "Asymmetric Effort" "has author"

# ============================================================
test_suite "inputs"
# ============================================================

assert_contains "${content}" "api-key:" "has api-key input"
assert_contains "${content}" "required: true" "api-key is required"
assert_contains "${content}" "run-tests:" "has run-tests input"
assert_contains "${content}" "endpoint:" "has endpoint input"
assert_contains "${content}" "cli-version:" "has cli-version input"
assert_contains "${content}" "debug:" "has debug input"
assert_contains "${content}" "working-directory:" "has working-directory input"

# ============================================================
test_suite "defaults"
# ============================================================

assert_contains "${content}" 'default: "false"' "has false defaults"
assert_contains "${content}" 'default: "https://app.fossa.com"' "endpoint default"
assert_contains "${content}" 'default: "latest"' "cli-version default"
assert_contains "${content}" 'default: "."' "working-directory default"

# ============================================================
test_suite "steps"
# ============================================================

assert_contains "${content}" "Validate inputs" "has validation step"
assert_contains "${content}" "Install FOSSA CLI" "has install step"
assert_contains "${content}" "Run FOSSA analyze" "has analyze step"
assert_contains "${content}" "Run FOSSA test" "has test step"

# ============================================================
test_suite "shell safety"
# ============================================================

assert_contains "${content}" "set -euo pipefail" "uses strict bash mode"
assert_contains "${content}" "shell: bash" "all steps use bash"

# ============================================================
test_suite "security"
# ============================================================

assert_contains "${content}" "FOSSA_API_KEY" "uses env var for API key"
assert_not_contains "${content}" "fossa_key_" "no hardcoded key prefixes"

# Check no hardcoded tokens (strings 32+ chars of alphanumeric)
lines="$(grep -cP '[A-Za-z0-9_]{40,}' "${ACTION_FILE}" || true)"
assert_eq "0" "${lines}" "no hardcoded long tokens"

# ============================================================
test_suite "conditional test step"
# ============================================================

assert_contains "${content}" "inputs.run-tests" "test step is conditional"

# ============================================================
test_summary
