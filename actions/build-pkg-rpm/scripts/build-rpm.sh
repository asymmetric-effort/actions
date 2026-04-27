#!/usr/bin/env bash
# build-rpm.sh — Generate spec file (if needed) and build RPM package.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Validate required inputs for inline mode
validate_inline_inputs() {
  local name="${1}"
  local version="${2}"
  local source_dir="${3}"

  if [[ -z "${name}" ]]; then
    echo "::error::Input 'name' is required when no spec-file is provided" >&2
    return 1
  fi
  if [[ -z "${version}" ]]; then
    echo "::error::Input 'version' is required when no spec-file is provided" >&2
    return 1
  fi
  if [[ ! -d "${source_dir}" ]]; then
    echo "::error::source-dir does not exist: ${source_dir}" >&2
    return 1
  fi
}

# Validate that a spec file exists and is readable
validate_spec_file() {
  local spec_file="$1"

  if [[ ! -f "${spec_file}" ]]; then
    echo "::error::spec-file not found: ${spec_file}" >&2
    return 1
  fi
}

# Generate file list from source directory (iterative, no recursion)
generate_file_list() {
  local source_dir="$1"
  local install_prefix="$2"

  # Use find with -print (iterative by nature in find implementation)
  while IFS= read -r file; do
    if [[ -f "${file}" ]]; then
      local rel_path="${file#"${source_dir}"}"
      echo "${install_prefix}${rel_path}"
    fi
  done < <(find "${source_dir}" -type f 2>/dev/null | sort)
}

# Generate an RPM spec file from inline inputs
generate_spec() {
  local name="$1"
  local version="$2"
  local release="$3"
  local summary="$4"
  local description="$5"
  local license="$6"
  local url="$7"
  local arch="$8"
  local install_prefix="$9"
  local source_dir="${10}"
  local requires="${11}"
  local scripts_pre="${12}"
  local scripts_post="${13}"

  cat << SPECEOF
Name:           ${name}
Version:        ${version}
Release:        ${release}%{?dist}
Summary:        ${summary:-${name}}
License:        ${license}
${url:+URL:            ${url}}
BuildArch:      ${arch}

%description
${description:-${summary:-${name}}}

SPECEOF

  # Add Requires
  if [[ -n "${requires}" ]]; then
    while IFS= read -r req || [[ -n "${req}" ]]; do
      req="$(echo "${req}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [[ -n "${req}" ]]; then
        echo "Requires:       ${req}"
      fi
    done <<< "${requires}"
    echo ""
  fi

  # Pre-install script
  if [[ -n "${scripts_pre}" ]]; then
    echo "%pre"
    echo "${scripts_pre}"
    echo ""
  fi

  # Post-install script
  if [[ -n "${scripts_post}" ]]; then
    echo "%post"
    echo "${scripts_post}"
    echo ""
  fi

  # Install section
  echo "%install"
  echo "mkdir -p %{buildroot}${install_prefix}"
  echo "cp -a ${source_dir}/* %{buildroot}${install_prefix}/"
  echo ""

  # Files section
  echo "%files"
  generate_file_list "${source_dir}" "${install_prefix}"
}

# Set up rpmbuild directory tree
setup_rpmbuild_tree() {
  local topdir="$1"

  mkdir -p "${topdir}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
}

# Build the RPM from a spec file
run_rpmbuild() {
  local spec_file="$1"
  local topdir="$2"
  local arch="$3"

  rpmbuild -bb \
    --define "_topdir ${topdir}" \
    --target "${arch}" \
    --buildroot "${topdir}/BUILDROOT" \
    "${spec_file}" 2>&1
}

# Find the built RPM file in the output tree
find_built_rpm() {
  local topdir="$1"

  local rpm_file
  rpm_file="$(find "${topdir}/RPMS" -name '*.rpm' -type f | head -1 || true)"
  echo "${rpm_file}"
}

# Main entry point
build_rpm() {
  local spec_file="${INPUT_SPEC_FILE:-}"
  local name="${INPUT_NAME:-}"
  local version="${INPUT_VERSION:-}"
  local release="${INPUT_RELEASE:-1}"
  local arch="${INPUT_ARCH:-x86_64}"
  local summary="${INPUT_SUMMARY:-}"
  local description="${INPUT_DESCRIPTION:-}"
  local license="${INPUT_LICENSE:-MIT}"
  local url="${INPUT_URL:-}"
  local source_dir="${INPUT_SOURCE_DIR:?source-dir is required}"
  local install_prefix="${INPUT_INSTALL_PREFIX:-/usr/local/bin}"
  local output_dir="${INPUT_OUTPUT_DIR:-./rpmbuild-output}"
  local requires="${INPUT_REQUIRES:-}"
  local scripts_pre="${INPUT_SCRIPTS_PRE:-}"
  local scripts_post="${INPUT_SCRIPTS_POST:-}"

  # Resolve source_dir to absolute path
  source_dir="$(cd "${source_dir}" && pwd)"

  local topdir
  topdir="$(mktemp -d)/rpmbuild"
  setup_rpmbuild_tree "${topdir}"

  if [[ -n "${spec_file}" ]]; then
    validate_spec_file "${spec_file}"
    cp "${spec_file}" "${topdir}/SPECS/"
    spec_file="${topdir}/SPECS/$(basename "${spec_file}")"
  else
    validate_inline_inputs "${name}" "${version}" "${source_dir}"
    spec_file="${topdir}/SPECS/${name}.spec"
    generate_spec \
      "${name}" "${version}" "${release}" "${summary}" "${description}" \
      "${license}" "${url}" "${arch}" "${install_prefix}" "${source_dir}" \
      "${requires}" "${scripts_pre}" "${scripts_post}" \
      > "${spec_file}"
    echo "::notice::Generated spec file at ${spec_file}"
  fi

  echo "Building RPM..."
  run_rpmbuild "${spec_file}" "${topdir}" "${arch}"

  local rpm_path
  rpm_path="$(find_built_rpm "${topdir}")"

  if [[ -z "${rpm_path}" ]]; then
    echo "::error::RPM build produced no output" >&2
    exit 1
  fi

  # Copy to output directory
  mkdir -p "${output_dir}"
  cp "${rpm_path}" "${output_dir}/"
  local rpm_name
  rpm_name="$(basename "${rpm_path}")"
  local final_path="${output_dir}/${rpm_name}"

  echo "::notice::RPM built: ${final_path}"
  echo "rpm-path=${final_path}" >> "${GITHUB_OUTPUT}"
  echo "rpm-name=${rpm_name}" >> "${GITHUB_OUTPUT}"
}
