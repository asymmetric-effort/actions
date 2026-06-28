#!/usr/bin/env bash
# validate.sh — Validate inputs for upload-artifact.

set -euo pipefail

validate_upload_inputs() {
  local name="${INPUT_NAME:-}"
  local path="${INPUT_PATH:-}"
  local if_no_files_found="${INPUT_IF_NO_FILES_FOUND-warn}"
  local compression_level="${INPUT_COMPRESSION_LEVEL-6}"
  local retention_days="${INPUT_RETENTION_DAYS:-}"

  if [[ -z "${name}" ]]; then
    echo "::error::name is required and cannot be empty" >&2
    return 1
  fi

  if [[ -z "${path}" ]]; then
    echo "::error::path is required and cannot be empty" >&2
    return 1
  fi

  if [[ "${if_no_files_found}" != "warn" && "${if_no_files_found}" != "error" && "${if_no_files_found}" != "ignore" ]]; then
    echo "::error::if-no-files-found must be one of: warn, error, ignore (got '${if_no_files_found}')" >&2
    return 1
  fi

  if ! [[ "${compression_level}" =~ ^[0-9]$ ]]; then
    echo "::error::compression-level must be a single digit 0-9 (got '${compression_level}')" >&2
    return 1
  fi

  if [[ -n "${retention_days}" ]]; then
    if ! [[ "${retention_days}" =~ ^[1-9][0-9]*$ ]]; then
      echo "::error::retention-days must be a positive integer (got '${retention_days}')" >&2
      return 1
    fi
    if [[ "${retention_days}" -lt 1 || "${retention_days}" -gt 90 ]]; then
      echo "::error::retention-days must be between 1 and 90 (got '${retention_days}')" >&2
      return 1
    fi
  fi

  echo "::notice::Validated: name=${name}, path=${path}, if-no-files-found=${if_no_files_found}, compression-level=${compression_level}"
}
