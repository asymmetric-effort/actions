#!/usr/bin/env bash
# publish.sh — Publish the npm package using OIDC trusted publisher.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Read package name from package.json
read_package_name() {
  local pkg_dir="$1"
  grep -oP '"name"\s*:\s*"\K[^"]+' "${pkg_dir}/package.json" | head -1
}

# Read package version from package.json
read_package_version() {
  local pkg_dir="$1"
  grep -oP '"version"\s*:\s*"\K[^"]+' "${pkg_dir}/package.json" | head -1
}

# Check if this version is already published
check_version_exists() {
  local pkg_name="$1"
  local pkg_version="$2"
  local registry="$3"

  local http_code
  http_code="$(curl -fsSL -o /dev/null -w "%{http_code}" \
    "${registry}/${pkg_name}/${pkg_version}" 2>/dev/null || echo "000")"

  if [[ "${http_code}" == "200" ]]; then
    return 0  # Version exists
  fi
  return 1  # Version does not exist
}

# Build the npm publish command arguments
build_publish_args() {
  local tag="$1"
  local access="$2"
  local dry_run="$3"
  local provenance="$4"

  local args=()
  args+=("--tag" "${tag}")
  args+=("--access" "${access}")

  if [[ "${provenance}" == "true" ]]; then
    args+=("--provenance")
  fi

  if [[ "${dry_run}" == "true" ]]; then
    args+=("--dry-run")
  fi

  echo "${args[*]}"
}

# Main entry point
npm_publish() {
  local pkg_dir="${INPUT_PACKAGE_DIR:-.}"
  local tag="${INPUT_TAG:-latest}"
  local access="${INPUT_ACCESS:-public}"
  local dry_run="${INPUT_DRY_RUN:-false}"
  local provenance="${INPUT_PROVENANCE:-true}"
  local registry="${INPUT_REGISTRY:-https://registry.npmjs.org}"

  local pkg_name
  pkg_name="$(read_package_name "${pkg_dir}")"
  local pkg_version
  pkg_version="$(read_package_version "${pkg_dir}")"

  echo "::notice::Publishing ${pkg_name}@${pkg_version} to ${registry} with tag '${tag}'"

  # Check if version already exists
  if [[ "${dry_run}" != "true" ]]; then
    if check_version_exists "${pkg_name}" "${pkg_version}" "${registry}"; then
      echo "::error::Version ${pkg_version} of ${pkg_name} is already published. Bump the version in package.json before publishing." >&2
      exit 1
    fi
  fi

  # Build args
  local publish_args
  publish_args="$(build_publish_args "${tag}" "${access}" "${dry_run}" "${provenance}")"

  echo "Running: npm publish ${publish_args}"

  # shellcheck disable=SC2086  # Intentional word splitting of args
  (cd "${pkg_dir}" && npm publish ${publish_args})

  if [[ "${dry_run}" == "true" ]]; then
    echo "::notice::Dry run complete — no package was published"
  else
    echo "::notice::Successfully published ${pkg_name}@${pkg_version}"
  fi

  # Set outputs
  {
    echo "version=${pkg_version}"
    echo "package=${pkg_name}"
    echo "registry-url=${registry}"
  } >> "${GITHUB_OUTPUT}"
}
