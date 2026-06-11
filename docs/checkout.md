# checkout

Check out repository source code in your GitHub Actions workflow.

## Description

This composite action clones a repository and checks out a specific ref (branch, tag, or SHA). It replaces `actions/checkout@v6.0.3` with a self-contained composite action that supports shallow clones, submodules, Git LFS, workspace cleaning, and credential management.

**Action type:** Composite

## Usage

### Basic

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1
  - run: ls -la
```

### Specific branch or tag

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1
    with:
      ref: "v2.0.0"
```

### Full clone with submodules

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1
    with:
      fetch-depth: "0"
      submodules: "recursive"
```

### Checkout a different repository

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1
    with:
      repository: "other-org/other-repo"
      token: ${{ secrets.PAT }}
      path: "other-repo"
```

### With Git LFS

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1
    with:
      lfs: "true"
```

### Using outputs

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1
    id: co
  - run: echo "Checked out ref ${{ steps.co.outputs.ref }} at commit ${{ steps.co.outputs.commit }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `repository` | Repository name with owner (e.g., `owner/repo`). | No | `${{ github.repository }}` |
| `ref` | Branch, tag, or SHA to checkout. If empty, uses the triggering event's ref. | No | `""` |
| `token` | GitHub token for authentication. | No | `${{ github.token }}` |
| `path` | Relative path under `$GITHUB_WORKSPACE` to place the repository. | No | `.` |
| `fetch-depth` | Number of commits to fetch. Set to `0` for full history. | No | `1` |
| `submodules` | Whether to checkout submodules: `false`, `true`, or `recursive`. | No | `false` |
| `lfs` | Whether to download Git LFS objects. | No | `false` |
| `clean` | Whether to clean the workspace before checkout (preserves `.git`). | No | `true` |
| `persist-credentials` | Whether to persist the token in the local git config. | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `ref` | The branch name or SHA that was checked out. |
| `commit` | The full commit SHA of HEAD after checkout. |

## Security Considerations

- The `token` input defaults to the automatic `GITHUB_TOKEN`, which is scoped to the current repository and expires after the workflow run.
- When `persist-credentials` is set to `false`, the token is removed from the git remote URL and git config after checkout.
- Clone URLs use the `x-access-token` scheme for HTTPS authentication.
- See [Security Practices](./security.md) for project-wide security details.
