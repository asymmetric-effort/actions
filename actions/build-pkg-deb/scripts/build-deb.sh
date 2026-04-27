#!/usr/bin/env bash
# build-deb.sh — Generate control file (if needed) and build .deb package.
# Sourced by action.yml; all logic is in functions for testability.

set -euo pipefail

# Validate required inputs for inline mode
validate_inline_inputs() {
  local name="$1"
  local version="$2"
  local source_dir="$3"

  if [[ -z "${name}" ]]; then
    echo "::error::Input 'name' is required when no control-file is provided" >&2
    return 1
  fi
  if [[ -z "${version}" ]]; then
    echo "::error::Input 'version' is required when no control-file is provided" >&2
    return 1
  fi
  if [[ ! -d "${source_dir}" ]]; then
    echo "::error::source-dir does not exist: ${source_dir}" >&2
    return 1
  fi
}

# Validate a control file exists
validate_control_file() {
  local control_file="$1"

  if [[ ! -f "${control_file}" ]]; then
    echo "::error::control-file not found: ${control_file}" >&2
    return 1
  fi
}

# Calculate installed size in KB from source directory
calculate_installed_size() {
  local source_dir="$1"
  du -sk "${source_dir}" 2>/dev/null | cut -f1 || echo "0"
}

# Generate a debian/control file from inline inputs
generate_control() {
  local name="$1"
  local version="$2"
  local arch="$3"
  local maintainer="$4"
  local summary="$5"
  local description="$6"
  local section="$7"
  local priority="$8"
  local homepage="$9"
  local depends="${10}"
  local installed_size="${11}"

  echo "Package: ${name}"
  echo "Version: ${version}"
  echo "Architecture: ${arch}"
  echo "Maintainer: ${maintainer:-Unknown <unknown@example.com>}"
  echo "Installed-Size: ${installed_size}"
  echo "Section: ${section}"
  echo "Priority: ${priority}"

  if [[ -n "${depends}" ]]; then
    echo "Depends: ${depends}"
  fi

  if [[ -n "${homepage}" ]]; then
    echo "Homepage: ${homepage}"
  fi

  echo "Description: ${summary:-${name}}"

  # Long description: indent each line with a single space
  if [[ -n "${description}" ]]; then
    while IFS= read -r line || [[ -n "${line}" ]]; do
      if [[ -z "${line}" ]]; then
        echo " ."
      else
        echo " ${line}"
      fi
    done <<< "${description}"
  fi
}

# Set up the DEB package directory structure
setup_deb_tree() {
  local pkg_dir="$1"
  local source_dir="$2"
  local install_prefix="$3"

  # Create DEBIAN directory
  mkdir -p "${pkg_dir}/DEBIAN"

  # Create install target and copy files
  local target_dir="${pkg_dir}${install_prefix}"
  mkdir -p "${target_dir}"

  # Copy files iteratively using find (no recursion)
  while IFS= read -r file; do
    local rel_path="${file#"${source_dir}"}"
    local dest="${target_dir}${rel_path}"
    local dest_dir
    dest_dir="$(dirname "${dest}")"
    mkdir -p "${dest_dir}"
    cp -p "${file}" "${dest}"
  done < <(find "${source_dir}" -type f 2>/dev/null)

  # Copy directories (preserve structure)
  while IFS= read -r dir; do
    local rel_path="${dir#"${source_dir}"}"
    if [[ -n "${rel_path}" ]]; then
      mkdir -p "${target_dir}${rel_path}"
    fi
  done < <(find "${source_dir}" -type d 2>/dev/null)
}

# Write a maintainer script (preinst, postinst, etc.)
write_maintainer_script() {
  local pkg_dir="$1"
  local script_name="$2"
  local content="$3"

  if [[ -n "${content}" ]]; then
    local script_path="${pkg_dir}/DEBIAN/${script_name}"
    {
      echo "#!/usr/bin/env bash"
      echo "set -euo pipefail"
      echo "${content}"
    } > "${script_path}"
    chmod 0755 "${script_path}"
  fi
}

# Build the .deb file using dpkg-deb
run_dpkg_deb() {
  local pkg_dir="$1"
  local output_path="$2"

  dpkg-deb --build --root-owner-group "${pkg_dir}" "${output_path}" 2>&1
}

# Main entry point
build_deb() {
  local control_file="${INPUT_CONTROL_FILE:-}"
  local name="${INPUT_NAME:-}"
  local version="${INPUT_VERSION:-}"
  local arch="${INPUT_ARCH:-amd64}"
  local maintainer="${INPUT_MAINTAINER:-}"
  local summary="${INPUT_SUMMARY:-}"
  local description="${INPUT_DESCRIPTION:-}"
  local section="${INPUT_SECTION:-utils}"
  local priority="${INPUT_PRIORITY:-optional}"
  local homepage="${INPUT_HOMEPAGE:-}"
  local source_dir="${INPUT_SOURCE_DIR:?source-dir is required}"
  local install_prefix="${INPUT_INSTALL_PREFIX:-/usr/local/bin}"
  local output_dir="${INPUT_OUTPUT_DIR:-./debbuild-output}"
  local depends="${INPUT_DEPENDS:-}"
  local scripts_preinst="${INPUT_SCRIPTS_PREINST:-}"
  local scripts_postinst="${INPUT_SCRIPTS_POSTINST:-}"

  # Resolve source_dir to absolute path
  source_dir="$(cd "${source_dir}" && pwd)"

  local pkg_dir
  pkg_dir="$(mktemp -d)/debpkg"

  # Set up directory tree with files
  setup_deb_tree "${pkg_dir}" "${source_dir}" "${install_prefix}"

  if [[ -n "${control_file}" ]]; then
    validate_control_file "${control_file}"
    cp "${control_file}" "${pkg_dir}/DEBIAN/control"
  else
    validate_inline_inputs "${name}" "${version}" "${source_dir}"
    local installed_size
    installed_size="$(calculate_installed_size "${source_dir}")"
    generate_control \
      "${name}" "${version}" "${arch}" "${maintainer}" "${summary}" \
      "${description}" "${section}" "${priority}" "${homepage}" \
      "${depends}" "${installed_size}" \
      > "${pkg_dir}/DEBIAN/control"
    echo "::notice::Generated control file"
  fi

  # Write maintainer scripts
  write_maintainer_script "${pkg_dir}" "preinst" "${scripts_preinst}"
  write_maintainer_script "${pkg_dir}" "postinst" "${scripts_postinst}"

  # Determine output filename
  if [[ -n "${name}" && -n "${version}" ]]; then
    local deb_name="${name}_${version}_${arch}.deb"
  else
    # Extract name/version/arch from control file
    local ctrl_name ctrl_version ctrl_arch
    ctrl_name="$(grep -oP '^Package:\s*\K\S+' "${pkg_dir}/DEBIAN/control" | head -1)"
    ctrl_version="$(grep -oP '^Version:\s*\K\S+' "${pkg_dir}/DEBIAN/control" | head -1)"
    ctrl_arch="$(grep -oP '^Architecture:\s*\K\S+' "${pkg_dir}/DEBIAN/control" | head -1)"
    local deb_name="${ctrl_name}_${ctrl_version}_${ctrl_arch}.deb"
  fi

  mkdir -p "${output_dir}"
  local output_path="${output_dir}/${deb_name}"

  echo "Building DEB: ${deb_name}..."
  run_dpkg_deb "${pkg_dir}" "${output_path}"

  if [[ ! -f "${output_path}" ]]; then
    echo "::error::DEB build produced no output" >&2
    exit 1
  fi

  echo "::notice::DEB built: ${output_path}"
  echo "deb-path=${output_path}" >> "${GITHUB_OUTPUT}"
  echo "deb-name=${deb_name}" >> "${GITHUB_OUTPUT}"

  # Cleanup
  rm -rf "$(dirname "${pkg_dir}")"
}
