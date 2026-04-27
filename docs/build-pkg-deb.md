# Build DEB Package

Build Debian .deb packages from a control file or inline metadata.

## Overview

The `build-pkg-deb` action creates `.deb` packages for Debian, Ubuntu, and other dpkg-based Linux distributions. It can generate a control file from inline inputs or use a custom control file you provide.

## Usage

```yaml
# Inline metadata — generates control file automatically
- uses: asymmetric-effort/actions/actions/build-pkg-deb@v1
  with:
    name: "myapp"
    version: "1.0.0"
    summary: "My Application"
    maintainer: "Team <team@example.com>"
    source-dir: "./build/output"
    install-prefix: "/usr/local/bin"
```

```yaml
# From a control file
- uses: asymmetric-effort/actions/actions/build-pkg-deb@v1
  with:
    control-file: "./debian/control"
    source-dir: "./build/output"
```

```yaml
# With dependencies and post-install script
- uses: asymmetric-effort/actions/actions/build-pkg-deb@v1
  with:
    name: "myapp"
    version: "2.0.0"
    arch: "amd64"
    source-dir: "./dist"
    install-prefix: "/opt/myapp/bin"
    depends: "libc6, bash (>= 5.0)"
    scripts-postinst: |
      chmod +x /opt/myapp/bin/myapp
      ln -sf /opt/myapp/bin/myapp /usr/local/bin/myapp
```

```yaml
# Upload DEB as release asset
- uses: asymmetric-effort/actions/actions/build-pkg-deb@v1
  id: deb
  with:
    name: "myapp"
    version: ${{ github.ref_name }}
    source-dir: "./build"

- uses: asymmetric-effort/actions/actions/gh-release@v1
  with:
    files: ${{ steps.deb.outputs.deb-path }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `control-file` | Path to a debian/control file | No | |
| `name` | Package name (required without control-file) | No | |
| `version` | Package version (required without control-file) | No | |
| `arch` | Target architecture (amd64, arm64, all) | No | `amd64` |
| `maintainer` | Package maintainer (Name \<email\>) | No | |
| `summary` | Short package description | No | |
| `description` | Full package description | No | |
| `section` | Package section | No | `utils` |
| `priority` | Package priority | No | `optional` |
| `homepage` | Project homepage URL | No | |
| `source-dir` | Directory containing files to package | **Yes** | |
| `install-prefix` | Install prefix inside the package | No | `/usr/local/bin` |
| `output-dir` | Directory for built .deb output | No | `./debbuild-output` |
| `depends` | Comma-separated package dependencies | No | |
| `scripts-preinst` | Pre-install script content | No | |
| `scripts-postinst` | Post-install script content | No | |

## Outputs

| Output | Description |
|--------|-------------|
| `deb-path` | Path to the built .deb file |
| `deb-name` | Filename of the built .deb |

## Runner Requirements

- Requires `dpkg-deb` — available by default on all Ubuntu/Debian runners
- Does not support Windows or macOS runners

## Security Considerations

- Source files are copied into the package from `source-dir` — verify contents before packaging
- Maintainer scripts (preinst, postinst) run as root on target systems — review carefully
- The action does not sign packages; use `dpkg-sig` or `debsigs` in a separate step if required
