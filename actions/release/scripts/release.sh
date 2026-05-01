#!/usr/bin/env bash
# release.sh — Create or update a GitHub release.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Resolve the release body from inputs
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

# Check if a release exists for a tag
release_exists() {
  local repo="$1"
  local tag="$2"
  gh api "repos/${repo}/releases/tags/${tag}" >/dev/null 2>&1
}

# Get the existing release body
get_existing_body() {
  local repo="$1"
  local tag="$2"
  gh api "repos/${repo}/releases/tags/${tag}" --jq '.body // ""' 2>/dev/null || echo ""
}

# Parse a field from release JSON
parse_release_field() {
  local json="$1"
  local field="$2"

  if [[ "${field}" == "id" ]]; then
    echo "${json}" | grep -oP '"id"\s*:\s*\K[0-9]+' | head -1
  else
    echo "${json}" | grep -oP "\"${field}\"\s*:\s*\"\K[^\"]*" | head -1
  fi
}

# Create a new release
create_release() {
  local repo="$1"
  local tag="$2"
  local name="$3"
  local body="$4"

  local args=()
  args+=(--repo "${repo}")
  args+=(--title "${name}")

  if [[ -n "${INPUT_TARGET_COMMITISH:-}" ]]; then
    args+=(--target "${INPUT_TARGET_COMMITISH}")
  fi

  if [[ "${INPUT_DRAFT:-false}" == "true" ]]; then
    args+=(--draft)
  fi

  if [[ "${INPUT_PRERELEASE:-false}" == "true" ]]; then
    args+=(--prerelease)
  fi

  if [[ "${INPUT_GENERATE_RELEASE_NOTES:-false}" == "true" ]]; then
    args+=(--generate-notes)
  fi

  if [[ -n "${INPUT_PREVIOUS_TAG:-}" ]]; then
    args+=(--notes-start-tag "${INPUT_PREVIOUS_TAG}")
  fi

  if [[ -n "${INPUT_MAKE_LATEST:-}" ]]; then
    args+=(--latest="${INPUT_MAKE_LATEST}")
  fi

  if [[ -n "${INPUT_DISCUSSION_CATEGORY_NAME:-}" ]]; then
    args+=(--discussion-category "${INPUT_DISCUSSION_CATEGORY_NAME}")
  fi

  if [[ -n "${body}" ]]; then
    args+=(--notes "${body}")
  else
    args+=(--notes "")
  fi

  gh release create "${tag}" "${args[@]}" 2>&1
}

# Update an existing release
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

  if [[ -n "${INPUT_DISCUSSION_CATEGORY_NAME:-}" ]]; then
    args+=(--discussion-category "${INPUT_DISCUSSION_CATEGORY_NAME}")
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

  if release_exists "${repo}" "${tag}"; then
    echo "::notice::Updating existing release for tag ${tag}"

    # Handle append_body
    if [[ "${INPUT_APPEND_BODY:-false}" == "true" && -n "${body}" ]]; then
      local existing_body
      existing_body="$(get_existing_body "${repo}" "${tag}")"
      if [[ -n "${existing_body}" ]]; then
        body="${existing_body}

${body}"
      fi
    fi

    update_release "${repo}" "${tag}" "${name}" "${body}"
  else
    echo "::notice::Creating new release for tag ${tag}"
    create_release "${repo}" "${tag}" "${name}" "${body}"
  fi

  # Fetch release data for outputs
  local release_data
  release_data="$(gh api "repos/${repo}/releases/tags/${tag}" 2>/dev/null)"

  local release_id release_url upload_url
  release_id="$(parse_release_field "${release_data}" "id")"
  release_url="$(parse_release_field "${release_data}" "html_url")"
  upload_url="$(parse_release_field "${release_data}" "upload_url")"

  {
    echo "id=${release_id}"
    echo "url=${release_url}"
    echo "upload_url=${upload_url}"
    echo "tag=${tag}"
  } >> "${GITHUB_OUTPUT}"

  echo "::notice::Release URL: ${release_url}"
}
