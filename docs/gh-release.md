# gh-release

Create or update GitHub Releases with asset uploads.

## Description

This action creates a new GitHub Release (or updates an existing one) for a given tag, optionally uploading file assets using glob patterns. It supports draft and prerelease flags, auto-generated release notes, cross-repository releases, and asset overwrite behavior.

**Action type:** Node20 (TypeScript)

## Usage

### Basic release on tag push

```yaml
name: Release
on:
  push:
    tags: ["v*"]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - uses: asymmetric-effort/actions/actions/gh-release@v1
        with:
          tag_name: ${{ github.ref_name }}
```

### Release with file assets

```yaml
steps:
  - uses: actions/checkout@v4
  - run: make build
  - uses: asymmetric-effort/actions/actions/gh-release@v1
    with:
      tag_name: ${{ github.ref_name }}
      files: |
        dist/*.tar.gz
        dist/*.zip
        dist/checksums.txt
```

### Draft release with custom notes

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/gh-release@v1
    with:
      tag_name: ${{ github.ref_name }}
      name: "Release ${{ github.ref_name }}"
      body: |
        ## Changes
        - Feature A
        - Bug fix B
      draft: "true"
```

### Release notes from a file

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/gh-release@v1
    with:
      tag_name: ${{ github.ref_name }}
      body_path: CHANGELOG.md
```

### Auto-generated release notes

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/gh-release@v1
    with:
      tag_name: ${{ github.ref_name }}
      generate_release_notes: "true"
```

### Prerelease

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/gh-release@v1
    with:
      tag_name: ${{ github.ref_name }}
      prerelease: "true"
```

### Strict file matching

```yaml
steps:
  - uses: actions/checkout@v4
  - run: make build
  - uses: asymmetric-effort/actions/actions/gh-release@v1
    with:
      tag_name: ${{ github.ref_name }}
      files: |
        dist/myapp-linux-amd64
        dist/myapp-darwin-amd64
      fail_on_unmatched_files: "true"
```

### Using outputs

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/gh-release@v1
    id: release
    with:
      tag_name: ${{ github.ref_name }}
      files: dist/*
  - run: |
      echo "Release URL: ${{ steps.release.outputs.url }}"
      echo "Release ID: ${{ steps.release.outputs.id }}"
      echo "Upload URL: ${{ steps.release.outputs.upload_url }}"
      echo "Assets: ${{ steps.release.outputs.assets }}"
```

### Complete workflow example

```yaml
name: Release
on:
  push:
    tags: ["v*"]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make build
      - uses: actions/upload-artifact@v4
        with:
          name: binaries
          path: dist/

  release:
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: binaries
          path: dist/

      - uses: asymmetric-effort/actions/actions/gh-release@v1
        with:
          tag_name: ${{ github.ref_name }}
          name: "${{ github.ref_name }}"
          generate_release_notes: "true"
          files: |
            dist/*.tar.gz
            dist/*.zip
            dist/checksums.txt
          fail_on_unmatched_files: "true"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `tag_name` | Git tag for the release. | No | `${{ github.ref_name }}` |
| `name` | Display name of the release. Defaults to the tag name if not set. | No | |
| `body` | Release notes as inline text. Mutually exclusive with `body_path`. | No | |
| `body_path` | Path to a file containing release notes. Mutually exclusive with `body`. | No | |
| `draft` | Create the release as a draft (not published). | No | `false` |
| `prerelease` | Mark the release as a prerelease. | No | `false` |
| `files` | Newline-delimited glob patterns for assets to upload. Each line is a separate pattern (e.g. `dist/*.tar.gz`). | No | |
| `working_directory` | Base directory for resolving file glob patterns. | No | `${{ github.workspace }}` |
| `overwrite_files` | Replace existing assets with the same filename when updating a release. | No | `true` |
| `fail_on_unmatched_files` | Fail the action if any glob pattern matches zero files. | No | `false` |
| `target_commitish` | Commit SHA or branch name for tag creation. Only used when creating a new tag. | No | |
| `generate_release_notes` | Auto-generate release notes using the GitHub API (based on merged PRs and commits since the last release). | No | `false` |
| `make_latest` | Control whether this release is marked as "Latest" on GitHub. Accepts `true`, `false`, or `legacy`. | No | |
| `token` | GitHub token for API authentication. Requires `contents: write` permission. | No | `${{ github.token }}` |
| `repository` | Target repository in `owner/repo` format. Allows creating releases in a different repository (token must have access). | No | `${{ github.repository }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `url` | HTML URL of the created or updated release (e.g. `https://github.com/owner/repo/releases/tag/v1.0.0`). |
| `id` | Numeric ID of the release, useful for subsequent API calls. |
| `upload_url` | Upload URL template for adding more assets via the GitHub Releases API. |
| `assets` | JSON array of uploaded asset metadata. Each element contains fields like `name`, `size`, `browser_download_url`, etc. |

## Behavior Details

### Release creation vs. update

- If a release already exists for the given `tag_name`, the action **updates** it with the provided inputs (name, body, draft/prerelease flags, etc.).
- If no release exists, a new one is **created**.

### Asset uploads

- The `files` input accepts one glob pattern per line.
- Globs are resolved relative to `working_directory`.
- When `overwrite_files` is `true` (the default), existing assets with the same filename are deleted before uploading the new version.
- When `fail_on_unmatched_files` is `true`, the action fails if any pattern matches zero files. This is useful for catching build failures where expected artifacts are missing.

### Release notes

- `body` and `body_path` are mutually exclusive. If both are provided, `body` takes precedence.
- When `generate_release_notes` is `true`, GitHub automatically generates notes based on PRs merged and commits since the previous release. This can be combined with `body` to prepend custom text.

## Permissions

The workflow job must have `contents: write` permission:

```yaml
jobs:
  release:
    permissions:
      contents: write
```

When using the default `GITHUB_TOKEN`, this allows creating releases and uploading assets in the current repository. For cross-repository releases, provide a `token` (e.g. a PAT or GitHub App token) with write access to the target repository.

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

- The `token` input defaults to `GITHUB_TOKEN`, which is automatically scoped to the current repository and expires after the workflow run.
- For cross-repository releases, use a fine-grained PAT or GitHub App installation token with the minimum required permissions (`contents: write` on the target repo).
- Never hardcode tokens in workflow files. Always use GitHub secrets.
- See [Security Practices](./security.md) for project-wide security details.
