# codeql

Run CodeQL security analysis in your GitHub Actions workflow.

## Description

This set of composite actions replaces `github/codeql-action@v3.28.0` with three self-contained composite actions that handle CodeQL initialization, building, and analysis. The actions download the CodeQL CLI, initialize databases, trace builds, run queries, and upload SARIF results to GitHub Code Scanning.

**Action type:** Composite (3 sub-actions)

## Sub-Actions

### codeql-init

Initialize CodeQL databases for security analysis.

#### Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `languages` | Comma-separated list of languages to analyze (e.g. `go,javascript`) | Yes | |
| `config-file` | Path to CodeQL configuration file | No | `""` |
| `queries` | Comma-separated list of additional query packs or suites | No | `""` |
| `tools` | CodeQL CLI version (`latest` or a specific version) | No | `latest` |
| `token` | GitHub token for downloading CodeQL CLI | No | `${{ github.token }}` |

#### Outputs

| Name | Description |
|------|-------------|
| `codeql-path` | Path to the CodeQL CLI binary |

### codeql-autobuild

Auto-detect and build the project for CodeQL analysis.

#### Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `language` | Language to build (if empty, builds all initialized languages) | No | `""` |
| `build-command` | Custom build command to use instead of auto-detection | No | `""` |

#### Supported Build Systems

| Language | Detected Build Systems |
|----------|----------------------|
| Go | `go.mod`, `Makefile`, default (`go build ./...`) |
| JavaScript/TypeScript | `yarn.lock` (yarn), `package.json` (npm) |
| Python | No build needed (interpreted) |
| Java | `pom.xml` (Maven), `build.gradle` / `build.gradle.kts` (Gradle) |
| C/C++ | `CMakeLists.txt` (CMake), `Makefile` (Make) |
| C# | `.sln` / `.csproj` (dotnet) |
| Ruby | No build needed (interpreted) |
| Swift | `Package.swift` (Swift Package Manager), xcodebuild |

### codeql-analyze

Run CodeQL analysis and upload SARIF results.

#### Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `category` | Category for the SARIF upload (used to distinguish multiple analyses) | No | `""` |
| `output` | Directory to write SARIF output files | No | `""` |
| `upload` | Whether to upload SARIF results to GitHub Code Scanning | No | `true` |
| `token` | GitHub token for uploading results | No | `${{ github.token }}` |

#### Outputs

| Name | Description |
|------|-------------|
| `sarif-output` | Path to the directory containing SARIF output files |

## Usage

### Basic (Go project)

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1

  - uses: asymmetric-effort/actions/actions/codeql-init@v1
    with:
      languages: "go"

  - uses: asymmetric-effort/actions/actions/codeql-autobuild@v1

  - uses: asymmetric-effort/actions/actions/codeql-analyze@v1
```

### Multiple languages

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1

  - uses: asymmetric-effort/actions/actions/codeql-init@v1
    with:
      languages: "go,javascript,python"

  - uses: asymmetric-effort/actions/actions/codeql-autobuild@v1

  - uses: asymmetric-effort/actions/actions/codeql-analyze@v1
    with:
      category: "multi-language"
```

### Custom build command

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1

  - uses: asymmetric-effort/actions/actions/codeql-init@v1
    with:
      languages: "cpp"

  - uses: asymmetric-effort/actions/actions/codeql-autobuild@v1
    with:
      build-command: "cmake -B build && cmake --build build"

  - uses: asymmetric-effort/actions/actions/codeql-analyze@v1
    with:
      output: "sarif-results"
```

### Specific CodeQL version with custom queries

```yaml
steps:
  - uses: asymmetric-effort/actions/actions/checkout@v1

  - uses: asymmetric-effort/actions/actions/codeql-init@v1
    with:
      languages: "java"
      tools: "2.16.0"
      queries: "security-extended"

  - uses: asymmetric-effort/actions/actions/codeql-autobuild@v1

  - uses: asymmetric-effort/actions/actions/codeql-analyze@v1
    with:
      upload: "true"
      category: "java-security"
```

### Full workflow example

```yaml
name: "CodeQL Analysis"

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 6 * * 1"

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    strategy:
      fail-fast: false
      matrix:
        language: ["go", "javascript"]

    steps:
      - uses: asymmetric-effort/actions/actions/checkout@v1

      - uses: asymmetric-effort/actions/actions/codeql-init@v1
        with:
          languages: ${{ matrix.language }}

      - uses: asymmetric-effort/actions/actions/codeql-autobuild@v1

      - uses: asymmetric-effort/actions/actions/codeql-analyze@v1
        with:
          category: "/language:${{ matrix.language }}"
```

## Architecture

The three actions share common utility functions via `actions/codeql-common/scripts/shared.sh`. State is passed between steps using environment variables (`CODEQL_DATABASES`, `CODEQL_TOOL_DIR`) exported to `$GITHUB_ENV`.

### File Structure

```
actions/
  codeql-common/scripts/shared.sh    # Shared utility functions
  codeql-init/action.yml             # Init action definition
  codeql-init/scripts/init.sh        # Download CLI, create databases
  codeql-autobuild/action.yml        # Autobuild action definition
  codeql-autobuild/scripts/autobuild.sh  # Build detection and execution
  codeql-analyze/action.yml          # Analyze action definition
  codeql-analyze/scripts/analyze.sh  # Analysis and SARIF upload
tests/
  codeql/test-init.sh                # Init tests
  codeql/test-autobuild.sh           # Autobuild tests
  codeql/test-analyze.sh             # Analyze tests
```
