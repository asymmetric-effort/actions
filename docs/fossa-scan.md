# fossa-scan

Run [FOSSA](https://fossa.com/) license compliance and security scanning in your GitHub Actions workflow.

## Description

This composite action installs the FOSSA CLI, runs `fossa analyze` to scan your project for license compliance and dependency issues, and optionally runs `fossa test` to enforce compliance policies. It supports Linux and macOS runners on both x86_64 and ARM64 architectures.

**Action type:** Composite (shell-based)

## Usage

### Basic analysis

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/fossa-scan@v1
    with:
      api-key: ${{ secrets.FOSSA_API_KEY }}
```

### Analysis with compliance testing

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/fossa-scan@v1
    with:
      api-key: ${{ secrets.FOSSA_API_KEY }}
      run-tests: "true"
```

### Custom project and branch

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/fossa-scan@v1
    with:
      api-key: ${{ secrets.FOSSA_API_KEY }}
      project: "my-custom-project"
      branch: ${{ github.ref_name }}
```

### Pinned CLI version with debug output

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/fossa-scan@v1
    with:
      api-key: ${{ secrets.FOSSA_API_KEY }}
      cli-version: "v3.9.0"
      debug: "true"
```

### Using test results

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/fossa-scan@v1
    id: fossa
    with:
      api-key: ${{ secrets.FOSSA_API_KEY }}
      run-tests: "true"
  - run: echo "FOSSA test result: ${{ steps.fossa.outputs.test-result }}"
```

### Monorepo / subdirectory scanning

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/fossa-scan@v1
    with:
      api-key: ${{ secrets.FOSSA_API_KEY }}
      working-directory: "./services/backend"
```

### Complete workflow example

```yaml
name: License Compliance
on:
  push:
    branches: [main]
  pull_request:

jobs:
  fossa:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: asymmetric-effort/actions/actions/fossa-scan@v1
        id: scan
        with:
          api-key: ${{ secrets.FOSSA_API_KEY }}
          run-tests: "true"
          project: ${{ github.repository }}
          branch: ${{ github.ref_name }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `api-key` | FOSSA API key for authentication. Must be stored as a secret. | **Yes** | |
| `run-tests` | Run `fossa test` after analysis to enforce compliance policies. The step fails if tests do not pass. | No | `false` |
| `endpoint` | FOSSA server endpoint URL. Change this for on-premise FOSSA deployments. | No | `https://app.fossa.com` |
| `project` | Project name override. If not set, FOSSA auto-detects from the repository. | No | |
| `branch` | Branch name override. If not set, FOSSA auto-detects from Git. | No | |
| `working-directory` | Working directory for the analysis. Useful for monorepos or subdirectory scanning. | No | `.` |
| `cli-version` | FOSSA CLI version to install (e.g. `v3.9.0`). | No | `latest` |
| `debug` | Enable debug output from the FOSSA CLI. | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `test-result` | Result of `fossa test`: `pass` or `fail`. Only populated when `run-tests` is `"true"`. |

## How It Works

The action executes three steps:

1. **Validate inputs** -- Ensures the required `api-key` is provided.
2. **Install FOSSA CLI** -- Downloads the FOSSA CLI binary from the [official GitHub releases](https://github.com/fossas/fossa-cli/releases) for the appropriate OS and architecture, installs it to a temporary directory, and adds it to `PATH`.
3. **Run `fossa analyze`** -- Scans the project dependencies and uploads results to the FOSSA server.
4. **Run `fossa test`** (optional) -- If `run-tests: "true"`, checks the project against configured FOSSA policies. The step fails and the output is set to `fail` if any policy violations are found.

## Platform Support

| Platform | Architecture | Supported |
|----------|-------------|-----------|
| Linux | x86_64 (amd64) | Yes |
| Linux | aarch64 (arm64) | Yes |
| macOS | x86_64 (amd64) | Yes |
| macOS | arm64 | Yes |
| Windows | any | No |

## Security Considerations

- **The `api-key` input is required and should always be stored as a GitHub Actions secret.** Never hardcode API keys in workflow files.
- The FOSSA CLI is downloaded over HTTPS from official GitHub releases (`github.com/fossas/fossa-cli`).
- The API key is passed via the `FOSSA_API_KEY` environment variable, not as a command-line argument, to avoid leaking it in process listings or logs.
- See [Security Practices](./security.md) for project-wide security details.
