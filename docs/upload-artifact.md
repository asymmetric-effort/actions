# Upload Artifact

Upload build artifacts from a workflow run.

## Overview

The `upload-artifact` action packages files into a compressed archive and uploads them as a GitHub Actions artifact. It is a drop-in replacement for `actions/upload-artifact@v4` implemented as a composite action with zero third-party dependencies.

The action supports glob patterns, multiple paths, configurable compression, retention policies, and overwriting existing artifacts.

## Usage

```yaml
# Upload a single directory
- uses: asymmetric-effort/actions/actions/upload-artifact@v1
  with:
    name: my-build
    path: ./dist

# Upload with glob pattern
- uses: asymmetric-effort/actions/actions/upload-artifact@v1
  with:
    name: test-results
    path: |
      ./coverage/**
      ./test-results/*.xml

# Upload with custom retention and compression
- uses: asymmetric-effort/actions/actions/upload-artifact@v1
  with:
    name: release-assets
    path: ./build/output
    retention-days: "30"
    compression-level: "9"

# Overwrite an existing artifact
- uses: asymmetric-effort/actions/actions/upload-artifact@v1
  with:
    name: latest-build
    path: ./dist
    overwrite: "true"

# Fail the workflow if no files are found
- uses: asymmetric-effort/actions/actions/upload-artifact@v1
  with:
    name: required-output
    path: ./output/*.bin
    if-no-files-found: "error"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Name of the artifact | Yes | — |
| `path` | File, directory, or wildcard pattern for files to upload | Yes | — |
| `retention-days` | Number of days to retain the artifact (1-90, empty = repo default) | No | `""` |
| `if-no-files-found` | Behavior when no files are found (`warn`, `error`, `ignore`) | No | `warn` |
| `compression-level` | zlib compression level (0-9) | No | `6` |
| `overwrite` | Whether to overwrite an existing artifact with the same name | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `artifact-id` | The ID of the uploaded artifact |
| `artifact-url` | URL to download the artifact |

## How It Works

1. **Validate** — Checks that the artifact name and path are provided, that `if-no-files-found` is a valid option, and that `compression-level` is between 0 and 9.
2. **Resolve** — Expands glob patterns and directory references into a flat list of files to upload. Handles the `if-no-files-found` policy if no files match.
3. **Archive** — Creates a tar.gz archive of the matched files at the specified compression level.
4. **Upload** — Uses the GitHub Actions Runtime API to create an artifact container, upload the archive in chunks, and finalize the artifact.
5. **Output** — Sets `artifact-id` and `artifact-url` as step outputs for downstream use.
