#!/usr/bin/env bash
# install-tools.sh — Install Go ecosystem tools (govulncheck, etc.).
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Get the installed govulncheck version, or empty if not installed
get_govulncheck_version() {
  if command -v govulncheck >/dev/null 2>&1; then
    govulncheck -version 2>/dev/null | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
  else
    echo ""
  fi
}

# Install govulncheck
install_govulncheck() {
  local version="${1:-latest}"

  # Check if already installed (from cache)
  local existing
  existing="$(get_govulncheck_version)"
  if [[ -n "${existing}" && "${existing}" != "" ]]; then
    if [[ "${version}" == "latest" || "${existing}" == "${version}" ]]; then
      echo "::notice::govulncheck ${existing} already installed (from cache)"
      echo "govulncheck-version=${existing}" >> "${GITHUB_OUTPUT}"
      return 0
    fi
  fi

  echo "Installing govulncheck@${version}..."

  local install_pkg="golang.org/x/vuln/cmd/govulncheck"
  if [[ "${version}" == "latest" ]]; then
    go install "${install_pkg}@latest"
  else
    # Ensure version starts with 'v'
    local ver="${version}"
    if [[ "${ver}" != v* ]]; then
      ver="v${ver}"
    fi
    go install "${install_pkg}@${ver}"
  fi

  local installed
  installed="$(get_govulncheck_version)"
  echo "::notice::govulncheck ${installed} installed"
  echo "govulncheck-version=${installed}" >> "${GITHUB_OUTPUT}"
}

# Main entry point: install all Go tools
install_go_tools() {
  local govulncheck_version="${GOVULNCHECK_VERSION:-latest}"

  install_govulncheck "${govulncheck_version}"
}
