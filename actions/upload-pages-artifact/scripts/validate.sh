#!/usr/bin/env bash
# validate.sh — Validate inputs for upload-pages-artifact.

set -euo pipefail

validate_pages_inputs() {
  local path="${INPUT_PATH:-.}"
  local retention_days="${INPUT_RETENTION_DAYS:-1}"

  if [[ ! -d "${path}" ]]; then
    echo "::error::path does not exist or is not a directory: ${path}" >&2
    return 1
  fi

  if ! [[ "${retention_days}" =~ ^[1-9][0-9]*$ ]]; then
    echo "::error::retention-days must be a positive integer: ${retention_days}" >&2
    return 1
  fi

  echo "::notice::Validated: path=${path}, retention-days=${retention_days}"
}
