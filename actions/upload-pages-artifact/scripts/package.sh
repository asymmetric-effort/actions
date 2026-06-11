#!/usr/bin/env bash
# package.sh — Package a directory as a GitHub Pages deployment artifact.

set -euo pipefail

package_pages_artifact() {
  local path="${INPUT_PATH:-.}"

  # Ensure .nojekyll exists so GitHub Pages skips Jekyll processing
  if [[ ! -f "${path}/.nojekyll" ]]; then
    touch "${path}/.nojekyll"
    echo "::notice::Created .nojekyll file in ${path}"
  fi

  # Create a temp directory for the archive
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local artifact_path="${tmp_dir}/artifact.tar.gz"

  # Archive contents at root level (no parent directory wrapper)
  tar -czf "${artifact_path}" -C "${path}" .

  echo "::notice::Created artifact archive: ${artifact_path}"
  echo "artifact-path=${artifact_path}" >> "${GITHUB_OUTPUT}"
}
