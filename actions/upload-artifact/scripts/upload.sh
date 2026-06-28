#!/usr/bin/env bash
# upload.sh — Resolve files, create archive, and upload artifact via GitHub Actions Artifact API.

set -euo pipefail

# Build the artifact service base URL.
build_artifact_url() {
  local runtime_url="${ACTIONS_RUNTIME_URL}"
  local run_id="${GITHUB_RUN_ID}"
  # Remove trailing slash from runtime_url if present
  runtime_url="${runtime_url%/}"
  echo "${runtime_url}/_apis/pipelines/workflows/${run_id}/artifacts?api-version=6.0-preview"
}

# Resolve glob patterns in INPUT_PATH (newline-separated) into a list of matching files.
# Prints one file path per line to stdout.
resolve_glob_paths() {
  local path_input="${1}"
  local found_files=()

  while IFS= read -r pattern; do
    # Skip empty lines
    [[ -z "${pattern}" ]] && continue
    # Trim leading/trailing whitespace
    pattern="$(echo "${pattern}" | xargs)"
    [[ -z "${pattern}" ]] && continue

    if [[ -d "${pattern}" ]]; then
      # If it is a directory, include all files recursively
      while IFS= read -r -d '' file; do
        found_files+=("${file}")
      done < <(find "${pattern}" -type f -print0)
    elif [[ -f "${pattern}" ]]; then
      found_files+=("${pattern}")
    else
      # Treat as glob
      local glob_matches=()
      # Use nullglob so non-matching globs expand to nothing
      local old_nullglob
      old_nullglob="$(shopt -p nullglob || true)"
      shopt -s nullglob
      for match in ${pattern}; do
        if [[ -f "${match}" ]]; then
          glob_matches+=("${match}")
        elif [[ -d "${match}" ]]; then
          while IFS= read -r -d '' file; do
            glob_matches+=("${file}")
          done < <(find "${match}" -type f -print0)
        fi
      done
      eval "${old_nullglob}"
      found_files+=("${glob_matches[@]}")
    fi
  done <<< "${path_input}"

  # Print unique files
  if [[ ${#found_files[@]} -gt 0 ]]; then
    printf '%s\n' "${found_files[@]}" | sort -u
  fi
}

# Create a tar.gz archive of the resolved files.
# Args: $1 = archive path, $2 = compression level, remaining args = file list (newline-separated via stdin)
create_archive() {
  local archive_path="${1}"
  local compression_level="${2}"
  local file_list="${3}"
  local tmp_filelist
  tmp_filelist="$(mktemp)"

  echo "${file_list}" > "${tmp_filelist}"

  # Determine a common base directory for all files
  local common_prefix=""
  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    local dir
    dir="$(dirname "${f}")"
    if [[ -z "${common_prefix}" ]]; then
      common_prefix="${dir}"
    else
      # Find common prefix between common_prefix and dir
      while [[ "${dir}" != "${common_prefix}"* ]]; do
        common_prefix="$(dirname "${common_prefix}")"
      done
    fi
  done < "${tmp_filelist}"

  # Default to current directory if no common prefix
  if [[ -z "${common_prefix}" ]]; then
    common_prefix="."
  fi

  # Build tar using the file list relative to common prefix
  local relative_files=()
  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    # Make path relative to common_prefix
    local rel="${f#"${common_prefix}"/}"
    relative_files+=("${rel}")
  done < "${tmp_filelist}"

  rm -f "${tmp_filelist}"

  # Create archive from common_prefix directory
  tar -czf "${archive_path}" \
    -I "gzip -${compression_level}" \
    -C "${common_prefix}" \
    "${relative_files[@]}" 2>/dev/null || \
  tar -czf "${archive_path}" \
    -C "${common_prefix}" \
    "${relative_files[@]}"

  echo "::notice::Created archive ${archive_path} ($(du -h "${archive_path}" | cut -f1))"
}

# Create an artifact container via the Actions Runtime API.
# Prints the container ID to stdout.
create_artifact_container() {
  local artifact_name="${1}"
  local retention_days="${2:-}"
  local artifact_url
  artifact_url="$(build_artifact_url)"

  local payload="{\"type\":\"actions_storage\",\"name\":\"${artifact_name}\"}"
  if [[ -n "${retention_days}" ]]; then
    payload="{\"type\":\"actions_storage\",\"name\":\"${artifact_name}\",\"retentionDays\":${retention_days}}"
  fi

  local response
  response="$(curl -s -S \
    -X POST \
    -H "Authorization: Bearer ${ACTIONS_RUNTIME_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "${artifact_url}")"

  local container_id
  container_id="$(echo "${response}" | jq -r '.containerId // empty')"

  if [[ -z "${container_id}" ]]; then
    echo "::error::Failed to create artifact container. Response: ${response}" >&2
    return 1
  fi

  echo "${container_id}"
}

# Upload a file to the artifact container.
upload_artifact_file() {
  local container_id="${1}"
  local artifact_name="${2}"
  local file_path="${3}"
  local file_size
  file_size="$(stat -c%s "${file_path}" 2>/dev/null || stat -f%z "${file_path}" 2>/dev/null)"

  local runtime_url="${ACTIONS_RUNTIME_URL%/}"
  local upload_url="${runtime_url}/_apis/resources/Containers/${container_id}?itemPath=${artifact_name}/${artifact_name}.tar.gz&api-version=6.0-preview"

  local chunk_size=$((4 * 1024 * 1024)) # 4MB chunks
  local offset=0

  if [[ "${file_size}" -le "${chunk_size}" ]]; then
    # Single upload for small files
    curl -s -S \
      -X PUT \
      -H "Authorization: Bearer ${ACTIONS_RUNTIME_TOKEN}" \
      -H "Content-Type: application/octet-stream" \
      -H "Content-Range: bytes 0-$((file_size - 1))/${file_size}" \
      --data-binary "@${file_path}" \
      "${upload_url}" > /dev/null
  else
    # Chunked upload for larger files
    local tmp_chunk
    tmp_chunk="$(mktemp)"
    while [[ "${offset}" -lt "${file_size}" ]]; do
      local end=$((offset + chunk_size - 1))
      if [[ "${end}" -ge "${file_size}" ]]; then
        end=$((file_size - 1))
      fi
      local length=$((end - offset + 1))

      dd if="${file_path}" bs=1 skip="${offset}" count="${length}" of="${tmp_chunk}" 2>/dev/null

      curl -s -S \
        -X PUT \
        -H "Authorization: Bearer ${ACTIONS_RUNTIME_TOKEN}" \
        -H "Content-Type: application/octet-stream" \
        -H "Content-Range: bytes ${offset}-${end}/${file_size}" \
        --data-binary "@${tmp_chunk}" \
        "${upload_url}" > /dev/null

      offset=$((end + 1))
    done
    rm -f "${tmp_chunk}"
  fi

  echo "::notice::Uploaded ${file_path} (${file_size} bytes)"
}

# Finalize the artifact upload.
finalize_artifact() {
  local container_id="${1}"
  local artifact_name="${2}"
  local file_size="${3}"

  local artifact_url
  artifact_url="$(build_artifact_url)"

  local response
  response="$(curl -s -S \
    -X PATCH \
    -H "Authorization: Bearer ${ACTIONS_RUNTIME_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"size\":${file_size}}" \
    "${artifact_url}&artifactName=${artifact_name}")"

  echo "::notice::Finalized artifact '${artifact_name}'"
}

# Delete an existing artifact by name (for overwrite support).
delete_existing_artifact() {
  local artifact_name="${1}"
  local repo="${GITHUB_REPOSITORY}"
  local run_id="${GITHUB_RUN_ID}"

  # List artifacts for this run and find by name
  local response
  response="$(curl -s -S \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${repo}/actions/runs/${run_id}/artifacts")"

  local artifact_id
  artifact_id="$(echo "${response}" | jq -r ".artifacts[] | select(.name==\"${artifact_name}\") | .id // empty")"

  if [[ -n "${artifact_id}" ]]; then
    curl -s -S \
      -X DELETE \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/${repo}/actions/artifacts/${artifact_id}" > /dev/null
    echo "::notice::Deleted existing artifact '${artifact_name}' (id: ${artifact_id})"
  fi
}

# Main entry point: resolve files, create archive, upload via Actions Runtime API.
upload_artifact() {
  local name="${INPUT_NAME}"
  local path_input="${INPUT_PATH}"
  local if_no_files_found="${INPUT_IF_NO_FILES_FOUND:-warn}"
  local compression_level="${INPUT_COMPRESSION_LEVEL:-6}"
  local overwrite="${INPUT_OVERWRITE:-false}"
  local retention_days="${INPUT_RETENTION_DAYS:-}"

  # Resolve file paths
  local file_list
  file_list="$(resolve_glob_paths "${path_input}")"

  local file_count
  file_count="$(echo "${file_list}" | grep -c . || true)"

  if [[ "${file_count}" -eq 0 ]]; then
    case "${if_no_files_found}" in
      error)
        echo "::error::No files found matching path: ${path_input}" >&2
        return 1
        ;;
      warn)
        echo "::warning::No files found matching path: ${path_input}"
        echo "artifact-id=" >> "${GITHUB_OUTPUT}"
        echo "artifact-url=" >> "${GITHUB_OUTPUT}"
        return 0
        ;;
      ignore)
        echo "::notice::No files found matching path: ${path_input}. Ignoring."
        echo "artifact-id=" >> "${GITHUB_OUTPUT}"
        echo "artifact-url=" >> "${GITHUB_OUTPUT}"
        return 0
        ;;
    esac
  fi

  echo "::notice::Found ${file_count} file(s) to upload"

  # Handle overwrite
  if [[ "${overwrite}" == "true" ]]; then
    delete_existing_artifact "${name}"
  fi

  # Create archive
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local archive_path="${tmp_dir}/${name}.tar.gz"

  create_archive "${archive_path}" "${compression_level}" "${file_list}"

  # Create artifact container
  local container_id
  container_id="$(create_artifact_container "${name}" "${retention_days}")"

  # Upload the archive
  upload_artifact_file "${container_id}" "${name}" "${archive_path}"

  # Finalize
  local archive_size
  archive_size="$(stat -c%s "${archive_path}" 2>/dev/null || stat -f%z "${archive_path}" 2>/dev/null)"
  finalize_artifact "${container_id}" "${name}" "${archive_size}"

  # Set outputs
  local repo="${GITHUB_REPOSITORY}"
  local run_id="${GITHUB_RUN_ID}"
  echo "artifact-id=${container_id}" >> "${GITHUB_OUTPUT}"
  echo "artifact-url=https://github.com/${repo}/actions/runs/${run_id}/artifacts/${container_id}" >> "${GITHUB_OUTPUT}"

  # Cleanup
  rm -rf "${tmp_dir}"

  echo "::notice::Artifact '${name}' uploaded successfully (id: ${container_id})"
}
