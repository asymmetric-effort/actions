# Deploy Pages

Deploy static files to GitHub Pages by pushing to a deploy branch.

## Overview

The `deploy-pages` action deploys static sites to GitHub Pages by pushing files to a configurable branch (default: `gh-pages`). It is a complete, self-contained replacement for `peaceiris/actions-gh-pages` with full feature parity.

## Usage

```yaml
# Basic deploy
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./dist
```

```yaml
# Custom domain with orphan branch
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build
    cname: my-site.example.com
    force_orphan: "true"
```

```yaml
# Deploy with SSH deploy key
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    deploy_key: ${{ secrets.DEPLOY_KEY }}
    publish_dir: ./public
```

```yaml
# Deploy to external repository
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    token: ${{ secrets.PERSONAL_TOKEN }}
    publish_dir: ./dist
    external_repository: org/other-repo
```

```yaml
# Deploy to subdirectory, keep existing files
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./docs-build
    destination_dir: docs
    keep_files: "true"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `token` | GitHub token for pushing | No | `${{ github.token }}` |
| `deploy_key` | SSH private key for pushing | No | |
| `publish_dir` | Directory to deploy | No | `public` |
| `publish_branch` | Target branch | No | `gh-pages` |
| `destination_dir` | Subdirectory within the branch | No | |
| `external_repository` | Deploy to different repo (owner/repo) | No | |
| `allow_empty_commit` | Allow empty commits | No | `false` |
| `keep_files` | Keep existing files in branch | No | `false` |
| `force_orphan` | Single-commit history | No | `false` |
| `user_name` | Git committer name | No | `github-actions[bot]` |
| `user_email` | Git committer email | No | bot noreply address |
| `commit_message` | Commit message (SHA appended) | No | |
| `full_commit_message` | Full message (no SHA) | No | |
| `tag_name` | Tag the deploy commit | No | |
| `tag_message` | Annotated tag message | No | |
| `enable_jekyll` | Enable Jekyll (skip .nojekyll) | No | `false` |
| `cname` | Custom domain (writes CNAME) | No | |
| `exclude_assets` | Patterns to exclude | No | `.github` |

## Outputs

| Output | Description |
|--------|-------------|
| `deploy_branch` | The branch deployed to |
| `commit_hash` | SHA of the deploy commit |

## Feature Parity with peaceiris/actions-gh-pages

| Feature | Supported |
|---------|-----------|
| Push to gh-pages branch | Yes |
| Token auth | Yes |
| SSH deploy key auth | Yes |
| Custom publish directory | Yes |
| Custom publish branch | Yes |
| Destination subdirectory | Yes |
| External repository | Yes |
| Force orphan (single commit) | Yes |
| Keep existing files | Yes |
| Allow empty commits | Yes |
| Custom committer name/email | Yes |
| Custom commit message | Yes |
| Full commit message | Yes |
| Tag deploy commit | Yes |
| Annotated tags | Yes |
| Enable/disable Jekyll | Yes |
| CNAME custom domain | Yes |
| Exclude assets | Yes |

## Permissions

```yaml
permissions:
  contents: write
```

## Security

- Token is embedded in the HTTPS remote URL and never logged
- SSH deploy keys are written to a temporary file with 600 permissions
- Zero third-party dependencies
