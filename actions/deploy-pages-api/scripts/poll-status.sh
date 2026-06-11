#!/usr/bin/env bash
# poll-status.sh — Poll GitHub Pages deployment status until complete or timeout.

set -euo pipefail

# Convert milliseconds to seconds (integer).
# Arguments: $1 = milliseconds
ms_to_seconds() {
  local ms="${1:?ms is required}"
  echo $(( ms / 1000 ))
}

# Check if the deployment has reached a terminal state.
# Arguments: $1 = status string
# Returns: 0 if terminal, 1 if still in progress
is_terminal_status() {
  local status="${1:?status is required}"

  case "${status}" in
    succeed|deployment_failed|deployment_content_failed|cancelled)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Determine if a terminal status is a success.
# Arguments: $1 = status string
is_success_status() {
  local status="${1:?status is required}"
  [[ "${status}" == "succeed" ]]
}

# Fetch the current deployment status from the GitHub API.
# Arguments: $1 = status_url
# Globals: INPUT_TOKEN
fetch_deployment_status() {
  local status_url="${1:?status_url is required}"
  local token="${INPUT_TOKEN:?INPUT_TOKEN is required}"

  local response
  response="$(curl -sS --fail-with-body \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    "${status_url}")" || {
    echo "::warning::Failed to fetch deployment status"
    return 1
  }

  echo "${response}"
}

# Parse the status field from a deployment status response.
# Arguments: $1 = JSON response body
parse_status() {
  local response="${1:?response is required}"
  echo "${response}" | jq -r '.status // "unknown"'
}

# Poll deployment status until terminal state or timeout.
# Arguments: $1 = deployment_id, $2 = timeout_ms, $3 = max_errors,
#            $4 = interval_ms, $5 = status_url
# Globals: INPUT_TOKEN, GITHUB_API_URL, GITHUB_REPOSITORY
poll_deployment_status() {
  local deployment_id="${1:?deployment_id is required}"
  local timeout_ms="${2:-600000}"
  local max_errors="${3:-10}"
  local interval_ms="${4:-5000}"
  local status_url="${5:-}"

  local api_url="${GITHUB_API_URL:-https://api.github.com}"
  local repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

  if [[ -z "${status_url}" ]]; then
    status_url="${api_url}/repos/${repo}/pages/deployments/${deployment_id}"
  fi

  local interval_sec
  interval_sec="$(ms_to_seconds "${interval_ms}")"
  if [[ "${interval_sec}" -lt 1 ]]; then
    interval_sec=1
  fi

  local timeout_sec
  timeout_sec="$(ms_to_seconds "${timeout_ms}")"

  local start_time
  start_time="$(date +%s)"
  local consecutive_errors=0

  echo "::notice::Polling deployment ${deployment_id} (timeout=${timeout_sec}s, interval=${interval_sec}s)..."

  while true; do
    local elapsed
    elapsed=$(( $(date +%s) - start_time ))

    if [[ ${elapsed} -ge ${timeout_sec} ]]; then
      echo "::error::Deployment timed out after ${timeout_sec}s"
      return 1
    fi

    local response
    if response="$(fetch_deployment_status "${status_url}")"; then
      consecutive_errors=0

      local status
      status="$(parse_status "${response}")"

      echo "::notice::Deployment status: ${status} (${elapsed}s elapsed)"

      if is_terminal_status "${status}"; then
        if is_success_status "${status}"; then
          echo "::notice::Deployment succeeded"
          return 0
        else
          echo "::error::Deployment failed with status: ${status}"
          return 1
        fi
      fi
    else
      consecutive_errors=$(( consecutive_errors + 1 ))
      echo "::warning::Poll error (${consecutive_errors}/${max_errors})"

      if [[ ${consecutive_errors} -ge ${max_errors} ]]; then
        echo "::error::Too many consecutive polling errors (${max_errors})"
        return 1
      fi
    fi

    sleep "${interval_sec}"
  done
}
