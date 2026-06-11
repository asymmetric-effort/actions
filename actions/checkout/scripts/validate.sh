#!/usr/bin/env bash
# validate.sh — Validate inputs for the checkout action.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Check that the token is not empty
validate_token() {
  local token="${1:-}"
  if [[ -z "${token}" ]]; then
    echo "::error::Input 'token' must not be empty" >&2
    return 1
  fi
}

# Check that fetch-depth is a non-negative integer
validate_fetch_depth() {
  local depth="${1:-}"
  if ! [[ "${depth}" =~ ^[0-9]+$ ]]; then
    echo "::error::Input 'fetch-depth' must be a non-negative integer, got '${depth}'" >&2
    return 1
  fi
}

# Check that submodules value is valid
validate_submodules() {
  local submodules="${1:-}"
  case "${submodules}" in
    false|true|recursive) ;;
    *)
      echo "::error::Input 'submodules' must be 'false', 'true', or 'recursive', got '${submodules}'" >&2
      return 1
      ;;
  esac
}

# Main validation entry point
validate_checkout_inputs() {
  local token="${INPUT_TOKEN:-}"
  local fetch_depth="${INPUT_FETCH_DEPTH:-1}"
  local submodules="${INPUT_SUBMODULES:-false}"

  validate_token "${token}" || return 1
  validate_fetch_depth "${fetch_depth}" || return 1
  validate_submodules "${submodules}" || return 1

  echo "::notice::Checkout inputs validated successfully"
}
