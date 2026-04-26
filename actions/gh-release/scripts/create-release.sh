#!/usr/bin/env bash
# create-release.sh — Create or update a GitHub release.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Resolve the release body text from inputs
resolve_body() {
  local body="${INPUT_BODY:-}"
  local body_path="${INPUT_BODY_PATH:-}"
  local working_dir="${INPUT_WORKING_DIRECTORY:-.}"

  if [[ -n "${body_path}" ]]; then
    local resolved_path
    if [[ "${body_path}" == /* ]]; then
      resolved_path="${body_path}"
    else
      resolved_path="${working_dir}/${body_path}"
    fi

    if [[ ! -f "${resolved_path}" ]]; then
      echo "::error::body_path file not found: ${resolved_path}" >&2
      return 1
    fi
    cat "${resolved_path}"
    return 0
  fi

  echo "${body}"
}

# Check if a release already exists for the given tag
find_existing_release() {
  local repo="$1"
  local tag="$2"

  local response
  if response="$(gh api "repos/${repo}/releases/tags/${tag}" 2>/dev/null)"; then
    echo "${response}"
    return 0
  fi
  return 1
}

# Parse a JSON field from a response (lightweight, no jq dependency)
parse_json_field() {
  local json="$1"
  local field="$2"

  # Handle numeric fields (id)
  if [[ "${field}" == "id" ]]; then
    echo "${json}" | grep -oP '"id"\s*:\s*\K[0-9]+' | head -1
  else
    echo "${json}" | grep -oP "\"${field}\"\s*:\s*\"\K[^\"]*" | head -1
  fi
}

# Create a new release via the GitHub API
create_release() {
  local repo="$1"
  local tag="$2"
  local name="$3"
  local body="$4"

  local args=()
  args+=(--repo "${repo}")
  args+=(--title "${name}")
  args+=(--target "${INPUT_TARGET_COMMITISH:-$(git rev-parse HEAD 2>/dev/null || echo "")}")

  if [[ "${INPUT_DRAFT:-false}" == "true" ]]; then
    args+=(--draft)
  fi

  if [[ "${INPUT_PRERELEASE:-false}" == "true" ]]; then
    args+=(--prerelease)
  fi

  if [[ "${INPUT_GENERATE_RELEASE_NOTES:-false}" == "true" ]]; then
    args+=(--generate-notes)
  fi

  if [[ -n "${INPUT_MAKE_LATEST:-}" ]]; then
    args+=(--latest="${INPUT_MAKE_LATEST}")
  fi

  if [[ -n "${body}" ]]; then
    args+=(--notes "${body}")
  else
    args+=(--notes "")
  fi

  gh release create "${tag}" "${args[@]}" 2>&1
}

# Update an existing release via the GitHub API
update_release() {
  local repo="$1"
  local tag="$2"
  local name="$3"
  local body="$4"

  local args=()
  args+=(--repo "${repo}")
  args+=(--title "${name}")

  if [[ "${INPUT_DRAFT:-false}" == "true" ]]; then
    args+=(--draft)
  else
    args+=(--draft=false)
  fi

  if [[ "${INPUT_PRERELEASE:-false}" == "true" ]]; then
    args+=(--prerelease)
  else
    args+=(--prerelease=false)
  fi

  if [[ -n "${INPUT_MAKE_LATEST:-}" ]]; then
    args+=(--latest="${INPUT_MAKE_LATEST}")
  fi

  if [[ -n "${body}" ]]; then
    args+=(--notes "${body}")
  fi

  gh release edit "${tag}" "${args[@]}" 2>&1
}

# Main entry point
create_or_update_release() {
  local repo="${INPUT_REPOSITORY:?INPUT_REPOSITORY is required}"
  local tag="${INPUT_TAG_NAME:?INPUT_TAG_NAME is required}"
  local name="${INPUT_NAME:-${tag}}"

  local body
  body="$(resolve_body)"

  if find_existing_release "${repo}" "${tag}" >/dev/null; then
    echo "::notice::Updating existing release for tag ${tag}"
    update_release "${repo}" "${tag}" "${name}" "${body}"
  else
    echo "::notice::Creating new release for tag ${tag}"
    create_release "${repo}" "${tag}" "${name}" "${body}"
  fi

  # Fetch the release data to set outputs
  local release_data
  release_data="$(gh api "repos/${repo}/releases/tags/${tag}" 2>/dev/null)"

  local release_id release_url upload_url
  release_id="$(parse_json_field "${release_data}" "id")"
  release_url="$(parse_json_field "${release_data}" "html_url")"
  upload_url="$(parse_json_field "${release_data}" "upload_url")"

  {
    echo "id=${release_id}"
    echo "url=${release_url}"
    echo "upload_url=${upload_url}"
  } >> "${GITHUB_OUTPUT}"

  echo "::notice::Release URL: ${release_url}"
}
