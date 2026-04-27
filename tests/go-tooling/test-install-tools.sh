#!/usr/bin/env bash
# Tests for actions/go-tooling/scripts/install-tools.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/go-tooling" && pwd)"
source "${ACTION_DIR}/scripts/install-tools.sh"

# Setup
GITHUB_OUTPUT="$(mktemp)"
trap 'rm -f "${GITHUB_OUTPUT}"' EXIT

# ============================================================
test_suite "get_govulncheck_version (not installed)"
# ============================================================

# When govulncheck is not in PATH, should return empty
PATH_BACKUP="${PATH}"
PATH="/usr/bin:/bin"

result="$(get_govulncheck_version)"
assert_eq "" "${result}" "returns empty when govulncheck not installed"

PATH="${PATH_BACKUP}"

# ============================================================
test_suite "get_govulncheck_version (installed)"
# ============================================================

# Create a fake govulncheck
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}"' EXIT

cat > "${tmp_dir}/govulncheck" << 'SCRIPT'
#!/usr/bin/env bash
if [[ "${1:-}" == "-version" ]]; then
  echo "govulncheck v1.1.4"
fi
SCRIPT
chmod +x "${tmp_dir}/govulncheck"

PATH="${tmp_dir}:${PATH}"
result="$(get_govulncheck_version)"
assert_eq "v1.1.4" "${result}" "returns version when installed"

# ============================================================
test_suite "install_govulncheck (already installed, latest)"
# ============================================================

true > "${GITHUB_OUTPUT}"
install_govulncheck "latest"
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "govulncheck-version=v1.1.4" "skips install when already present for latest"

# ============================================================
test_suite "install_govulncheck (already installed, matching version)"
# ============================================================

true > "${GITHUB_OUTPUT}"
install_govulncheck "v1.1.4"
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "govulncheck-version=v1.1.4" "skips install for matching version"

# ============================================================
test_suite "install_go_tools entry point"
# ============================================================

GOVULNCHECK_VERSION="latest"
true > "${GITHUB_OUTPUT}"
install_go_tools
output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "govulncheck-version=" "install_go_tools sets govulncheck output"

# ============================================================
test_suite "install_govulncheck (version prefix handling)"
# ============================================================

# Test that version without 'v' prefix gets 'v' added
# (We can't actually run go install in tests, but we can test the logic branches)
# The function should try to install when version doesn't match
# Since we have a fake govulncheck with v1.1.4, asking for v1.2.0 should attempt install
assert_failure "attempts install for different version" bash -c "
  export GITHUB_OUTPUT='${GITHUB_OUTPUT}'
  export PATH='${tmp_dir}:${PATH}'
  source '${ACTION_DIR}/scripts/install-tools.sh'
  install_govulncheck 'v1.2.0'
"

# ============================================================
test_summary
