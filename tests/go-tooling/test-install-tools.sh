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
test_suite "install_govulncheck (version mismatch triggers install)"
# ============================================================

# When installed version (v1.1.4) doesn't match requested (v1.2.0),
# the function should NOT skip — it should attempt go install.
# We verify by checking that the "already installed (from cache)" message is NOT emitted.
true > "${GITHUB_OUTPUT}"

# Create a subshell with a fake 'go' that fails, so we can detect the attempt
assert_failure "attempts go install for mismatched version" bash -c "
  export GITHUB_OUTPUT='${GITHUB_OUTPUT}'
  fake_dir=\$(mktemp -d)
  # Fake govulncheck that reports v1.1.4
  cat > \"\${fake_dir}/govulncheck\" << 'GOVULN'
#!/usr/bin/env bash
if [[ \"\${1:-}\" == \"-version\" ]]; then echo 'govulncheck v1.1.4'; fi
GOVULN
  chmod +x \"\${fake_dir}/govulncheck\"
  # Fake go that always fails (simulates go not being configured)
  cat > \"\${fake_dir}/go\" << 'GOFAKE'
#!/usr/bin/env bash
exit 1
GOFAKE
  chmod +x \"\${fake_dir}/go\"
  export PATH=\"\${fake_dir}:/usr/bin:/bin\"
  source '${ACTION_DIR}/scripts/install-tools.sh'
  install_govulncheck 'v1.2.0'
"

# ============================================================
test_summary
