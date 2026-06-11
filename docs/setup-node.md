# setup-node

Install and configure [Node.js](https://nodejs.org/) in your GitHub Actions workflow.

## Description

This action downloads and installs a specified version of Node.js, adds it to `PATH`, and optionally caches the package manager store for faster subsequent runs. It supports version resolution from `.nvmrc`, `.node-version`, and `package.json` files, as well as LTS codename specifiers.

**Replaces:** `actions/setup-node@v6.4.0`

## Usage

### Basic

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-node@v1
    with:
      node-version: "20"
```

### Read version from file

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-node@v1
    with:
      node-version-file: ".nvmrc"
```

### With npm caching

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-node@v1
    with:
      node-version: "20"
      cache: "npm"
  - run: npm ci
```

### LTS version

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-node@v1
    with:
      node-version: "lts/*"
```

### Private registry

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-node@v1
    with:
      node-version: "20"
      registry-url: "https://npm.pkg.github.com"
  - run: npm ci
    env:
      NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### Using outputs

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-node@v1
    id: setup
    with:
      node-version: "20"
      cache: "npm"
  - run: echo "Installed Node.js ${{ steps.setup.outputs.node-version }}"
  - run: echo "Cache hit: ${{ steps.setup.outputs.cache-hit }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `node-version` | Node.js version to install. Accepts a semver string (e.g. `20.11.0`), `lts/*`, `lts/iron`, or `latest`. | No | `""` (defaults to latest LTS) |
| `node-version-file` | File to read the Node.js version from (e.g. `.nvmrc`, `.node-version`, `package.json`). | No | `""` |
| `cache` | Package manager to cache (`npm`, `yarn`, or `pnpm`). Leave empty to disable caching. | No | `""` |
| `registry-url` | npm registry URL to configure in `.npmrc`. | No | `""` |
| `architecture` | Target architecture for the Node.js binary (`x64` or `arm64`). | No | `x64` |
| `token` | GitHub token used for API requests. | No | `${{ github.token }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `node-version` | The exact Node.js version that was installed (e.g. `20.11.0`). |
| `cache-hit` | `"true"` if the package manager cache was restored, `"false"` otherwise. |

## Version Resolution

The action resolves the Node.js version in the following order of precedence:

1. **`node-version`** -- If provided, this explicit version is used. Supports:
   - Exact semver: `20.11.0`
   - LTS codename: `lts/iron`, `lts/hydrogen`
   - Latest LTS: `lts/*`
   - Latest current: `latest`
2. **`node-version-file`** -- If `node-version` is empty and a file is specified, the version is read from:
   - `.nvmrc`
   - `.node-version`
   - `package.json` (reads `engines.node`)
3. **Default** -- If neither input is provided, the latest LTS version is installed.

## Caching

When `cache` is set to `npm`, `yarn`, or `pnpm`, the action restores and saves the package manager cache directory. The cache key is derived from the lockfile hash and runner OS.

| Manager | Lockfile | Cache Directory |
|---------|----------|-----------------|
| npm | `package-lock.json` | `~/.npm` |
| yarn | `yarn.lock` | `$(yarn cache dir)` |
| pnpm | `pnpm-lock.yaml` | `$(pnpm store path)` |

## Runner Compatibility

| Runner | Supported |
|--------|-----------|
| `ubuntu-latest` | Yes |
| `ubuntu-22.04` | Yes |
| `ubuntu-24.04` | Yes |
| `macos-latest` | Yes |
| `macos-14` (ARM64) | Yes |
| `windows-latest` | Yes |

## Security Considerations

- The `token` input defaults to the automatic `GITHUB_TOKEN`, which is scoped to the current repository and expires after the workflow run.
- Node.js binaries are downloaded from the official Node.js distribution at `nodejs.org`.
- Caching is handled through the GitHub Actions cache, which is scoped to the repository and branch.
