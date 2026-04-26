# Asymmetric Effort Actions

Secure, self-contained GitHub Actions for the [Asymmetric Effort](https://github.com/asymmetric-effort) organization.

## Overview

This project provides clean-room implementations of commonly used GitHub Actions, eliminating reliance on third-party actions to secure the software supply chain. Each action is minimal, tightly focused, and thoroughly tested.

All actions are published from a single monorepo at [github.com/asymmetric-effort/actions](https://github.com/asymmetric-effort/actions) and follow [semantic versioning](https://semver.org/).

## Available Actions

| Action | Description | Type | Documentation |
|--------|-------------|------|---------------|
| [setup-bun](./setup-bun.md) | Install and configure the Bun JavaScript runtime | Node20 (TypeScript) | [Full docs](./setup-bun.md) |
| [fossa-scan](./fossa-scan.md) | Run FOSSA license compliance and security scanning | Composite | [Full docs](./fossa-scan.md) |
| [gh-release](./gh-release.md) | Create or update GitHub Releases with asset uploads | Node20 (TypeScript) | [Full docs](./gh-release.md) |

## Quick Start

Reference actions from this repository using the full path with a version tag:

```yaml
# Install the Bun runtime
- uses: asymmetric-effort/actions/actions/setup-bun@v1
  with:
    bun-version: "latest"

# Run FOSSA license compliance scanning
- uses: asymmetric-effort/actions/actions/fossa-scan@v1
  with:
    api-key: ${{ secrets.FOSSA_API_KEY }}

# Create a GitHub Release with assets
- uses: asymmetric-effort/actions/actions/gh-release@v1
  with:
    tag_name: ${{ github.ref_name }}
    files: |
      dist/*.tar.gz
      dist/*.zip
```

## Versioning

This project uses semantic versioning (`v1.0.0`). Pin your workflows to a major version tag for stability:

```yaml
- uses: asymmetric-effort/actions/actions/setup-bun@v1
```

You can also pin to a specific patch version if needed:

```yaml
- uses: asymmetric-effort/actions/actions/setup-bun@v1.0.0
```

## Repository Structure

```
actions/
  setup-bun/       # Bun runtime installer (Node20, TypeScript)
  fossa-scan/      # FOSSA scanning (composite action)
  gh-release/      # GitHub Releases (Node20, TypeScript)
docs/              # Documentation (this directory)
scripts/           # Build and maintenance scripts
site/              # Documentation site source
```

## Additional Resources

- [Security Practices](./security.md) -- how we secure the supply chain
- [Contributing Guide](./contributing.md) -- how to contribute to this project
- [MIT License](https://github.com/asymmetric-effort/actions/blob/main/LICENSE)
