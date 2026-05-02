#!/usr/bin/env bash
# validate.sh — Validate inputs before deployment.

set -euo pipefail

validate_inputs() {
  local publish_dir="${INPUT_PUBLISH_DIR:-public}"
  local token="${INPUT_TOKEN:-}"
  local deploy_key="${INPUT_DEPLOY_KEY:-}"

  if [[ ! -d "${publish_dir}" ]]; then
    echo "::error::publish_dir does not exist: ${publish_dir}" >&2
    return 1
  fi

  if [[ -z "${token}" && -z "${deploy_key}" ]]; then
    echo "::error::Either token or deploy_key must be provided" >&2
    return 1
  fi

  local file_count
  file_count="$(find "${publish_dir}" -type f 2>/dev/null | head -1 | wc -l)"
  if [[ "${file_count}" -eq 0 ]]; then
    echo "::warning::publish_dir appears to be empty: ${publish_dir}" >&2
  fi

  echo "::notice::Validated: publish_dir=${publish_dir}"
}
