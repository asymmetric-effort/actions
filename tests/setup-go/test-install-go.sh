#!/usr/bin/env bash
# Tests for actions/setup-go/scripts/install-go.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-go" && pwd)"
source "${ACTION_DIR}/scripts/install-go.sh"

# Setup
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
GITHUB_PATH="$(mktemp)"
GITHUB_ENV="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}" "${GITHUB_PATH}" "${GITHUB_ENV}"' EXIT

# ============================================================
test_suite "configure_setup_go"
# ============================================================

# Create a fake Go installation
mkdir -p "${tmp_dir}/sdk/go1.26.2/bin"
cat > "${tmp_dir}/sdk/go1.26.2/bin/go" << 'SCRIPT'
#!/usr/bin/env bash
echo "go version go1.26.2 linux/amd64"
SCRIPT
chmod +x "${tmp_dir}/sdk/go1.26.2/bin/go"
mkdir -p "${tmp_dir}/gopath/bin"

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"
true > "${GITHUB_ENV}"

configure_setup_go "${tmp_dir}/sdk/go1.26.2" "${tmp_dir}/gopath" "1.26.2"

output="$(cat "${GITHUB_OUTPUT}")"
path_output="$(cat "${GITHUB_PATH}")"
env_output="$(cat "${GITHUB_ENV}")"

assert_contains "${output}" "go-version=1.26.2" "sets go-version output"
assert_contains "${output}" "go-path=${tmp_dir}/gopath" "sets go-path output"
assert_contains "${path_output}" "${tmp_dir}/sdk/go1.26.2/bin" "adds Go bin to PATH"
assert_contains "${path_output}" "${tmp_dir}/gopath/bin" "adds GOPATH/bin to PATH"
assert_contains "${env_output}" "GOROOT=${tmp_dir}/sdk/go1.26.2" "sets GOROOT"
assert_contains "${env_output}" "GOPATH=${tmp_dir}/gopath" "sets GOPATH"

# ============================================================
test_suite "install_setup_go (already installed)"
# ============================================================

RESOLVED_VERSION="1.26.2"
DOWNLOAD_URL="https://go.dev/dl/go1.26.2.linux-amd64.tar.gz"
HOME="${tmp_dir}/cached-home"
mkdir -p "${HOME}/sdk/go1.26.2/bin"
cp "${tmp_dir}/sdk/go1.26.2/bin/go" "${HOME}/sdk/go1.26.2/bin/go"
chmod +x "${HOME}/sdk/go1.26.2/bin/go"
mkdir -p "${HOME}/go/bin"

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"
true > "${GITHUB_ENV}"

install_setup_go

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "go-version=1.26.2" "already installed: version output set"
assert_contains "${output}" "go-path=" "already installed: go-path output set"

# ============================================================
test_suite "install_setup_go (download - unreachable URL fails)"
# ============================================================

# install_setup_go will fail because the download URL is unreachable
assert_failure "download fails with unreachable URL in test" bash -c "
  export RESOLVED_VERSION=1.26.2
  export DOWNLOAD_URL=file:///nonexistent.tar.gz
  export HOME='${tmp_dir}/fail-home'
  export GITHUB_OUTPUT='${GITHUB_OUTPUT}'
  export GITHUB_PATH='${GITHUB_PATH}'
  export GITHUB_ENV='${GITHUB_ENV}'
  mkdir -p '${tmp_dir}/fail-home'
  source '${ACTION_DIR}/scripts/install-go.sh'
  install_setup_go
"

# ============================================================
test_summary
