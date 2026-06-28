#!/usr/bin/env bash
# parse-url.sh — Parse a GitHub Pages URL into components.
# shellcheck disable=SC2034

set -euo pipefail

# Extract the origin (protocol + host) from a URL.
# e.g., https://user.github.io/repo -> https://user.github.io
extract_origin() {
  local url="$1"
  echo "${url}" | sed -E 's|^(https?://[^/]+).*|\1|'
}

# Extract the hostname from a URL.
# e.g., https://user.github.io/repo -> user.github.io
extract_host() {
  local url="$1"
  echo "${url}" | sed -E 's|^https?://([^/]+).*|\1|'
}

# Extract the base path from a URL.
# e.g., https://user.github.io/repo -> /repo
# e.g., https://user.github.io -> /
extract_base_path() {
  local url="$1"
  local path
  path="$(echo "${url}" | sed -E 's|^https?://[^/]+||')"

  # Remove trailing slash if present (but keep bare /)
  path="${path%/}"

  if [[ -z "${path}" ]]; then
    echo "/"
  else
    echo "${path}"
  fi
}

# Parse a Pages URL and set output variables.
# Usage: parse_pages_url "https://user.github.io/repo"
# Sets: PAGES_BASE_URL, PAGES_ORIGIN, PAGES_HOST, PAGES_BASE_PATH
parse_pages_url() {
  local url="$1"

  # Remove trailing slash for consistency
  url="${url%/}"

  PAGES_BASE_URL="${url}"
  PAGES_ORIGIN="$(extract_origin "${url}")"
  PAGES_HOST="$(extract_host "${url}")"
  PAGES_BASE_PATH="$(extract_base_path "${url}")"
}
