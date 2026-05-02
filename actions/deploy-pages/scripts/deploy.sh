#!/usr/bin/env bash
# deploy.sh — Deploy static files to a GitHub Pages branch.

set -euo pipefail

# Build the commit message
build_commit_message() {
  local source_sha="${GITHUB_SHA:-unknown}"

  if [[ -n "${INPUT_FULL_COMMIT_MESSAGE:-}" ]]; then
    echo "${INPUT_FULL_COMMIT_MESSAGE}"
    return
  fi

  local msg="${INPUT_COMMIT_MESSAGE:-deploy:}"
  echo "${msg} ${source_sha}"
}

# Determine the remote URL
get_remote_url() {
  local repo="${INPUT_EXTERNAL_REPOSITORY:-${GITHUB_REPOSITORY}}"
  local server="${GITHUB_SERVER_URL:-https://github.com}"

  if [[ -n "${INPUT_DEPLOY_KEY:-}" ]]; then
    # SSH URL for deploy key auth
    local host
    host="$(echo "${server}" | sed 's|^https\?://||' | sed 's|/.*||')"
    echo "git@${host}:${repo}.git"
  else
    # HTTPS URL with token
    local token="${INPUT_TOKEN:-}"
    echo "https://x-access-token:${token}@${server#https://}/${repo}.git"
  fi
}

# Configure SSH for deploy key
setup_deploy_key() {
  local deploy_key="${INPUT_DEPLOY_KEY:-}"

  if [[ -z "${deploy_key}" ]]; then
    return
  fi

  local ssh_dir="${HOME}/.ssh"
  mkdir -p "${ssh_dir}"
  chmod 700 "${ssh_dir}"

  local key_file="${ssh_dir}/deploy_key"
  echo "${deploy_key}" > "${key_file}"
  chmod 600 "${key_file}"

  # Configure SSH to use the deploy key and skip host verification
  cat > "${ssh_dir}/config" << SSHCONFIG
Host *
  IdentityFile ${key_file}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
SSHCONFIG
  chmod 600 "${ssh_dir}/config"

  export GIT_SSH_COMMAND="ssh -i ${key_file} -o StrictHostKeyChecking=no"
  echo "::notice::Deploy key configured"
}

# Prepare the publish directory contents in a work directory
prepare_contents() {
  local publish_dir="$1"
  local work_dir="$2"
  local destination_dir="${INPUT_DESTINATION_DIR:-}"
  local enable_jekyll="${INPUT_ENABLE_JEKYLL:-false}"
  local cname="${INPUT_CNAME:-}"
  local exclude_assets="${INPUT_EXCLUDE_ASSETS:-.github}"

  local target_dir="${work_dir}"
  if [[ -n "${destination_dir}" ]]; then
    target_dir="${work_dir}/${destination_dir}"
    mkdir -p "${target_dir}"
  fi

  # Copy files from publish_dir to target
  # Use rsync-like behavior with cp
  cp -a "${publish_dir}/." "${target_dir}/"

  # Remove excluded assets (iterative)
  if [[ -n "${exclude_assets}" ]]; then
    while IFS= read -r pattern || [[ -n "${pattern}" ]]; do
      pattern="$(echo "${pattern}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [[ -z "${pattern}" ]] && continue
      # Remove matching files/dirs from the target
      while IFS= read -r match; do
        if [[ -e "${match}" ]]; then
          rm -rf "${match}"
        fi
      done < <(compgen -G "${target_dir}/${pattern}" 2>/dev/null || true)
    done <<< "${exclude_assets}"
  fi

  # Create .nojekyll unless Jekyll is enabled
  if [[ "${enable_jekyll}" != "true" ]]; then
    touch "${work_dir}/.nojekyll"
  fi

  # Write CNAME file if specified
  if [[ -n "${cname}" ]]; then
    echo "${cname}" > "${work_dir}/CNAME"
  fi
}

# Deploy to the target branch
deploy_to_pages() {
  local publish_branch="${INPUT_PUBLISH_BRANCH:-gh-pages}"
  local force_orphan="${INPUT_FORCE_ORPHAN:-false}"
  local keep_files="${INPUT_KEEP_FILES:-false}"
  local allow_empty="${INPUT_ALLOW_EMPTY_COMMIT:-false}"
  local user_name="${INPUT_USER_NAME:-github-actions[bot]}"
  local user_email="${INPUT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
  local publish_dir="${INPUT_PUBLISH_DIR:-public}"
  local tag_name="${INPUT_TAG_NAME:-}"
  local tag_message="${INPUT_TAG_MESSAGE:-}"

  # Resolve publish_dir to absolute path
  publish_dir="$(cd "${publish_dir}" && pwd)"

  # Set up deploy key if provided
  setup_deploy_key

  local remote_url
  remote_url="$(get_remote_url)"

  local commit_msg
  commit_msg="$(build_commit_message)"

  # Create a temporary working directory
  local work_dir
  work_dir="$(mktemp -d)"
  local original_dir
  original_dir="$(pwd)"

  cd "${work_dir}"
  git init -q

  git config user.name "${user_name}"
  git config user.email "${user_email}"

  # Try to fetch the existing branch
  local branch_exists=false
  if git fetch --depth=1 "${remote_url}" "${publish_branch}" 2>/dev/null; then
    branch_exists=true
  fi

  if [[ "${force_orphan}" == "true" ]]; then
    # Orphan branch — single commit, no history
    git checkout --orphan "${publish_branch}"
  elif [[ "${branch_exists}" == "true" ]]; then
    git checkout -b "${publish_branch}" FETCH_HEAD
  else
    git checkout --orphan "${publish_branch}"
  fi

  # Clean the working tree if not keeping files (preserve .git directory)
  if [[ "${keep_files}" != "true" || "${force_orphan}" == "true" ]]; then
    git rm -rf --quiet . 2>/dev/null || true
    # Remove remaining untracked files but keep .git
    local item
    while IFS= read -r item; do
      [[ "$(basename "${item}")" == ".git" ]] && continue
      rm -rf "${item}"
    done < <(find . -maxdepth 1 -not -name . -not -name .git 2>/dev/null)
  fi

  # Copy the publish directory contents
  prepare_contents "${publish_dir}" "${work_dir}"

  # Stage all files
  git add --all

  # Check if there are changes
  if git diff --cached --quiet 2>/dev/null; then
    if [[ "${allow_empty}" != "true" ]]; then
      echo "::notice::No changes to deploy — skipping commit"
      echo "deploy_branch=${publish_branch}" >> "${GITHUB_OUTPUT}"
      echo "commit_hash=" >> "${GITHUB_OUTPUT}"
      cd "${original_dir}"
      rm -rf "${work_dir}"
      return 0
    fi
    # Create empty commit
    git commit --allow-empty -m "${commit_msg}"
  else
    git commit -m "${commit_msg}"
  fi

  # Create tag if requested
  if [[ -n "${tag_name}" ]]; then
    if [[ -n "${tag_message}" ]]; then
      git tag -a "${tag_name}" -m "${tag_message}"
    else
      git tag "${tag_name}"
    fi
  fi

  # Push to remote
  echo "::notice::Pushing to ${publish_branch}..."
  if [[ "${force_orphan}" == "true" ]]; then
    git push --force "${remote_url}" "${publish_branch}"
  else
    git push "${remote_url}" "${publish_branch}"
  fi

  # Push tag if created
  if [[ -n "${tag_name}" ]]; then
    git push "${remote_url}" "${tag_name}"
    echo "::notice::Pushed tag ${tag_name}"
  fi

  local commit_hash
  commit_hash="$(git rev-parse HEAD)"

  {
    echo "deploy_branch=${publish_branch}"
    echo "commit_hash=${commit_hash}"
  } >> "${GITHUB_OUTPUT}"

  echo "::notice::Deployed to ${publish_branch} (${commit_hash})"

  # Cleanup: return to original directory and remove work dir
  cd "${original_dir}"
  rm -rf "${work_dir}"
}
