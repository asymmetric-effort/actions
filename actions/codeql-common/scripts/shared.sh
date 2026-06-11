#!/usr/bin/env bash
# shared.sh — Shared utility functions for CodeQL composite actions.
# Sourced by codeql-init, codeql-autobuild, and codeql-analyze.

set -euo pipefail

# Default CodeQL databases directory
CODEQL_DEFAULT_DB_DIR="${RUNNER_TOOL_CACHE:-${HOME}}/codeql-databases"

# Return the CodeQL databases directory
get_codeql_databases_dir() {
  local db_dir="${CODEQL_DATABASES:-${CODEQL_DEFAULT_DB_DIR}}"
  echo "${db_dir}"
}

# Return the path to the codeql binary
get_codeql_path() {
  local codeql_dir="${CODEQL_TOOL_DIR:-${RUNNER_TOOL_CACHE:-${HOME}}/codeql-tools/codeql}"
  echo "${codeql_dir}/codeql"
}

# Parse and normalize a comma-separated language list.
# Strips whitespace, lowercases, and removes empty entries.
list_codeql_languages() {
  local input="$1"
  local normalized=""

  # Replace commas with newlines, process each entry
  while IFS= read -r lang; do
    # Trim whitespace and lowercase
    lang="$(echo "${lang}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    if [[ -z "${lang}" ]]; then
      continue
    fi
    # Normalize common aliases
    case "${lang}" in
      js|javascript)
        lang="javascript"
        ;;
      ts|typescript)
        lang="javascript"
        ;;
      py|python)
        lang="python"
        ;;
      rb|ruby)
        lang="ruby"
        ;;
      cs|csharp|c-sharp)
        lang="csharp"
        ;;
      cpp|c|"c++")
        lang="cpp"
        ;;
      golang)
        lang="go"
        ;;
      kt|kotlin)
        lang="java"
        ;;
      swift)
        lang="swift"
        ;;
    esac
    if [[ -n "${normalized}" ]]; then
      normalized="${normalized},${lang}"
    else
      normalized="${lang}"
    fi
  done <<< "$(echo "${input}" | tr ',' '\n')"

  echo "${normalized}"
}
