#!/usr/bin/env bash
# deploy.sh — Deploy to GitHub Pages via the Pages deployment API.

set -euo pipefail

# Find the artifact tar.gz in the download directory.
# Globals: ARTIFACT_DIR
find_artifact() {
  local artifact_dir="${ARTIFACT_DIR:?ARTIFACT_DIR is required}"
  local artifact

  artifact="$(find "${artifact_dir}" -maxdepth 1 -name '*.tar.gz' -type f | head -n 1)"

  if [[ -z "${artifact}" ]]; then
    echo "::error::No .tar.gz artifact found in ${artifact_dir}"
    return 1
  fi

  echo "${artifact}"
}

# Request an OIDC token from the Actions runtime.
# Globals: ACTIONS_ID_TOKEN_REQUEST_URL, ACTIONS_ID_TOKEN_REQUEST_TOKEN
get_oidc_token() {
  local request_url="${ACTIONS_ID_TOKEN_REQUEST_URL:?ACTIONS_ID_TOKEN_REQUEST_URL is required}"
  local request_token="${ACTIONS_ID_TOKEN_REQUEST_TOKEN:?ACTIONS_ID_TOKEN_REQUEST_TOKEN is required}"

  local audience="api://AzureADTokenExchange"
  local url="${request_url}&audience=${audience}"

  local response
  response="$(curl -sS --fail-with-body \
    -H "Authorization: bearer ${request_token}" \
    -H "Accept: application/json; api-version=2.0" \
    "${url}")" || {
    echo "::error::Failed to request OIDC token"
    return 1
  }

  local token
  token="$(echo "${response}" | jq -r '.value // empty')"

  if [[ -z "${token}" ]]; then
    echo "::error::OIDC token response did not contain a value"
    return 1
  fi

  echo "${token}"
}

# Build the JSON payload for creating a Pages deployment.
# Arguments: $1 = artifact_url or artifact_id, $2 = oidc_token
# Globals: GITHUB_SHA
build_deployment_payload() {
  local pages_build_version="${GITHUB_SHA:?GITHUB_SHA is required}"
  local oidc_token="${1:?oidc_token is required}"

  jq -n \
    --arg version "${pages_build_version}" \
    --arg token "${oidc_token}" \
    '{
      "artifact_url": "",
      "pages_build_version": $version,
      "oidc_token": $token
    }'
}

# Parse the deployment response and extract the deployment id and page_url.
# Arguments: $1 = JSON response body
# Output: writes "id" and "page_url" as key=value lines
parse_deployment_response() {
  local response="${1:?response is required}"

  local status_url page_url id

  status_url="$(echo "${response}" | jq -r '.status_url // empty')"
  page_url="$(echo "${response}" | jq -r '.page_url // empty')"
  id="$(echo "${response}" | jq -r '.id // empty')"

  if [[ -z "${id}" ]]; then
    echo "::error::Deployment response missing 'id' field"
    return 1
  fi

  echo "id=${id}"
  echo "page_url=${page_url}"
  echo "status_url=${status_url}"
}

# Create a Pages deployment via the GitHub API.
# Globals: INPUT_TOKEN, GITHUB_API_URL, GITHUB_REPOSITORY, GITHUB_SHA,
#          ACTIONS_ID_TOKEN_REQUEST_URL, ACTIONS_ID_TOKEN_REQUEST_TOKEN
create_deployment() {
  local token="${INPUT_TOKEN:?INPUT_TOKEN is required}"
  local api_url="${GITHUB_API_URL:-https://api.github.com}"
  local repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
  local artifact="${1:?artifact path is required}"

  echo "::notice::Requesting OIDC token..."
  local oidc_token
  oidc_token="$(get_oidc_token)"

  echo "::notice::Building deployment payload..."
  local payload
  payload="$(build_deployment_payload "${oidc_token}")"

  local deploy_url="${api_url}/repos/${repo}/pages/deployments"

  echo "::notice::Creating Pages deployment via ${deploy_url}..."
  local response
  response="$(curl -sS --fail-with-body \
    -X POST \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${deploy_url}")" || {
    echo "::error::Failed to create Pages deployment"
    return 1
  }

  local artifact_upload_url
  artifact_upload_url="$(echo "${response}" | jq -r '.artifact_url // empty')"

  # Upload the artifact if an upload URL was provided
  if [[ -n "${artifact_upload_url}" ]]; then
    echo "::notice::Uploading artifact to ${artifact_upload_url}..."
    curl -sS --fail-with-body \
      -X PUT \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/gzip" \
      -H "Content-Length: $(stat -c%s "${artifact}" 2>/dev/null || stat -f%z "${artifact}")" \
      --data-binary "@${artifact}" \
      "${artifact_upload_url}" > /dev/null || {
      echo "::error::Failed to upload artifact"
      return 1
    }
  fi

  echo "${response}"
}

# Main entry point: deploy via the Pages API.
# Globals: INPUT_TOKEN, INPUT_TIMEOUT, INPUT_ERROR_COUNT, INPUT_REPORTING_INTERVAL,
#          ARTIFACT_DIR, GITHUB_REPOSITORY, GITHUB_SHA, GITHUB_API_URL,
#          ACTIONS_ID_TOKEN_REQUEST_URL, ACTIONS_ID_TOKEN_REQUEST_TOKEN
deploy_pages_api() {
  echo "::notice::Starting Pages API deployment..."

  local artifact
  artifact="$(find_artifact)"
  echo "::notice::Found artifact: ${artifact}"

  local response
  response="$(create_deployment "${artifact}")"

  local deploy_info
  deploy_info="$(parse_deployment_response "${response}")"

  local deployment_id page_url status_url
  deployment_id="$(echo "${deploy_info}" | grep '^id=' | cut -d= -f2)"
  page_url="$(echo "${deploy_info}" | grep '^page_url=' | cut -d= -f2)"
  status_url="$(echo "${deploy_info}" | grep '^status_url=' | cut -d= -f2)"

  echo "::notice::Deployment created: id=${deployment_id}, page_url=${page_url}"

  local timeout="${INPUT_TIMEOUT:-600000}"
  local error_count="${INPUT_ERROR_COUNT:-10}"
  local reporting_interval="${INPUT_REPORTING_INTERVAL:-5000}"

  poll_deployment_status \
    "${deployment_id}" \
    "${timeout}" \
    "${error_count}" \
    "${reporting_interval}" \
    "${status_url}"

  echo "page_url=${page_url}" >> "${GITHUB_OUTPUT}"
  echo "::notice::Deployment complete: ${page_url}"
}
