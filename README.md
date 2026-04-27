# Asymmetric Effort Actions

Secure, self-contained GitHub Actions for the [Asymmetric Effort](https://github.com/asymmetric-effort) organization.

## Overview

This project provides clean-room implementations of commonly used GitHub Actions, eliminating reliance on third-party actions to secure our software supply chain. Each action is minimal, tightly focused, and thoroughly tested.

## Actions

| Action | Description | Status |
|--------|-------------|--------|
| [setup-bun](./actions/setup-bun) | Install and configure the Bun runtime | Active |
| [fossa-scan](./actions/fossa-scan) | Run FOSSA license compliance scanning | Active |
| [gh-release](./actions/gh-release) | Create or update GitHub Releases with asset uploads | Active |
| [go-tooling](./actions/go-tooling) | Install Go toolchain with govulncheck and caching | Active |
| [build-pkg-rpm](./actions/build-pkg-rpm) | Build RPM packages from spec or inline metadata | Active |
| [build-pkg-deb](./actions/build-pkg-deb) | Build DEB packages from control file or inline metadata | Active |
| [npm-publish](./actions/npm-publish) | Publish to npm using OIDC trusted publisher | Active |

## Usage

Reference actions from this repository using the `asymmetric-effort/actions` path:

```yaml
- uses: asymmetric-effort/actions/actions/setup-bun@main
  with:
    bun-version: "latest"

- uses: asymmetric-effort/actions/actions/fossa-scan@main
  with:
    api-key: ${{ secrets.FOSSA_API_KEY }}

- uses: asymmetric-effort/actions/actions/gh-release@main
  with:
    tag_name: ${{ github.ref_name }}
    files: |
      dist/*.tar.gz
      dist/*.zip
```

## Documentation

- Full documentation: [actions.asymmetric-effort.com](https://actions.asymmetric-effort.com)
- Markdown docs: [docs/](./docs/)

## Security

- All actions undergo exhaustive security review
- Dependabot monitors dependency updates
- CodeQL scans for vulnerabilities
- No third-party action dependencies (only `actions/*` and `github/*` official actions)

## License

MIT - See [LICENSE](./LICENSE)
