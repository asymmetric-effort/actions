# Audit Supply Chain

Scan repository workflows for third-party GitHub Actions and create issues
requesting internal replacements.

## Overview

This action scans `.github/workflows/*.yml` files in the current repository for
any `uses:` references to third-party actions. Actions from allowed organizations
are skipped. For each third-party action found, an issue is created in the
repository with the `github-action-request` label requesting a replacement.

## Usage

```yaml
- uses: asymmetric-effort/actions/actions/audit-supply-chain@v1
  with:
    token: ${{ secrets.SUPPLY_CHAIN_TOKEN }}
```

### Scheduled audit

```yaml
name: Supply Chain Audit
on:
  schedule:
    - cron: "0 7 * * 1" # Weekly on Monday
  workflow_dispatch:

permissions:
  contents: read
  issues: write

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: asymmetric-effort/actions/actions/audit-supply-chain@v1
        with:
          token: ${{ secrets.SUPPLY_CHAIN_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `token` | GitHub token with `issues:write` permission | Yes | - |
| `allowed-orgs` | Comma-separated list of allowed action orgs | No | `actions,github,asymmetric-effort` |

## Outputs

| Output | Description |
|--------|-------------|
| `findings-count` | Number of third-party action findings |

## Behavior

1. Scans all `.github/workflows/*.yml` and `.yaml` files
2. Extracts `uses:` references to GitHub Actions
3. Skips local actions (`./`), Docker references (`docker://`), and allowed orgs
4. Deduplicates findings by action path across all workflow files
5. Creates the `github-action-request` label if it doesn't exist
6. For each finding, checks if an open issue already exists (by label + title)
7. Creates an issue with the upstream action URL and source workflow link

## Allowed Organizations

By default, these organizations are not flagged:

- `actions` — Official GitHub Actions (e.g., `actions/checkout`)
- `github` — GitHub-maintained actions (e.g., `github/codeql-action`)
- `asymmetric-effort` — Company-owned actions

## Daily Polling Workflow

A companion workflow (`poll-supply-chain-requests.yml`) runs daily in the
`asymmetric-effort/actions` repository. It:

1. Discovers all repositories in the `asymmetric-effort` organization
2. Scans each repo for open issues with the `github-action-request` label
3. Creates tracking issues in `asymmetric-effort/actions` for any third-party
   action that doesn't already have a tracking issue

This ensures all supply chain replacement requests are centrally tracked.

## Required Permissions

The `token` input must have:

- `issues: write` — to create issues and labels in the scanned repository
- For the daily polling workflow: read access across all org repos

A Personal Access Token (PAT) or GitHub App token with appropriate scopes is
recommended, as the default `GITHUB_TOKEN` is scoped to the current repository.
