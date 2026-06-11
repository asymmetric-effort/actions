#!/usr/bin/env bash
# analyze.sh — Run CodeQL analysis and upload SARIF results.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Build the SARIF upload payload for the GitHub Code Scanning API.
# Args: sarif_file, category, commit_sha, ref
build_sarif_payload() {
  local sarif_file="$1"
  local category="$2"
  local commit_sha="$3"
  local ref="$4"

  local compressed
  compressed="$(gzip -c "${sarif_file}" | base64 -w 0)"

  local payload
  payload="$(jq -n \
    --arg sarif "${compressed}" \
    --arg commit_sha "${commit_sha}" \
    --arg ref "${ref}" \
    --arg category "${category}" \
    '{
      commit_sha: $commit_sha,
      ref: $ref,
      sarif: $sarif,
      tool_name: "CodeQL"
    } + (if $category != "" then {category: $category} else {} end)'
  )"

  echo "${payload}"
}

# Upload a SARIF file to GitHub Code Scanning API.
# Args: sarif_file, category, token, repo
upload_sarif() {
  local sarif_file="$1"
  local category="$2"
  local token="$3"
  local repo="$4"

  local commit_sha="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}"
  local ref="${GITHUB_REF:-refs/heads/main}"

  echo "::notice::Uploading SARIF to GitHub Code Scanning for ${repo}"

  local payload
  payload="$(build_sarif_payload "${sarif_file}" "${category}" "${commit_sha}" "${ref}")"

  local response
  response="$(curl -fsSL \
    -X POST \
    -H "Authorization: token ${token}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    -d "${payload}" \
    "https://api.github.com/repos/${repo}/code-scanning/sarifs"
  )"

  local sarif_id
  sarif_id="$(echo "${response}" | jq -r '.id // empty')"
  if [[ -n "${sarif_id}" ]]; then
    echo "::notice::SARIF uploaded successfully (id: ${sarif_id})"
  else
    echo "::warning::SARIF upload response did not contain an id: ${response}"
  fi
}

# Finalize and analyze a single CodeQL database.
# Args: db_path, sarif_dir, codeql_bin
analyze_database() {
  local db_path="$1"
  local sarif_dir="$2"
  local codeql_bin="$3"

  local lang
  lang="$(basename "${db_path}")"
  local sarif_file="${sarif_dir}/${lang}.sarif"

  echo "::notice::Finalizing CodeQL database for ${lang}"
  "${codeql_bin}" database finalize "${db_path}"

  echo "::notice::Analyzing CodeQL database for ${lang}"
  "${codeql_bin}" database analyze "${db_path}" \
    --format=sarif-latest \
    --output="${sarif_file}"

  echo "::notice::SARIF results written to ${sarif_file}"
  echo "${sarif_file}"
}

# Main entry point: finalize databases, run analysis, upload results.
analyze_codeql() {
  local category="${INPUT_CATEGORY:-}"
  local output_dir="${INPUT_OUTPUT:-}"
  local upload="${INPUT_UPLOAD:-true}"
  local token="${INPUT_TOKEN:-}"

  local codeql_bin
  codeql_bin="$(get_codeql_path)"

  local db_dir
  db_dir="$(get_codeql_databases_dir)"

  # Create SARIF output directory
  local sarif_dir="${RUNNER_TEMP:-/tmp}/codeql-sarif-results"
  mkdir -p "${sarif_dir}"

  # Analyze each database
  for db_path in "${db_dir}"/*/; do
    if [[ ! -d "${db_path}" ]]; then
      continue
    fi

    local sarif_file
    sarif_file="$(analyze_database "${db_path}" "${sarif_dir}" "${codeql_bin}")"

    # Upload if requested
    if [[ "${upload}" == "true" && -n "${token}" ]]; then
      local repo="${GITHUB_REPOSITORY:-}"
      if [[ -z "${repo}" ]]; then
        echo "::error::GITHUB_REPOSITORY is not set; cannot upload SARIF"
        return 1
      fi
      local lang_category="${category}"
      if [[ -n "${category}" ]]; then
        local lang
        lang="$(basename "${db_path}")"
        lang_category="${category}-${lang}"
      fi
      upload_sarif "${sarif_file}" "${lang_category}" "${token}" "${repo}"
    fi
  done

  # Copy SARIF files to user-specified output directory
  if [[ -n "${output_dir}" ]]; then
    mkdir -p "${output_dir}"
    cp -r "${sarif_dir}"/* "${output_dir}/"
    echo "::notice::SARIF files copied to ${output_dir}"
    sarif_dir="${output_dir}"
  fi

  # Set output
  echo "sarif-output=${sarif_dir}" >> "${GITHUB_OUTPUT}"

  echo "::notice::CodeQL analysis complete"
}
