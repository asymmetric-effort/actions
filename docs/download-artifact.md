# download-artifact

Download artifacts from a GitHub Actions workflow run.

## Description

This composite action downloads artifacts that were uploaded during a workflow run using the GitHub Actions artifact API. It replaces `actions/download-artifact@v8` with a self-contained composite action that supports downloading single or multiple artifacts and extracting them to a specified directory.

**Action type:** Composite

## Usage

### Basic

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/download-artifact@v1
    with:
      name: "build-output"
```

### Download to a specific directory

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/download-artifact@v1
    with:
      name: "build-output"
      path: "artifacts/build"
```

### Merge multiple artifacts

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/download-artifact@v1
    with:
      name: "build-"
      path: "artifacts"
      merge-multiple: "true"
```

### Download from a different workflow run

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/download-artifact@v1
    with:
      name: "release-assets"
      run-id: "123456789"
      github-token: ${{ secrets.PAT }}
```

### Using outputs

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/download-artifact@v1
    id: download
    with:
      name: "build-output"
  - run: echo "Downloaded to ${{ steps.download.outputs.download-path }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Name of the artifact to download. | Yes | — |
| `path` | Directory to extract the artifact into. | No | `.` |
| `merge-multiple` | If `true`, download all artifacts whose names match the `name` pattern. | No | `false` |
| `run-id` | Workflow run ID to download artifacts from. Defaults to the current run. | No | `""` |
| `github-token` | GitHub token for API authentication. | No | `${{ github.token }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `download-path` | Absolute path to the directory where artifacts were extracted. |

## How It Works

1. **Validation** — Ensures the artifact name is non-empty, the target path is valid (creates it if needed), and `merge-multiple` is a valid boolean.
2. **API Query** — Queries the GitHub Actions REST API for artifacts associated with the specified workflow run.
3. **Download** — Downloads the artifact archive using Bearer token authentication.
4. **Extraction** — Extracts the zip archive into the target directory.
5. **Output** — Sets the `download-path` output to the absolute path of the extraction directory.

When `merge-multiple` is `true`, the action downloads all artifacts whose names match the provided `name` as a regex pattern and extracts them all into the same target directory.

## Security Considerations

- The `github-token` input defaults to the automatic `GITHUB_TOKEN`, which is scoped to the current repository and expires after the workflow run.
- When downloading artifacts from a different workflow run, a personal access token (PAT) with appropriate permissions may be required.
- See [Security Practices](./security.md) for project-wide security details.
