# Setup Go

Install and configure the Go toolchain. A drop-in replacement for `actions/setup-go`.

## Overview

The `setup-go` action installs a specified version of Go, configures `GOROOT`, `GOPATH`, and `PATH`, and caches Go modules for fast subsequent runs. It supports reading the version from `go.mod` or `.go-version` files.

## Usage

```yaml
# Basic usage — installs the latest stable Go
- uses: asymmetric-effort/actions/actions/setup-go@v1
```

```yaml
# Specify a Go version
- uses: asymmetric-effort/actions/actions/setup-go@v1
  with:
    go-version: "1.26.2"
```

```yaml
# Read version from go.mod
- uses: asymmetric-effort/actions/actions/setup-go@v1
  with:
    go-version-file: "go.mod"
```

```yaml
# Full workflow example
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: asymmetric-effort/actions/actions/setup-go@v1
        with:
          go-version-file: "go.mod"

      - run: go build ./...
      - run: go test ./...
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `go-version` | Go version to install (e.g., `1.26.2`, `latest`, `stable`) | No | `""` (resolves to latest) |
| `go-version-file` | File to read Go version from (e.g., `go.mod`, `.go-version`) | No | `""` |
| `check-latest` | Check for the latest available version matching the input | No | `false` |
| `cache` | Enable caching of Go modules | No | `true` |
| `cache-dependency-path` | Path to dependency file(s) for cache key | No | `""` |
| `token` | GitHub token for API requests | No | `${{ github.token }}` |
| `architecture` | Target architecture override (e.g., `amd64`, `arm64`) | No | `""` |

## Outputs

| Output | Description |
|--------|-------------|
| `go-version` | The installed Go version |
| `cache-hit` | Whether Go modules were restored from cache |

## Version Resolution

Version is resolved in priority order:

1. Explicit `go-version` input
2. Version from `go-version-file` (if specified)
3. Latest stable release from go.dev

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

The action caches two directories:

| Path | Contents |
|------|----------|
| `~/go/pkg/mod` | Go module cache |
| `~/.cache/go-build` | Build cache |

Cache keys include OS, architecture, Go version, and `go.sum` hash.

Set `cache: "false"` to disable caching.

## Platform Support

| OS | Architecture | Status |
|----|-------------|--------|
| Linux | x64 | Supported |
| Linux | arm64 | Supported |
| macOS | x64 | Supported |
| macOS | arm64 | Supported |
| Windows | x64 | Supported |
