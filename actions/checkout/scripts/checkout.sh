#!/usr/bin/env bash
# checkout.sh — Clone and checkout a repository.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Build the authenticated clone URL
build_clone_url() {
  local token="$1"
  local repository="$2"
  echo "https://x-access-token:${token}@github.com/${repository}.git"
}

# Build the git clone arguments based on fetch-depth and submodules
get_clone_args() {
  local fetch_depth="$1"
  local submodules="$2"
  local args=""

  if [[ "${fetch_depth}" != "0" ]]; then
    args="--depth=${fetch_depth}"
  fi

  if [[ "${submodules}" == "true" || "${submodules}" == "recursive" ]]; then
    args="${args:+${args} }--recurse-submodules"
  fi

  echo "${args}"
}

# Determine the ref to checkout
get_checkout_ref() {
  local input_ref="$1"
  local github_sha="${GITHUB_SHA:-}"
  local github_ref="${GITHUB_REF:-}"

  if [[ -n "${input_ref}" ]]; then
    echo "${input_ref}"
  elif [[ -n "${github_sha}" ]]; then
    echo "${github_sha}"
  elif [[ -n "${github_ref}" ]]; then
    echo "${github_ref}"
  else
    echo ""
  fi
}

# Clean the workspace directory, preserving .git
clean_workspace() {
  local target_path="$1"

  if [[ ! -d "${target_path}" ]]; then
    return 0
  fi

  # Remove everything except .git
  find "${target_path}" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
  echo "::notice::Cleaned workspace at ${target_path}"
}

# Remove stored credentials from git config
remove_credentials() {
  local target_path="$1"
  local repository="$2"

  git -C "${target_path}" config --unset-all "http.https://github.com/${repository}.extraheader" 2>/dev/null || true
  git -C "${target_path}" config --unset-all "http.https://github.com/${repository}.git.extraheader" 2>/dev/null || true
  # Remove the token-bearing remote URL and replace with plain HTTPS
  git -C "${target_path}" remote set-url origin "https://github.com/${repository}.git" 2>/dev/null || true
  echo "::notice::Credentials removed from git config"
}

# Main entry point: clone and checkout the repository
checkout_repository() {
  local repository="${INPUT_REPOSITORY:-}"
  local ref="${INPUT_REF:-}"
  local token="${INPUT_TOKEN:-}"
  local target_path="${INPUT_PATH:-.}"
  local fetch_depth="${INPUT_FETCH_DEPTH:-1}"
  local submodules="${INPUT_SUBMODULES:-false}"
  local lfs="${INPUT_LFS:-false}"
  local clean="${INPUT_CLEAN:-true}"
  local persist_credentials="${INPUT_PERSIST_CREDENTIALS:-true}"

  # Resolve target path relative to GITHUB_WORKSPACE
  if [[ "${target_path}" != /* ]]; then
    target_path="${GITHUB_WORKSPACE:-.}/${target_path}"
  fi

  # Clean workspace if requested
  if [[ "${clean}" == "true" ]]; then
    clean_workspace "${target_path}"
  fi

  # Build clone URL and args
  local clone_url
  clone_url="$(build_clone_url "${token}" "${repository}")"

  local clone_args
  clone_args="$(get_clone_args "${fetch_depth}" "${submodules}")"

  # Determine the ref to checkout
  local checkout_ref
  checkout_ref="$(get_checkout_ref "${ref}")"

  # Clone the repository
  echo "::notice::Cloning ${repository} into ${target_path}"
  # shellcheck disable=SC2086
  git clone ${clone_args} -- "${clone_url}" "${target_path}"

  # Mark directory as safe
  git config --global --add safe.directory "${target_path}"

  # Checkout specific ref if needed (and it differs from HEAD)
  if [[ -n "${checkout_ref}" ]]; then
    echo "::notice::Checking out ref: ${checkout_ref}"
    git -C "${target_path}" fetch --depth="${fetch_depth}" origin "${checkout_ref}" 2>/dev/null || true
    git -C "${target_path}" checkout "${checkout_ref}" 2>/dev/null || \
      git -C "${target_path}" checkout -B "__checkout_ref" "FETCH_HEAD" 2>/dev/null || true
  fi

  # Handle LFS
  if [[ "${lfs}" == "true" ]]; then
    echo "::notice::Fetching Git LFS objects"
    git -C "${target_path}" lfs install --local
    git -C "${target_path}" lfs pull
  fi

  # Remove credentials if not persisting
  if [[ "${persist_credentials}" != "true" ]]; then
    remove_credentials "${target_path}" "${repository}"
  fi

  # Set outputs
  local checked_out_ref
  checked_out_ref="$(git -C "${target_path}" symbolic-ref --short HEAD 2>/dev/null || git -C "${target_path}" rev-parse HEAD)"
  local commit_sha
  commit_sha="$(git -C "${target_path}" rev-parse HEAD)"

  echo "ref=${checked_out_ref}" >> "${GITHUB_OUTPUT}"
  echo "commit=${commit_sha}" >> "${GITHUB_OUTPUT}"

  echo "::notice::Checked out ${repository} at ${commit_sha}"
}
