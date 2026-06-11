#!/usr/bin/env bash
# Tests for actions/setup-python/scripts/install-python.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the scripts under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/setup-python" && pwd)"
source "${ACTION_DIR}/scripts/resolve-version.sh"
source "${ACTION_DIR}/scripts/cache-utils.sh"
source "${ACTION_DIR}/scripts/install-python.sh"

# ============================================================
# Setup
# ============================================================
tmp_dir="$(mktemp -d)"
GITHUB_OUTPUT="$(mktemp)"
GITHUB_PATH="$(mktemp)"
GITHUB_ENV="$(mktemp)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}" "${GITHUB_PATH}" "${GITHUB_ENV}"' EXIT

# ============================================================
test_suite "configure_python"
# ============================================================

# Create a fake python that prints a version
mkdir -p "${tmp_dir}/fake-python/bin"
cat > "${tmp_dir}/fake-python/bin/python3" << 'SCRIPT'
#!/usr/bin/env bash
case "$1" in
  --version) echo "Python 3.12.1" ;;
  -c) eval "$2" 2>/dev/null || echo "/usr/lib/python3/site-packages" ;;
  -m)
    if [[ "$2" == "pip" ]]; then
      if [[ "${3:-}" == "cache" && "${4:-}" == "dir" ]]; then
        echo "/tmp/pip-cache"
      elif [[ "${3:-}" == "--version" ]]; then
        echo "pip 23.0"
      fi
    fi
    ;;
esac
SCRIPT
chmod +x "${tmp_dir}/fake-python/bin/python3"

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"
true > "${GITHUB_ENV}"

configure_python "${tmp_dir}/fake-python/bin" "3.12.1" ""

output="$(cat "${GITHUB_OUTPUT}")"
path_output="$(cat "${GITHUB_PATH}")"

assert_contains "${output}" "python-version=3.12.1" "sets python-version output"
assert_contains "${output}" "python-path=${tmp_dir}/fake-python/bin/python3" "sets python-path output"
assert_contains "${path_output}" "${tmp_dir}/fake-python/bin" "adds to GITHUB_PATH"

# ============================================================
test_suite "configure_python (with cache type)"
# ============================================================

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"
true > "${GITHUB_ENV}"

configure_python "${tmp_dir}/fake-python/bin" "3.12.1" "pip"

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "python-version=3.12.1" "sets python-version with cache"
assert_contains "${output}" "cache-dir=" "sets cache-dir output"

# ============================================================
test_suite "configure_python (missing binary)"
# ============================================================

mkdir -p "${tmp_dir}/empty-dir"

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"
true > "${GITHUB_ENV}"

assert_failure "missing binary fails" configure_python "${tmp_dir}/empty-dir" "3.12.1" ""

# ============================================================
test_suite "install_python (tool cache hit)"
# ============================================================

# Set up a cached Python installation
TOOL_CACHE="${tmp_dir}/tool-cache"
mkdir -p "${TOOL_CACHE}/Python/3.12.1/x64/bin"
cp "${tmp_dir}/fake-python/bin/python3" "${TOOL_CACHE}/Python/3.12.1/x64/bin/python3"
chmod +x "${TOOL_CACHE}/Python/3.12.1/x64/bin/python3"

RESOLVED_VERSION="3.12.1"
DOWNLOAD_URL="https://www.python.org/ftp/python/3.12.1/Python-3.12.1.tgz"
INPUT_ARCHITECTURE="x64"
INPUT_CACHE=""

true > "${GITHUB_OUTPUT}"
true > "${GITHUB_PATH}"
true > "${GITHUB_ENV}"

install_python

output="$(cat "${GITHUB_OUTPUT}")"
assert_contains "${output}" "python-version=3.12.1" "tool cache hit: version output set"
assert_contains "${output}" "python-path=" "tool cache hit: path output set"

# ============================================================
test_suite "get_python_cache_dir"
# ============================================================

result="$(get_python_cache_dir "pip" "${tmp_dir}/fake-python/bin/python3")"
assert_not_empty "${result}" "pip cache dir is not empty"

result="$(get_python_cache_dir "pipenv" "${tmp_dir}/fake-python/bin/python3")"
assert_not_empty "${result}" "pipenv cache dir is not empty"

result="$(get_python_cache_dir "poetry" "${tmp_dir}/fake-python/bin/python3")"
assert_not_empty "${result}" "poetry cache dir is not empty"

# ============================================================
test_suite "get_python_cache_key"
# ============================================================

# Create a mock requirements.txt
echo "flask==2.0.0" > "${tmp_dir}/requirements.txt"
cd "${tmp_dir}"

result="$(get_python_cache_key "pip" "python")"
assert_contains "${result}" "python-pip-" "pip cache key has correct prefix"
assert_not_contains "${result}" "no-lockfile" "pip cache key uses hash when file exists"

# No lock file
cd /tmp
result="$(get_python_cache_key "pipenv" "python")"
assert_contains "${result}" "no-lockfile" "missing lockfile produces fallback key"

# Cleanup
unset RESOLVED_VERSION DOWNLOAD_URL INPUT_ARCHITECTURE INPUT_CACHE TOOL_CACHE

# ============================================================
test_summary
