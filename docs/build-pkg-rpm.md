# Build RPM Package

Build RPM packages from a spec file or inline metadata.

## Overview

The `build-pkg-rpm` action creates RPM packages for Red Hat, CentOS, Fedora, and other RPM-based Linux distributions. It can generate a spec file from inline inputs or use a custom spec file you provide.

## Usage

```yaml
# Inline metadata — generates spec file automatically
- uses: asymmetric-effort/actions/actions/build-pkg-rpm@v1
  with:
    name: "myapp"
    version: "1.0.0"
    summary: "My Application"
    source-dir: "./build/output"
    install-prefix: "/usr/local/bin"
```

```yaml
# From a spec file
- uses: asymmetric-effort/actions/actions/build-pkg-rpm@v1
  with:
    spec-file: "./packaging/myapp.spec"
    source-dir: "./build/output"
```

```yaml
# With dependencies and scripts
- uses: asymmetric-effort/actions/actions/build-pkg-rpm@v1
  with:
    name: "myapp"
    version: "2.0.0"
    arch: "x86_64"
    source-dir: "./dist"
    install-prefix: "/opt/myapp/bin"
    requires: |
      bash
      curl >= 7.0
    scripts-post: |
      chmod +x /opt/myapp/bin/myapp
```

```yaml
# Upload RPM as release asset
- uses: asymmetric-effort/actions/actions/build-pkg-rpm@v1
  id: rpm
  with:
    name: "myapp"
    version: ${{ github.ref_name }}
    source-dir: "./build"

- uses: asymmetric-effort/actions/actions/gh-release@v1
  with:
    files: ${{ steps.rpm.outputs.rpm-path }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `spec-file` | Path to an RPM .spec file | No | |
| `name` | Package name (required without spec-file) | No | |
| `version` | Package version (required without spec-file) | No | |
| `release` | Package release number | No | `1` |
| `arch` | Target architecture | No | `x86_64` |
| `summary` | One-line package summary | No | |
| `description` | Full package description | No | |
| `license` | Package license | No | `MIT` |
| `url` | Project URL | No | |
| `source-dir` | Directory containing files to package | **Yes** | |
| `install-prefix` | Install prefix inside the RPM | No | `/usr/local/bin` |
| `output-dir` | Directory for built RPM output | No | `./rpmbuild-output` |
| `requires` | Newline-delimited package dependencies | No | |
| `scripts-pre` | Pre-install script content | No | |
| `scripts-post` | Post-install script content | No | |

## Outputs

| Output | Description |
|--------|-------------|
| `rpm-path` | Path to the built RPM file |
| `rpm-name` | Filename of the built RPM |

## Runner Requirements

- Requires `rpmbuild` — automatically installed via `apt-get`, `dnf`, or `yum` if missing
- Supported on Ubuntu, Debian, Fedora, CentOS, and RHEL runners

## Security Considerations

- Source files are copied into the package from `source-dir` — verify contents before packaging
- Pre/post-install scripts run as root on target systems — review carefully
- The action does not sign packages; use GPG signing in a separate step if required
