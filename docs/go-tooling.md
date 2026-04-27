# Go Tooling

Install and configure the complete Go toolchain with security tools and caching.

## Overview

The `go-tooling` action provides a single step to set up a fully configured Go development environment in your CI pipelines. It installs the Go compiler, configures `GOPATH` and `GOROOT`, installs `govulncheck` for vulnerability scanning, and caches everything for fast subsequent runs.

## Usage

```yaml
# Basic usage — installs Go 1.26.2 + govulncheck
- uses: asymmetric-effort/actions/actions/go-tooling@v1
```

```yaml
# Specify a Go version
- uses: asymmetric-effort/actions/actions/go-tooling@v1
  with:
    go-version: "1.25.0"
```

```yaml
# Read version from go.mod
- uses: asymmetric-effort/actions/actions/go-tooling@v1
  with:
    go-version-file: "go.mod"
```

```yaml
# Pin govulncheck version
- uses: asymmetric-effort/actions/actions/go-tooling@v1
  with:
    govulncheck-version: "v1.1.4"
```

```yaml
# Full workflow example
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: asymmetric-effort/actions/actions/go-tooling@v1
        with:
          go-version-file: "go.mod"

      - run: go build ./...
      - run: go test ./...
      - run: govulncheck ./...
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `go-version` | Go version to install (e.g., `1.26.2`, `latest`, `stable`) | No | `1.26.2` |
| `go-version-file` | File to read Go version from (e.g., `go.mod`, `.go-version`) | No | |
| `govulncheck-version` | govulncheck version to install | No | `latest` |
| `no-cache` | Disable caching of Go toolchain and modules | No | `false` |
| `token` | GitHub token for API requests | No | `${{ github.token }}` |
| `cache-key-suffix` | Optional suffix for cache key isolation | No | |

## Outputs

| Output | Description |
|--------|-------------|
| `go-version` | The installed Go version |
| `go-path` | GOPATH value |
| `govulncheck-version` | The installed govulncheck version |
| `cache-hit` | Whether the toolchain was restored from cache |

## Version Resolution

Version is resolved in priority order:

1. Explicit `go-version` input (if not default)
2. Version from `go-version-file` (if specified)
3. Default: `1.26.2`

Special values:
- `latest` / `stable`: Fetches the latest stable release from go.dev
- `go1.26.2` format: The `go` prefix is automatically stripped

### go.mod support

When `go-version-file` points to a `go.mod`, the action reads the `go` directive:

```
module example.com/myproject

go 1.26.2
```

### .go-version support

Plain text files containing just the version number (with or without `go` prefix):

```
1.26.2
```

## Caching

The action caches three directories:

| Path | Contents |
|------|----------|
| `~/go` | GOPATH (module cache, compiled tools) |
| `~/sdk` | Go SDK installation |
| `~/.cache/go-build` | Build cache (compiled intermediate objects) |

Cache keys include OS, architecture, Go version, and `go.sum` hash. This means:
- Changing Go version invalidates the cache
- Changing dependencies (`go.sum`) invalidates the cache
- Different OS/arch combinations get separate caches

Use `cache-key-suffix` to isolate caches between jobs in the same workflow.

## Tools Installed

| Tool | Purpose |
|------|---------|
| `go` | Go compiler and toolchain |
| `govulncheck` | Scans Go code and dependencies for known vulnerabilities |

## Security Considerations

- The Go toolchain is downloaded from `go.dev/dl/` (Google's official distribution)
- `govulncheck` is installed via `go install` from `golang.org/x/vuln`
- The vulnerability database is fetched fresh on each `govulncheck` run (not cached)
- All downloads use HTTPS

## Platform Support

| OS | Architecture | Status |
|----|-------------|--------|
| Linux | x64 | Supported |
| Linux | arm64 | Supported |
| macOS | x64 | Supported |
| macOS | arm64 | Supported |
| Windows | x64 | Supported |
