#!/usr/bin/env bash
# assets.sh — Resolve file globs and upload release assets.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Global array populated by resolve_files
_RESOLVED_FILES=()

# Resolve glob patterns to file paths (iterative)
resolve_files() {
  local patterns="$1"
  local working_dir="$2"
  local fail_on_unmatched="$3"

  _RESOLVED_FILES=()

  local -a pattern_list=()
  while IFS= read -r line || [[ -n "${line}" ]]; do
    pattern_list+=("${line}")
  done <<< "${patterns}"

  local idx=0
  while [[ ${idx} -lt ${#pattern_list[@]} ]]; do
    local pattern="${pattern_list[${idx}]}"
    idx=$((idx + 1))

    pattern="$(echo "${pattern}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "${pattern}" ]] && continue

    local glob_path
    if [[ "${pattern}" == /* ]]; then
      glob_path="${pattern}"
    else
      glob_path="${working_dir}/${pattern}"
    fi

    local matched=0
    local file
    while IFS= read -r file; do
      if [[ -f "${file}" ]]; then
        _RESOLVED_FILES+=("${file}")
        matched=1
      fi
    done < <(compgen -G "${glob_path}" 2>/dev/null || true)

    if [[ "${matched}" -eq 0 ]]; then
      if [[ "${fail_on_unmatched}" == "true" ]]; then
        echo "::error::Glob pattern matched no files: ${pattern}" >&2
        return 1
      else
        echo "::warning::Glob pattern matched no files: ${pattern}" >&2
      fi
    fi
  done
}

# Deduplicate file paths (iterative)
deduplicate_files() {
  local -n input_arr=$1
  local -n output_arr=$2
  local -A seen=()

  local i=0
  while [[ $i -lt ${#input_arr[@]} ]]; do
    local file="${input_arr[$i]}"
    local real_path
    real_path="$(realpath "${file}" 2>/dev/null || echo "${file}")"
    if [[ -z "${seen[${real_path}]+_}" ]]; then
      seen["${real_path}"]=1
      output_arr+=("${file}")
    fi
    i=$((i + 1))
  done
}

# Get MIME type for a file
get_mime_type() {
  local file="$1"
  local ext="${file##*.}"
  ext="$(echo "${ext}" | tr '[:upper:]' '[:lower:]')"

  case "${ext}" in
    zip)      echo "application/zip" ;;
    tar)      echo "application/x-tar" ;;
    gz|tgz)   echo "application/gzip" ;;
    bz2)      echo "application/x-bzip2" ;;
    xz)       echo "application/x-xz" ;;
    deb)      echo "application/vnd.debian.binary-package" ;;
    rpm)      echo "application/x-rpm" ;;
    exe|msi|dmg|pkg) echo "application/octet-stream" ;;
    js)       echo "application/javascript" ;;
    json)     echo "application/json" ;;
    txt)      echo "text/plain" ;;
    md)       echo "text/markdown" ;;
    sha256|sha512) echo "text/plain" ;;
    sig|asc)  echo "application/pgp-signature" ;;
    *)        echo "application/octet-stream" ;;
  esac
}

# Delete an existing asset by name
delete_existing_asset() {
  local repo="$1"
  local tag="$2"
  local file_name="$3"

  local asset_id
  asset_id="$(gh api "repos/${repo}/releases/tags/${tag}" --jq \
    ".assets[] | select(.name == \"${file_name}\") | .id" 2>/dev/null || true)"

  if [[ -n "${asset_id}" ]]; then
    echo "::notice::Deleting existing asset: ${file_name} (id: ${asset_id})"
    gh api -X DELETE "repos/${repo}/releases/assets/${asset_id}" 2>/dev/null || true
  fi
}

# Upload a single asset
upload_single_asset() {
  local repo="$1"
  local tag="$2"
  local file_path="$3"
  local overwrite="$4"

  local file_name
  file_name="$(basename "${file_path}")"
  local content_type
  content_type="$(get_mime_type "${file_path}")"
  local file_size
  file_size="$(stat -c%s "${file_path}" 2>/dev/null || stat -f%z "${file_path}" 2>/dev/null || echo "0")"

  if [[ "${overwrite}" == "true" ]]; then
    delete_existing_asset "${repo}" "${tag}" "${file_name}"
  fi

  echo "Uploading ${file_name} (${file_size} bytes, ${content_type})"
  gh release upload --repo "${repo}" --clobber "${tag}" "${file_path}" 2>&1
  echo "::notice::Uploaded ${file_name}"
}

# Main entry point
upload_assets() {
  local files="${INPUT_FILES:?INPUT_FILES is required}"
  local working_dir="${INPUT_WORKING_DIRECTORY:-.}"
  local overwrite="${INPUT_OVERWRITE_FILES:-true}"
  local fail_on_unmatched="${INPUT_FAIL_ON_UNMATCHED_FILES:-false}"
  local repo="${INPUT_REPOSITORY:?INPUT_REPOSITORY is required}"
  local tag="${RELEASE_TAG:?RELEASE_TAG is required}"

  resolve_files "${files}" "${working_dir}" "${fail_on_unmatched}"

  if [[ ${#_RESOLVED_FILES[@]} -eq 0 ]]; then
    echo "::notice::No files matched the provided patterns"
    echo 'assets=[]' >> "${GITHUB_OUTPUT}"
    return 0
  fi

  local unique_files=()
  deduplicate_files _RESOLVED_FILES unique_files

  echo "Uploading ${#unique_files[@]} asset(s)..."

  local assets_json="["
  local first=1
  local i=0
  while [[ $i -lt ${#unique_files[@]} ]]; do
    local file="${unique_files[$i]}"
    upload_single_asset "${repo}" "${tag}" "${file}" "${overwrite}"

    local name
    name="$(basename "${file}")"
    local size
    size="$(stat -c%s "${file}" 2>/dev/null || stat -f%z "${file}" 2>/dev/null || echo "0")"

    if [[ ${first} -eq 1 ]]; then
      first=0
    else
      assets_json+=","
    fi
    assets_json+="{\"name\":\"${name}\",\"size\":${size}}"
    i=$((i + 1))
  done
  assets_json+="]"

  echo "assets=${assets_json}" >> "${GITHUB_OUTPUT}"
}
