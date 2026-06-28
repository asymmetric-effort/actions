#!/usr/bin/env bash
# download.sh — Download and extract artifacts from a workflow run.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Build the API URL for listing artifacts in a run
build_artifact_api_url() {
  local owner_repo="$1"
  local run_id="$2"
  echo "https://api.github.com/repos/${owner_repo}/actions/runs/${run_id}/artifacts"
}

# Parse the artifact list JSON and extract the artifact ID for a given name.
# Outputs the artifact ID or returns 1 if not found.
parse_artifact_id() {
  local json="$1"
  local name="$2"
  local artifact_id
  artifact_id="$(echo "${json}" | jq -r --arg name "${name}" \
    '.artifacts[] | select(.name == $name) | .id' | head -n 1)"

  if [[ -z "${artifact_id}" || "${artifact_id}" == "null" ]]; then
    echo "::error::Artifact '${name}' not found in workflow run" >&2
    return 1
  fi
  echo "${artifact_id}"
}

# Parse the artifact list JSON and return all artifact IDs matching a name pattern.
# When merge-multiple is true, all artifacts whose names match are returned.
parse_matching_artifact_ids() {
  local json="$1"
  local name="$2"
  local ids
  ids="$(echo "${json}" | jq -r --arg name "${name}" \
    '.artifacts[] | select(.name | test($name)) | .id')"

  if [[ -z "${ids}" ]]; then
    echo "::error::No artifacts matching '${name}' found in workflow run" >&2
    return 1
  fi
  echo "${ids}"
}

# Download and extract a single artifact by ID
extract_artifact() {
  local owner_repo="$1"
  local artifact_id="$2"
  local token="$3"
  local target_path="$4"

  local download_url="https://api.github.com/repos/${owner_repo}/actions/artifacts/${artifact_id}/zip"
  local tmp_zip
  tmp_zip="$(mktemp /tmp/artifact-XXXXXX.zip)"

  local http_code
  http_code="$(curl -sL -o "${tmp_zip}" -w "%{http_code}" \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${download_url}")"

  if [[ "${http_code}" -lt 200 || "${http_code}" -ge 300 ]]; then
    rm -f "${tmp_zip}"
    echo "::error::Failed to download artifact (HTTP ${http_code})" >&2
    return 1
  fi

  mkdir -p "${target_path}"
  unzip -o -q "${tmp_zip}" -d "${target_path}"
  rm -f "${tmp_zip}"

  echo "::notice::Extracted artifact ${artifact_id} to ${target_path}"
}

# Main entry point: download artifact(s)
download_artifact() {
  local name="${INPUT_NAME:-}"
  local path="${INPUT_PATH:-.}"
  local merge_multiple="${INPUT_MERGE_MULTIPLE:-false}"
  local run_id="${INPUT_RUN_ID:-${GITHUB_RUN_ID:-}}"
  local token="${INPUT_GITHUB_TOKEN:-}"
  local owner_repo="${GITHUB_REPOSITORY:-}"

  # Resolve target path relative to GITHUB_WORKSPACE
  local target_path="${path}"
  if [[ "${target_path}" != /* ]]; then
    target_path="${GITHUB_WORKSPACE:-.}/${target_path}"
  fi

  if [[ -z "${run_id}" ]]; then
    echo "::error::No run ID available. Set 'run-id' input or ensure GITHUB_RUN_ID is set." >&2
    return 1
  fi

  if [[ -z "${owner_repo}" ]]; then
    echo "::error::GITHUB_REPOSITORY is not set" >&2
    return 1
  fi

  # Fetch artifact list
  local api_url
  api_url="$(build_artifact_api_url "${owner_repo}" "${run_id}")"

  local response
  response="$(curl -sL \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${api_url}")"

  if [[ "$(echo "${response}" | jq -r '.message // empty')" != "" ]]; then
    local msg
    msg="$(echo "${response}" | jq -r '.message')"
    echo "::error::GitHub API error: ${msg}" >&2
    return 1
  fi

  if [[ "${merge_multiple}" == "true" ]]; then
    # Download all artifacts matching the name pattern
    local artifact_ids
    artifact_ids="$(parse_matching_artifact_ids "${response}" "${name}")" || return 1

    while IFS= read -r artifact_id; do
      extract_artifact "${owner_repo}" "${artifact_id}" "${token}" "${target_path}" || return 1
    done <<< "${artifact_ids}"
  else
    # Download a single artifact by exact name
    local artifact_id
    artifact_id="$(parse_artifact_id "${response}" "${name}")" || return 1
    extract_artifact "${owner_repo}" "${artifact_id}" "${token}" "${target_path}" || return 1
  fi

  # Resolve to absolute path for output
  local abs_path
  abs_path="$(cd "${target_path}" && pwd)"

  echo "download-path=${abs_path}" >> "${GITHUB_OUTPUT}"
  echo "::notice::Artifact download complete: ${abs_path}"
}
