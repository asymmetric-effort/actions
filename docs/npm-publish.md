# NPM Publish

Publish packages to npm using OIDC trusted publisher — no long-lived `NPM_TOKEN` secret required.

## Overview

The `npm-publish` action publishes npm packages using GitHub Actions' built-in OIDC identity. npm verifies that the publish request came from an authorized GitHub repository and workflow, eliminating the need to store npm access tokens as repository secrets.

This action **requires** that the npm package already exists and has trusted publishing configured. See [Bootstrap Guide](#bootstrap-guide) below for first-time setup.

## Usage

```yaml
jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # Required for OIDC
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v6
        with:
          node-version: "24"

      - run: npm ci

      - uses: asymmetric-effort/actions/actions/npm-publish@v1
```

```yaml
# Publish a scoped package with a custom tag
- uses: asymmetric-effort/actions/actions/npm-publish@v1
  with:
    tag: "next"
    access: "public"
```

```yaml
# Publish from a subdirectory
- uses: asymmetric-effort/actions/actions/npm-publish@v1
  with:
    package-dir: "./packages/core"
```

```yaml
# Dry run to verify without publishing
- uses: asymmetric-effort/actions/actions/npm-publish@v1
  with:
    dry-run: "true"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `package-dir` | Directory containing the package.json | No | `.` |
| `tag` | npm dist-tag (latest, next, beta, etc.) | No | `latest` |
| `access` | Package access level (public or restricted) | No | `public` |
| `dry-run` | Perform a dry run without publishing | No | `false` |
| `registry` | npm registry URL | No | `https://registry.npmjs.org` |
| `provenance` | Generate provenance attestation | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The published package version |
| `package` | The published package name |
| `registry-url` | The registry URL used |

## Bootstrap Guide

This action expects that the npm package **already exists on npm** with trusted publishing configured. Follow these steps to set up a new package for the first time.

### Step 1: Create and publish the package manually

```bash
# In your project directory with a valid package.json
cd my-project

# Log into npm (you need an npm account)
npm login

# Publish the initial version (typically 0.0.1 or 1.0.0)
npm publish --access public

# Verify it's published
npm view <your-package-name>
```

For scoped packages (e.g., `@asymmetric-effort/my-pkg`):

```bash
npm publish --access public
```

### Step 2: Configure trusted publishing on npm

1. Go to [npmjs.com](https://www.npmjs.com) and log in
2. Navigate to your package's settings page:
   `https://www.npmjs.com/package/<your-package-name>/access`
3. Scroll to **Publishing access** and click **Add a trusted publisher**
4. Fill in the GitHub Actions fields:
   - **Repository owner**: your GitHub org or username (e.g., `asymmetric-effort`)
   - **Repository name**: the repo name (e.g., `my-project`)
   - **Workflow filename**: the workflow file that publishes (e.g., `release.yml`)
   - **Environment** (optional): the GitHub environment name, if used
5. Click **Add trusted publisher**

### Step 3: Configure your GitHub workflow

Create a workflow that uses this action. The critical requirements are:

```yaml
name: Publish

on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    # These permissions are REQUIRED:
    permissions:
      contents: read
      id-token: write   # Needed for OIDC token exchange
    steps:
      - uses: actions/checkout@v6

      - uses: actions/setup-node@v6
        with:
          node-version: "24"

      - run: npm ci

      - uses: asymmetric-effort/actions/actions/npm-publish@v1
        with:
          access: "public"
```

### Step 4: Bump version and release

For subsequent publishes:

```bash
# Bump the version in package.json
npm version patch  # or minor, major, or explicit version

# Push the tag
git push && git push --tags

# Create a GitHub Release from the tag (triggers the workflow)
gh release create v1.0.1 --generate-notes
```

The workflow will automatically publish to npm using OIDC — no secrets needed.

### Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `OIDC token not available` | Workflow missing `id-token: write` permission | Add `permissions: { id-token: write }` to the job |
| `403 Forbidden` | Trusted publisher not configured or misconfigured | Verify the repository, workflow filename, and environment match exactly on npmjs.com |
| `Version already published` | The version in package.json already exists on npm | Run `npm version patch` (or minor/major) to bump |
| `Package not found` | The package has never been published | Complete Step 1 above (manual first publish) |

## How It Works

1. **Validate**: Checks that Node.js/npm are installed, `package.json` has `name` and `version`, and OIDC is available
2. **Configure**: Writes an `.npmrc` file pointing to the registry with an OIDC auth token placeholder
3. **Pre-check**: Verifies the target version isn't already published (prevents accidental overwrites)
4. **Publish**: Runs `npm publish` with `--provenance` (generates a signed provenance statement linking the package to its source commit and build)

## Security Considerations

- **No long-lived secrets**: OIDC tokens are short-lived and scoped to a single workflow run
- **Provenance**: Enabled by default — creates a cryptographically signed attestation linking the published package to the exact source commit and CI workflow
- **Version guard**: Refuses to publish a version that already exists, preventing accidental overwrites
- **Registry validation**: Only HTTPS registry URLs are accepted
- **.npmrc backup**: If an existing `.npmrc` exists, it is backed up before modification

## Workflow Permissions

The calling workflow **must** have these permissions:

```yaml
permissions:
  contents: read    # To check out the code
  id-token: write   # To request the OIDC token for npm
```

Without `id-token: write`, the OIDC token endpoint will not be available and the action will fail.
