# Configure Pages

Configure GitHub Pages and output site URL metadata.

## Overview

The `configure-pages` action configures GitHub Pages for a repository, enabling it if necessary, and outputs URL metadata for use in downstream build and deploy steps. It is a self-contained replacement for `actions/configure-pages@v5` with zero third-party dependencies.

## Usage

```yaml
# Basic usage — configure Pages with defaults
- uses: asymmetric-effort/actions/actions/configure-pages@v1
  id: pages

- run: echo "Site will be at ${{ steps.pages.outputs.base_url }}"
```

```yaml
# Full Pages workflow — build and deploy a static site
name: Deploy to Pages

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.pages.outputs.base_url }}
    steps:
      - uses: actions/checkout@v4

      - name: Configure Pages
        id: pages
        uses: asymmetric-effort/actions/actions/configure-pages@v1

      - name: Build
        run: npm run build
        env:
          BASE_PATH: ${{ steps.pages.outputs.base_path }}

      - name: Upload artifact
        uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1
        with:
          path: ./dist

      - name: Deploy
        uses: asymmetric-effort/actions/actions/deploy-pages@v1
```

```yaml
# With a static site generator (creates .nojekyll)
- uses: asymmetric-effort/actions/actions/configure-pages@v1
  id: pages
  with:
    static_site_generator: next
```

```yaml
# Without automatic enablement
- uses: asymmetric-effort/actions/actions/configure-pages@v1
  id: pages
  with:
    enablement: "false"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `token` | GitHub token with Pages permissions | No | `${{ github.token }}` |
| `enablement` | Whether to enable Pages if not already enabled | No | `true` |
| `static_site_generator` | SSG being used (next, nuxt, gatsby, sveltekit) | No | |

## Outputs

| Output | Description |
|--------|-------------|
| `base_url` | Full base URL for the Pages site (e.g., `https://user.github.io/repo`) |
| `origin` | Protocol and host (e.g., `https://user.github.io`) |
| `host` | Hostname (e.g., `user.github.io`) |
| `base_path` | Path component (e.g., `/repo` for project sites, `/` for user sites) |

## Behavior

1. Queries the GitHub Pages API to check if Pages is enabled for the repository.
2. If Pages is not enabled and `enablement` is `true`, enables Pages via the API with `build_type: workflow`.
3. If Pages is not enabled and `enablement` is `false`, the action fails with an error.
4. Parses the Pages site URL into components and sets all outputs.
5. If `static_site_generator` is specified, creates a `.nojekyll` file in the workspace root to disable Jekyll processing.

## Permissions

```yaml
permissions:
  pages: write
```

## Security

- The GitHub token is used only for API calls and is never logged.
- Zero third-party dependencies.
