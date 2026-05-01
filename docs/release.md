# Release

Create or update GitHub Releases with full-featured release management.

## Overview

The `release` action is a complete, self-contained replacement for `softprops/action-gh-release` with full feature parity. It creates or updates GitHub Releases, uploads assets via glob patterns, supports draft/prerelease workflows, auto-generated release notes, discussion linking, and body appending.

## Usage

```yaml
# Basic release on tag push
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    tag_name: ${{ github.ref_name }}
    generate_release_notes: "true"
```

```yaml
# Upload build artifacts
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    files: |
      dist/*.tar.gz
      dist/*.zip
      dist/*.deb
```

```yaml
# Release notes from file
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    body_path: CHANGELOG.md
    files: dist/*
```

```yaml
# Draft prerelease
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    draft: "true"
    prerelease: "true"
    files: build/output/*
```

```yaml
# Auto-generated notes with base tag comparison
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    generate_release_notes: "true"
    previous_tag: "v1.0.0"
```

```yaml
# Append to existing release notes
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    body: "Additional build artifacts added."
    append_body: "true"
    files: dist/extra-*
```

```yaml
# Create discussion for the release
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    generate_release_notes: "true"
    discussion_category_name: "Releases"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `tag_name` | Git tag for the release | No | `${{ github.ref_name }}` |
| `name` | Release name (defaults to tag) | No | |
| `body` | Release notes text | No | |
| `body_path` | Path to file with release notes | No | |
| `append_body` | Append body to existing notes | No | `false` |
| `draft` | Create as draft | No | `false` |
| `prerelease` | Mark as prerelease | No | `false` |
| `files` | Newline-delimited glob patterns | No | |
| `working_directory` | Base dir for file globs | No | `${{ github.workspace }}` |
| `overwrite_files` | Replace existing assets | No | `true` |
| `fail_on_unmatched_files` | Fail if glob matches nothing | No | `false` |
| `preserve_order` | Upload sequentially | No | `true` |
| `target_commitish` | Commitish for tag creation | No | |
| `generate_release_notes` | Auto-generate notes | No | `false` |
| `previous_tag` | Base tag for auto-generated notes | No | |
| `discussion_category_name` | Link a discussion | No | |
| `make_latest` | Latest release flag | No | |
| `token` | GitHub token | No | `${{ github.token }}` |
| `repository` | Target repo (owner/repo) | No | `${{ github.repository }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `url` | HTML URL of the release |
| `id` | Release ID |
| `upload_url` | Upload URL for additional assets |
| `assets` | JSON array of uploaded asset metadata |

## Feature Parity with softprops/action-gh-release

| Feature | Supported |
|---------|-----------|
| Create release | Yes |
| Update existing release | Yes |
| Upload assets (glob) | Yes |
| Overwrite assets | Yes |
| Draft / prerelease | Yes |
| Auto-generated notes | Yes |
| Previous tag comparison | Yes |
| Body from file | Yes |
| Append body | Yes |
| Discussion linking | Yes |
| Make latest | Yes |
| Fail on unmatched | Yes |
| Cross-repo releases | Yes |

## Permissions

```yaml
permissions:
  contents: write
```

Add `discussions: write` if using `discussion_category_name`.

## Security

- Zero third-party dependencies — pure bash composite action
- Uses `gh` CLI for all GitHub API interactions
- Token is passed via environment variable, never in command arguments
