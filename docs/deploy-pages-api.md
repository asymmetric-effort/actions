# Deploy Pages (API)

Deploy to GitHub Pages using the GitHub Pages deployment API.

## Overview

The `deploy-pages-api` action deploys static sites to GitHub Pages using the Pages deployment API (`POST /repos/{owner}/{repo}/pages/deployments`) with OIDC token authentication. This is a replacement for `actions/deploy-pages@v5.0.0`.

Unlike the `deploy-pages` action (which pushes to a publish branch), this action uses the official Pages API and requires an artifact previously uploaded via `upload-pages-artifact` (or `actions/upload-artifact`).

## Usage

```yaml
permissions:
  pages: write
  id-token: write

steps:
  - uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1
    with:
      path: ./dist

  - uses: asymmetric-effort/actions/actions/deploy-pages-api@v1
    id: deploy

  - run: echo "Deployed to ${{ steps.deploy.outputs.page_url }}"
```

```yaml
# Custom timeout and polling interval
permissions:
  pages: write
  id-token: write

steps:
  - uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1
    with:
      path: ./build

  - uses: asymmetric-effort/actions/actions/deploy-pages-api@v1
    id: deploy
    with:
      timeout: "300000"
      reporting_interval: "10000"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `token` | GitHub token with `pages:write` permission | No | `${{ github.token }}` |
| `timeout` | Maximum time (ms) to wait for deployment | No | `600000` |
| `error_count` | Maximum consecutive polling errors before failing | No | `10` |
| `reporting_interval` | Interval (ms) between status polls | No | `5000` |
| `artifact_name` | Name of the artifact to download and deploy | No | `github-pages` |

## Outputs

| Output | Description |
|--------|-------------|
| `page_url` | The URL of the deployed GitHub Pages site |

## Permissions

```yaml
permissions:
  pages: write
  id-token: write
```

Both permissions are required. The `id-token: write` permission is needed to request an OIDC token for authenticating with the Pages deployment API.

## How It Works

1. Downloads the named artifact (default: `github-pages`) produced by `upload-pages-artifact`
2. Requests an OIDC token from the GitHub Actions runtime
3. Creates a Pages deployment via `POST /repos/{owner}/{repo}/pages/deployments`
4. Uploads the artifact tarball to the deployment
5. Polls the deployment status until it succeeds, fails, or times out
6. Outputs the deployed page URL

## Security

- Uses OIDC tokens for API authentication (no long-lived secrets)
- The GitHub token is passed via Authorization header, never logged
- Zero third-party dependencies
