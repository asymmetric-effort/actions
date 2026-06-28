#!/usr/bin/env bash
# configure.sh — Configure GitHub Pages and output site URL metadata.

set -euo pipefail

# Build the JSON payload for enabling Pages.
enable_pages_payload() {
  cat <<'PAYLOAD'
{"build_type":"workflow","source":{"branch":"main","path":"/"}}
PAYLOAD
}

# Query the Pages API for the current repository.
query_pages_api() {
  local token="${INPUT_TOKEN}"
  local api_url="${GITHUB_API_URL:-https://api.github.com}"
  local repo="${GITHUB_REPOSITORY}"

  curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    "${api_url}/repos/${repo}/pages"
}

# Enable Pages via the API.
enable_pages() {
  local token="${INPUT_TOKEN}"
  local api_url="${GITHUB_API_URL:-https://api.github.com}"
  local repo="${GITHUB_REPOSITORY}"
  local payload
  payload="$(enable_pages_payload)"

  curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${api_url}/repos/${repo}/pages"
}

# Main function: configure Pages and set outputs.
configure_pages() {
  local response status_code body html_url

  echo "::notice::Configuring GitHub Pages..."

  # Query current Pages status
  response="$(query_pages_api)"
  status_code="$(echo "${response}" | tail -n1)"
  body="$(echo "${response}" | sed '$d')"

  if [[ "${status_code}" == "404" ]]; then
    # Pages not enabled
    if [[ "${INPUT_ENABLEMENT}" == "true" ]]; then
      echo "::notice::Pages not enabled. Enabling via API..."
      response="$(enable_pages)"
      status_code="$(echo "${response}" | tail -n1)"
      body="$(echo "${response}" | sed '$d')"

      if [[ "${status_code}" != "201" && "${status_code}" != "200" ]]; then
        echo "::error::Failed to enable Pages (HTTP ${status_code}): ${body}"
        return 1
      fi

      echo "::notice::Pages enabled successfully. Querying for site URL..."

      # Re-query to get the full URL
      response="$(query_pages_api)"
      status_code="$(echo "${response}" | tail -n1)"
      body="$(echo "${response}" | sed '$d')"

      if [[ "${status_code}" != "200" ]]; then
        echo "::error::Failed to query Pages after enablement (HTTP ${status_code}): ${body}"
        return 1
      fi
    else
      echo "::error::Pages is not enabled and enablement is set to false. Enable Pages in repository settings or set enablement to true."
      return 1
    fi
  elif [[ "${status_code}" != "200" ]]; then
    echo "::error::Failed to query Pages API (HTTP ${status_code}): ${body}"
    return 1
  fi

  # Extract html_url from the response
  html_url="$(echo "${body}" | grep -o '"html_url":"[^"]*"' | head -1 | sed 's/"html_url":"//;s/"//')"

  if [[ -z "${html_url}" ]]; then
    echo "::error::Could not extract html_url from Pages API response"
    return 1
  fi

  echo "::notice::Pages site URL: ${html_url}"

  # Parse the URL into components
  parse_pages_url "${html_url}"

  # Create .nojekyll if a static site generator is specified
  if [[ -n "${INPUT_STATIC_SITE_GENERATOR:-}" ]]; then
    local workspace="${GITHUB_WORKSPACE:-.}"
    touch "${workspace}/.nojekyll"
    echo "::notice::Created .nojekyll for static site generator: ${INPUT_STATIC_SITE_GENERATOR}"
  fi

  # Set outputs
  {
    echo "base_url=${PAGES_BASE_URL}"
    echo "origin=${PAGES_ORIGIN}"
    echo "host=${PAGES_HOST}"
    echo "base_path=${PAGES_BASE_PATH}"
  } >> "${GITHUB_OUTPUT}"

  echo "::notice::Pages configured — base_url=${PAGES_BASE_URL} origin=${PAGES_ORIGIN} host=${PAGES_HOST} base_path=${PAGES_BASE_PATH}"
}
