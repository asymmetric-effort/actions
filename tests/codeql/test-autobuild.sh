#!/usr/bin/env bash
# Tests for actions/codeql-autobuild/scripts/autobuild.sh

# shellcheck disable=SC1091,SC2034
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test-harness.sh"

# Source the scripts under test
ACTION_DIR="$(cd "${SCRIPT_DIR}/../../actions/codeql-autobuild" && pwd)"
COMMON_DIR="$(cd "${SCRIPT_DIR}/../../actions/codeql-common" && pwd)"
source "${COMMON_DIR}/scripts/shared.sh"
source "${ACTION_DIR}/scripts/autobuild.sh"

# ============================================================
# Setup
# ============================================================
GITHUB_OUTPUT="$(mktemp)"
GITHUB_ENV="$(mktemp)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}" "${GITHUB_OUTPUT}" "${GITHUB_ENV}"' EXIT

# ============================================================
test_suite "detect_build_system"
# ============================================================

# Go with go.mod
touch "${tmp_dir}/go.mod"
result="$(detect_build_system "go" "${tmp_dir}")"
assert_eq "go-mod" "${result}" "detects go.mod"
rm -f "${tmp_dir}/go.mod"

# Go with Makefile
touch "${tmp_dir}/Makefile"
result="$(detect_build_system "go" "${tmp_dir}")"
assert_eq "make" "${result}" "detects Go with Makefile"
rm -f "${tmp_dir}/Makefile"

# Go without any build file
result="$(detect_build_system "go" "${tmp_dir}")"
assert_eq "go-default" "${result}" "Go default when no build file"

# JavaScript with package.json
touch "${tmp_dir}/package.json"
result="$(detect_build_system "javascript" "${tmp_dir}")"
assert_eq "npm" "${result}" "detects npm via package.json"

# JavaScript with yarn.lock
touch "${tmp_dir}/yarn.lock"
result="$(detect_build_system "javascript" "${tmp_dir}")"
assert_eq "yarn" "${result}" "detects yarn via yarn.lock"
rm -f "${tmp_dir}/package.json" "${tmp_dir}/yarn.lock"

# Python is always none
result="$(detect_build_system "python" "${tmp_dir}")"
assert_eq "none" "${result}" "Python needs no build"

# Java with pom.xml
touch "${tmp_dir}/pom.xml"
result="$(detect_build_system "java" "${tmp_dir}")"
assert_eq "maven" "${result}" "detects Maven via pom.xml"
rm -f "${tmp_dir}/pom.xml"

# Java with build.gradle
touch "${tmp_dir}/build.gradle"
result="$(detect_build_system "java" "${tmp_dir}")"
assert_eq "gradle" "${result}" "detects Gradle via build.gradle"
rm -f "${tmp_dir}/build.gradle"

# Java with build.gradle.kts
touch "${tmp_dir}/build.gradle.kts"
result="$(detect_build_system "java" "${tmp_dir}")"
assert_eq "gradle" "${result}" "detects Gradle via build.gradle.kts"
rm -f "${tmp_dir}/build.gradle.kts"

# C++ with CMakeLists.txt
touch "${tmp_dir}/CMakeLists.txt"
result="$(detect_build_system "cpp" "${tmp_dir}")"
assert_eq "cmake" "${result}" "detects CMake"
rm -f "${tmp_dir}/CMakeLists.txt"

# C++ with Makefile
touch "${tmp_dir}/Makefile"
result="$(detect_build_system "cpp" "${tmp_dir}")"
assert_eq "make" "${result}" "detects Make for C++"
rm -f "${tmp_dir}/Makefile"

# Ruby is always none
result="$(detect_build_system "ruby" "${tmp_dir}")"
assert_eq "none" "${result}" "Ruby needs no build"

# Unknown language
result="$(detect_build_system "unknown" "${tmp_dir}")"
assert_eq "none" "${result}" "unknown language returns none"

# ============================================================
test_suite "build_command_for"
# ============================================================

result="$(build_command_for "go" "go-mod")"
assert_eq "go build ./..." "${result}" "Go mod build command"

result="$(build_command_for "go" "go-default")"
assert_eq "go build ./..." "${result}" "Go default build command"

result="$(build_command_for "javascript" "npm")"
assert_eq "npm install && npm run build --if-present" "${result}" "npm build command"

result="$(build_command_for "javascript" "yarn")"
assert_eq "yarn install && yarn build" "${result}" "yarn build command"

result="$(build_command_for "java" "maven")"
assert_eq "mvn package -B -DskipTests" "${result}" "Maven build command"

result="$(build_command_for "java" "gradle")"
assert_eq "gradle build -x test" "${result}" "Gradle build command"

result="$(build_command_for "cpp" "cmake")"
assert_contains "${result}" "cmake" "CMake build command contains cmake"

result="$(build_command_for "cpp" "make")"
assert_eq "make" "${result}" "Make build command"

result="$(build_command_for "python" "none")"
assert_eq "" "${result}" "no build command for interpreted languages"

result="$(build_command_for "csharp" "dotnet")"
assert_eq "dotnet build" "${result}" "dotnet build command"

# ============================================================
test_summary
