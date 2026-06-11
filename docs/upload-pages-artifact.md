# Upload Pages Artifact

Package and upload a directory as a GitHub Pages deployment artifact.

## Overview

The `upload-pages-artifact` action packages a directory into a tar.gz archive and uploads it as a GitHub Pages artifact named `github-pages`. It is a drop-in replacement for `actions/upload-pages-artifact@v4` with zero third-party dependencies in the packaging step.

The action automatically creates a `.nojekyll` file in the directory if one does not already exist, ensuring GitHub Pages skips Jekyll processing.

## Usage

```yaml
# Basic usage — upload current directory
- uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1

# Upload a specific build directory
- uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1
  with:
    path: ./dist

# Custom retention period
- uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1
  with:
    path: ./build
    retention-days: "7"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `path` | Directory containing the static files to deploy | No | `.` |
| `retention-days` | Number of days to retain the artifact | No | `1` |

## Outputs

| Output | Description |
|--------|-------------|
| `artifact-id` | The ID of the uploaded artifact |

## Permissions

```yaml
permissions:
  pages: write
  id-token: write
```

## How It Works

1. **Validate** — Checks that the path exists and is a directory, and that retention-days is a positive integer.
2. **Package** — Ensures a `.nojekyll` file exists, then creates a `artifact.tar.gz` archive with the directory contents at the root level (no parent directory wrapper).
3. **Upload** — Uses `actions/upload-artifact@v4` to upload the archive as `github-pages`.
