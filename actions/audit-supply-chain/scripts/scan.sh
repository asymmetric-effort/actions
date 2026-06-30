#!/usr/bin/env bash
# scan.sh — Scan workflow files for third-party action references.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Parse the allowed orgs input into an array.
# Returns via global ALLOWED_ORGS_ARRAY.
parse_allowed_orgs() {
  local input="$1"
  ALLOWED_ORGS_ARRAY=()
  IFS=',' read -ra ALLOWED_ORGS_ARRAY <<< "$input"
  # Trim whitespace from each entry.
  local i
  for i in "${!ALLOWED_ORGS_ARRAY[@]}"; do
    ALLOWED_ORGS_ARRAY[i]="$(echo "${ALLOWED_ORGS_ARRAY[i]}" | tr -d '[:space:]')"
  done
}

# Check if an org is in the allowed list.
is_allowed_org() {
  local org="$1"
  local allowed
  for allowed in "${ALLOWED_ORGS_ARRAY[@]}"; do
    if [[ "${org}" == "${allowed}" ]]; then
      return 0
    fi
  done
  return 1
}

# Extract the org from an action reference (e.g., "softprops/action-gh-release@v2" -> "softprops").
extract_org() {
  local action_ref="$1"
  local path="${action_ref%%@*}"
  echo "${path%%/*}"
}

# Extract the full action path without ref (e.g., "softprops/action-gh-release@v2" -> "softprops/action-gh-release").
extract_action_path() {
  local action_ref="$1"
  echo "${action_ref%%@*}"
}

# Extract 'uses:' references from a workflow file.
# Outputs one action reference per line (e.g., "softprops/action-gh-release@v2").
# Skips local actions (./) and docker:// references.
extract_uses_from_file() {
  local file="$1"
  local matches
  matches="$(grep -oP '^\s*-?\s*uses:\s*\K\S+' "$file" 2>/dev/null || true)"

  [[ -z "$matches" ]] && return 0

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    # Skip local actions and docker references.
    [[ "$ref" == ./* ]] && continue
    [[ "$ref" == docker://* ]] && continue
    echo "$ref"
  done <<< "$matches"
}

# Scan all workflow files and return third-party action references.
# Output format: action_ref|workflow_file (one per line, deduplicated by action path).
scan_workflows() {
  local -A seen
  local workflow

  for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do
    [[ -f "$workflow" ]] || continue

    while IFS= read -r action_ref; do
      [[ -z "$action_ref" ]] && continue

      local org
      org="$(extract_org "$action_ref")"

      # Skip allowed orgs.
      if is_allowed_org "$org"; then
        continue
      fi

      local action_path
      action_path="$(extract_action_path "$action_ref")"

      # Deduplicate by action path within this scan.
      if [[ -n "${seen[$action_path]+_}" ]]; then
        continue
      fi
      seen[$action_path]=1

      echo "${action_ref}|${workflow}"
    done < <(extract_uses_from_file "$workflow")
  done
}
