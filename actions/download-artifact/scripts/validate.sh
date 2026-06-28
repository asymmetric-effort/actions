#!/usr/bin/env bash
# validate.sh — Validate inputs for the download-artifact action.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Check that the artifact name is not empty
validate_artifact_name() {
  local name="${1:-}"
  if [[ -z "${name}" ]]; then
    echo "::error::Input 'name' must not be empty" >&2
    return 1
  fi
}

# Validate and prepare the download path (create if needed)
validate_download_path() {
  local path="${1:-}"
  if [[ -z "${path}" ]]; then
    echo "::error::Input 'path' must not be empty" >&2
    return 1
  fi

  # Resolve relative paths against GITHUB_WORKSPACE
  local resolved_path="${path}"
  if [[ "${resolved_path}" != /* ]]; then
    resolved_path="${GITHUB_WORKSPACE:-.}/${resolved_path}"
  fi

  if [[ -e "${resolved_path}" && ! -d "${resolved_path}" ]]; then
    echo "::error::Input 'path' exists but is not a directory: ${resolved_path}" >&2
    return 1
  fi

  if [[ ! -d "${resolved_path}" ]]; then
    mkdir -p "${resolved_path}"
    echo "::notice::Created download directory: ${resolved_path}"
  fi
}

# Validate merge-multiple is a boolean string
validate_merge_multiple() {
  local value="${1:-}"
  case "${value}" in
    true|false) ;;
    *)
      echo "::error::Input 'merge-multiple' must be 'true' or 'false', got '${value}'" >&2
      return 1
      ;;
  esac
}

# Main validation entry point
validate_download_inputs() {
  local name="${INPUT_NAME:-}"
  local path="${INPUT_PATH:-.}"
  local merge_multiple="${INPUT_MERGE_MULTIPLE:-false}"

  validate_artifact_name "${name}" || return 1
  validate_download_path "${path}" || return 1
  validate_merge_multiple "${merge_multiple}" || return 1

  echo "::notice::Download artifact inputs validated successfully"
}
