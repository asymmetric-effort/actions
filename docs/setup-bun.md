# setup-bun

Install and configure the [Bun](https://bun.sh/) JavaScript runtime in your GitHub Actions workflow.

## Description

This action downloads and installs a specified version of the Bun runtime, adds it to `PATH`, and optionally caches the binary for faster subsequent runs. It supports version resolution from `package.json` or `.tool-versions` files, and includes a post-run step for cache management.

**Action type:** Node20 (TypeScript)

## Usage

### Basic

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-bun@v1
  - run: bun --version
```

### Specific version

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-bun@v1
    with:
      bun-version: "1.1.0"
```

### Read version from file

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-bun@v1
    with:
      bun-version-file: "package.json"
```

### Canary builds

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-bun@v1
    with:
      bun-version: "canary"
      no-cache: "true"
```

### Using outputs

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-bun@v1
    id: setup
  - run: echo "Installed Bun ${{ steps.setup.outputs.bun-version }} at ${{ steps.setup.outputs.bun-path }}"
  - run: echo "Cache hit: ${{ steps.setup.outputs.cache-hit }}"
```

### Complete workflow example

```yaml
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: asymmetric-effort/actions/actions/setup-bun@v1
        with:
          bun-version: "1.1.0"

      - run: bun install
      - run: bun test
      - run: bun run build
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `bun-version` | Bun version to install. Accepts a semver string (e.g. `1.1.0`), `latest`, or `canary`. | No | `latest` |
| `bun-version-file` | File to read the Bun version from (e.g. `package.json`, `.tool-versions`). When set, this takes precedence over `bun-version`. | No | |
| `no-cache` | Disable caching of the Bun binary. Set to `"true"` to always download fresh. Recommended for canary builds. | No | `false` |
| `token` | GitHub token used for API requests to avoid rate limits when resolving versions. | No | `${{ github.token }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `bun-version` | The exact Bun version that was installed (e.g. `1.1.0`). |
| `bun-path` | Absolute path to the installed Bun binary. |
| `cache-hit` | `"true"` if the Bun binary was restored from cache, `"false"` otherwise. |

## Version Resolution

The action resolves the Bun version in the following order of precedence:

1. **`bun-version-file`** -- If specified, the version is read from the given file. Supported file formats:
   - `package.json` (reads `engines.bun` or a similar field)
   - `.tool-versions` (reads the `bun` entry)
2. **`bun-version`** -- The explicit version string. Accepts:
   - Exact semver: `1.1.0`
   - Latest stable: `latest`
   - Latest canary: `canary`
3. **Default** -- If neither input is provided, `latest` is used.

## Caching

By default, the Bun binary is cached using the GitHub Actions cache to speed up subsequent runs. The cache key is derived from the resolved Bun version and the runner OS/architecture.

To disable caching (e.g., for canary builds that change frequently), set `no-cache: "true"`.

The action includes a `post` step (`dist/post.js`) that runs after the workflow job completes to save the cache if needed.

## Runner Compatibility

| Runner | Supported |
|--------|-----------|
| `ubuntu-latest` | Yes |
| `ubuntu-22.04` | Yes |
| `ubuntu-20.04` | Yes |
| `macos-latest` | Yes |
| `macos-14` (ARM64) | Yes |
| `windows-latest` | Yes |

Requires Node.js 20 (provided by the GitHub Actions runner).

## Security Considerations

- The `token` input defaults to the automatic `GITHUB_TOKEN`, which is scoped to the current repository and expires after the workflow run. No additional permissions are needed.
- Bun binaries are downloaded from the official Bun GitHub releases.
- Caching is handled through the GitHub Actions cache, which is scoped to the repository and branch.
- See [Security Practices](./security.md) for project-wide security details.
