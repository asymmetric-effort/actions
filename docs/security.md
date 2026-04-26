# Security Practices

This document describes the security practices for the Asymmetric Effort Actions project.

## Supply Chain Security

### No Third-Party Action Dependencies

The primary security goal of this project is to eliminate reliance on third-party GitHub Actions. All actions in this repository are clean-room implementations that depend only on:

- **Official GitHub Actions** (`actions/*`) -- maintained by GitHub
- **GitHub-provided runners** -- standard runner images with Node.js 20

This removes an entire class of supply chain attacks where a compromised third-party action could exfiltrate secrets, inject malicious code, or tamper with build artifacts.

### Monorepo Structure

All actions are maintained in a single repository, providing:

- Unified review process for all changes
- Consistent dependency management
- Single point of audit for security reviews

## Automated Security Controls

### Dependabot

Dependabot monitors all dependencies for known vulnerabilities and automatically opens pull requests for updates.

### CodeQL Analysis

CodeQL static analysis scans the TypeScript source code for common vulnerability patterns, including:

- Injection flaws
- Path traversal
- Insecure data handling
- Prototype pollution

### Exhaustive Testing

Each action includes a comprehensive test suite (`__tests__/` directory) with unit tests covering input validation, error handling, and edge cases.

## Secrets Handling

### General Principles

- **Never hardcode secrets** in workflow files or action source code.
- **Always use GitHub Actions secrets** (`${{ secrets.* }}`) for sensitive values.
- **Prefer environment variables** over command-line arguments for passing secrets to processes (avoids leaking secrets in process listings and logs).

### Per-Action Details

| Action | Secrets | Handling |
|--------|---------|----------|
| setup-bun | `token` (GitHub token) | Defaults to `GITHUB_TOKEN`; used only for API rate limit avoidance |
| fossa-scan | `api-key` (FOSSA API key) | Passed via `FOSSA_API_KEY` environment variable, never as a CLI argument |
| gh-release | `token` (GitHub token) | Defaults to `GITHUB_TOKEN`; requires `contents: write` permission |

### Token Scoping

- The default `GITHUB_TOKEN` is automatically scoped to the current repository and expires when the workflow run completes.
- For cross-repository operations (e.g. `gh-release` with a different `repository`), use fine-grained Personal Access Tokens (PATs) or GitHub App installation tokens with the minimum required permissions.

## Dependency Management

### Node.js Actions (setup-bun, gh-release)

- Dependencies are locked via `package-lock.json`.
- The `dist/` directory contains bundled JavaScript built from TypeScript source, ensuring the executed code matches the reviewed source.
- TypeScript source is type-checked (`npm run typecheck`) and linted (`npm run lint`) as part of the CI process.

### Composite Action (fossa-scan)

- The FOSSA CLI is downloaded over HTTPS from official GitHub releases (`github.com/fossas/fossa-cli`).
- The download URL is deterministic based on the OS, architecture, and requested version.
- The CLI is installed to a temporary directory scoped to the runner, not a shared or persistent location.

## Reporting Vulnerabilities

If you discover a security vulnerability in any of these actions, please report it responsibly:

1. **Do not** open a public GitHub issue.
2. Use [GitHub Security Advisories](https://github.com/asymmetric-effort/actions/security/advisories) to report the vulnerability privately.
3. Include a description of the vulnerability, steps to reproduce, and any potential impact.

We will acknowledge receipt within 48 hours and provide a timeline for a fix.

## Version Pinning

We recommend pinning to a major version tag (e.g. `@v1`) for stability, or to an exact version tag (e.g. `@v1.0.0`) for maximum reproducibility:

```yaml
# Recommended: major version pin (receives non-breaking updates)
- uses: asymmetric-effort/actions/actions/setup-bun@v1

# Maximum reproducibility: exact version pin
- uses: asymmetric-effort/actions/actions/setup-bun@v1.0.0

# Also valid: pin to a commit SHA for cryptographic verification
- uses: asymmetric-effort/actions/actions/setup-bun@abc123def456
```

Pinning to `@main` is not recommended for production workflows, as it tracks the latest development changes.
