#!/usr/bin/env bash
# autobuild.sh — Auto-detect and build the project for CodeQL analysis.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Detect the build system for a given language.
# Returns a build system identifier string.
detect_build_system() {
  local lang="$1"
  local source_root="${2:-.}"

  case "${lang}" in
    go)
      if [[ -f "${source_root}/go.mod" ]]; then
        echo "go-mod"
      elif [[ -f "${source_root}/Makefile" ]]; then
        echo "make"
      else
        echo "go-default"
      fi
      ;;
    javascript)
      if [[ -f "${source_root}/yarn.lock" ]]; then
        echo "yarn"
      elif [[ -f "${source_root}/package-lock.json" ]] || [[ -f "${source_root}/package.json" ]]; then
        echo "npm"
      else
        echo "none"
      fi
      ;;
    python)
      echo "none"
      ;;
    java)
      if [[ -f "${source_root}/pom.xml" ]]; then
        echo "maven"
      elif [[ -f "${source_root}/build.gradle" ]] || [[ -f "${source_root}/build.gradle.kts" ]]; then
        echo "gradle"
      else
        echo "none"
      fi
      ;;
    cpp)
      if [[ -f "${source_root}/CMakeLists.txt" ]]; then
        echo "cmake"
      elif [[ -f "${source_root}/Makefile" ]]; then
        echo "make"
      else
        echo "none"
      fi
      ;;
    csharp)
      if compgen -G "${source_root}/*.sln" > /dev/null 2>&1; then
        echo "dotnet"
      elif compgen -G "${source_root}/*.csproj" > /dev/null 2>&1; then
        echo "dotnet"
      else
        echo "none"
      fi
      ;;
    ruby)
      echo "none"
      ;;
    swift)
      if [[ -f "${source_root}/Package.swift" ]]; then
        echo "swift-package"
      else
        echo "xcodebuild"
      fi
      ;;
    *)
      echo "none"
      ;;
  esac
}

# Build the build command for a given language and build system.
build_command_for() {
  local lang="$1"
  local build_system="$2"

  case "${build_system}" in
    go-mod)
      echo "go build ./..."
      ;;
    go-default)
      echo "go build ./..."
      ;;
    npm)
      echo "npm install && npm run build --if-present"
      ;;
    yarn)
      echo "yarn install && yarn build"
      ;;
    maven)
      echo "mvn package -B -DskipTests"
      ;;
    gradle)
      echo "gradle build -x test"
      ;;
    cmake)
      echo "mkdir -p build && cd build && cmake .. && make"
      ;;
    make)
      echo "make"
      ;;
    dotnet)
      echo "dotnet build"
      ;;
    swift-package)
      echo "swift build"
      ;;
    xcodebuild)
      echo "xcodebuild build"
      ;;
    none)
      echo ""
      ;;
    *)
      echo ""
      ;;
  esac
}

# Run the autobuild for a single language, tracing the build with CodeQL.
run_autobuild_for_language() {
  local lang="$1"
  local build_cmd="$2"
  local codeql_bin="$3"
  local db_dir="$4"

  local db_path="${db_dir}/${lang}"

  if [[ ! -d "${db_path}" ]]; then
    echo "::warning::No CodeQL database found for language '${lang}' at ${db_path}"
    return 0
  fi

  if [[ -n "${build_cmd}" ]]; then
    echo "::notice::Running build command for ${lang}: ${build_cmd}"
    "${codeql_bin}" database trace-command "${db_path}" -- bash -c "${build_cmd}"
  else
    echo "::notice::No build needed for ${lang} (interpreted language)"
  fi
}

# Main entry point: detect and run the build for CodeQL tracing.
autobuild_codeql() {
  local language="${INPUT_LANGUAGE:-}"
  local build_command="${INPUT_BUILD_COMMAND:-}"

  local codeql_bin
  codeql_bin="$(get_codeql_path)"

  local db_dir
  db_dir="$(get_codeql_databases_dir)"

  # If a custom build command is provided, use it directly
  if [[ -n "${build_command}" ]]; then
    echo "::notice::Using custom build command: ${build_command}"
    if [[ -n "${language}" ]]; then
      run_autobuild_for_language "${language}" "${build_command}" "${codeql_bin}" "${db_dir}"
    else
      # Apply the custom command to all databases
      for db_path in "${db_dir}"/*/; do
        local lang
        lang="$(basename "${db_path}")"
        run_autobuild_for_language "${lang}" "${build_command}" "${codeql_bin}" "${db_dir}"
      done
    fi
    return 0
  fi

  # Auto-detect and build for specified language or all languages
  if [[ -n "${language}" ]]; then
    local normalized
    normalized="$(list_codeql_languages "${language}")"
    local build_system
    build_system="$(detect_build_system "${normalized}")"
    local cmd
    cmd="$(build_command_for "${normalized}" "${build_system}")"
    echo "::notice::Detected build system '${build_system}' for ${normalized}"
    run_autobuild_for_language "${normalized}" "${cmd}" "${codeql_bin}" "${db_dir}"
  else
    # Build all initialized languages
    for db_path in "${db_dir}"/*/; do
      if [[ ! -d "${db_path}" ]]; then
        continue
      fi
      local lang
      lang="$(basename "${db_path}")"
      local build_system
      build_system="$(detect_build_system "${lang}")"
      local cmd
      cmd="$(build_command_for "${lang}" "${build_system}")"
      echo "::notice::Detected build system '${build_system}' for ${lang}"
      run_autobuild_for_language "${lang}" "${cmd}" "${codeql_bin}" "${db_dir}"
    done
  fi

  echo "::notice::Autobuild complete"
}
