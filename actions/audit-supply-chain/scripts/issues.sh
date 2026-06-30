#!/usr/bin/env bash
# issues.sh — Create GitHub issues for third-party action findings.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

LABEL_NAME="github-action-request"

# Ensure the github-action-request label exists, create if missing.
ensure_label() {
  local repo="$1"

  if gh label list --repo "$repo" --json name --jq '.[].name' 2>/dev/null | grep -qx "$LABEL_NAME"; then
    return 0
  fi

  echo "::notice::Creating label '${LABEL_NAME}' in ${repo}"
  gh label create "$LABEL_NAME" \
    --repo "$repo" \
    --description "Request to replace a third-party GitHub Action with an internal action" \
    --color "d93f0b" 2>/dev/null || true
}

# Build the upstream action URL on GitHub.
build_upstream_url() {
  local action_path="$1"
  echo "https://github.com/${action_path}"
}

# Build the workflow file URL in the scanned repo.
build_workflow_url() {
  local repo="$1"
  local workflow_file="$2"
  local server_url="${GITHUB_SERVER_URL:-https://github.com}"
  echo "${server_url}/${repo}/blob/main/${workflow_file}"
}

# Build the issue title for a finding.
build_issue_title() {
  local action_path="$1"
  echo "Replace \`${action_path}\` with internal action"
}

# Build the issue body for a finding.
build_issue_body() {
  local action_ref="$1"
  local action_path="$2"
  local workflow_file="$3"
  local repo="$4"
  local upstream_url="$5"
  local workflow_url="$6"

  cat <<BODY
## Third-Party Action Replacement Request

A third-party GitHub Action has been detected in this repository's CI/CD workflows.

**Third-party action:** \`${action_ref}\`
**Upstream:** ${upstream_url}
**Source workflow:** [${workflow_file}](${workflow_url})

This action should be replaced with an internal equivalent to eliminate the external supply-chain dependency.
BODY
}

# Check if an open issue already exists for this action.
issue_exists() {
  local repo="$1"
  local action_path="$2"

  local title
  title="$(build_issue_title "$action_path")"

  local count
  count="$(gh issue list \
    --repo "$repo" \
    --state open \
    --label "$LABEL_NAME" \
    --search "Replace \`${action_path}\`" \
    --json number \
    --jq 'length' 2>/dev/null || echo "0")"

  [[ "$count" -gt 0 ]]
}

# Create an issue for a third-party action finding.
create_finding_issue() {
  local repo="$1"
  local action_ref="$2"
  local workflow_file="$3"

  local action_path
  action_path="$(extract_action_path "$action_ref")"

  # Check for existing issue.
  if issue_exists "$repo" "$action_path"; then
    echo "::notice::Issue already exists for ${action_path}, skipping"
    return 0
  fi

  local upstream_url
  upstream_url="$(build_upstream_url "$action_path")"

  local workflow_url
  workflow_url="$(build_workflow_url "$repo" "$workflow_file")"

  local title
  title="$(build_issue_title "$action_path")"

  local body
  body="$(build_issue_body "$action_ref" "$action_path" "$workflow_file" "$repo" "$upstream_url" "$workflow_url")"

  echo "::notice::Creating issue: ${title}"
  gh issue create \
    --repo "$repo" \
    --title "$title" \
    --body "$body" \
    --label "$LABEL_NAME"
}

# Main entry point: scan workflows and create issues.
audit_supply_chain() {
  local repo="${GITHUB_REPOSITORY}"
  local allowed_orgs="${INPUT_ALLOWED_ORGS:-actions,github,asymmetric-effort}"

  parse_allowed_orgs "$allowed_orgs"

  echo "Auditing supply chain for ${repo}..."
  echo "Allowed orgs: ${ALLOWED_ORGS_ARRAY[*]}"

  # Ensure label exists.
  ensure_label "$repo"

  # Scan workflows.
  local findings
  findings="$(scan_workflows)"

  if [[ -z "$findings" ]]; then
    echo "::notice::No third-party actions found"
    echo "findings_count=0" >> "${GITHUB_OUTPUT}"
    return 0
  fi

  # Count findings.
  local count
  count="$(echo "$findings" | wc -l)"
  echo "::notice::Found ${count} third-party action(s)"

  # Create issues for each finding.
  while IFS='|' read -r action_ref workflow_file; do
    create_finding_issue "$repo" "$action_ref" "$workflow_file"
  done <<< "$findings"

  echo "findings_count=${count}" >> "${GITHUB_OUTPUT}"
  echo "Audit complete: ${count} finding(s)"
}
