# setup-python

Install and configure the [Python](https://www.python.org/) runtime in your GitHub Actions workflow.

## Description

This action installs a specified version of Python, adds it to `PATH`, and optionally caches package manager dependencies for faster subsequent runs. It supports version resolution from `.python-version` files and can install Python from the GitHub Actions tool cache, the deadsnakes PPA, or by building from source.

**Action type:** Composite

## Usage

### Basic

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-python@v1
    with:
      python-version: "3.12"
```

### Read version from file

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-python@v1
    with:
      python-version-file: ".python-version"
```

### With pip caching

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-python@v1
    with:
      python-version: "3.12"
      cache: "pip"
  - run: pip install -r requirements.txt
```

### With poetry caching

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-python@v1
    with:
      python-version: "3.12"
      cache: "poetry"
  - run: poetry install
```

### Using outputs

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: asymmetric-effort/actions/actions/setup-python@v1
    id: setup
    with:
      python-version: "3.12"
  - run: echo "Installed Python ${{ steps.setup.outputs.python-version }} at ${{ steps.setup.outputs.python-path }}"
  - run: echo "Cache hit: ${{ steps.setup.outputs.cache-hit }}"
```

### Complete workflow example

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: asymmetric-effort/actions/actions/setup-python@v1
        with:
          python-version: "3.12"
          cache: "pip"

      - run: pip install -r requirements.txt
      - run: python -m pytest
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `python-version` | Python version to install (e.g., `3.12`, `3.11.5`). | No | `""` |
| `python-version-file` | File to read the Python version from (e.g., `.python-version`). Used when `python-version` is not set. | No | `.python-version` |
| `cache` | Package manager to cache dependencies for (`pip`, `pipenv`, or `poetry`). Leave empty to disable caching. | No | `""` |
| `architecture` | Target architecture (`x64` or `arm64`). | No | `x64` |
| `token` | GitHub token used for API requests to avoid rate limits. | No | `${{ github.token }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `python-version` | The exact Python version that was installed (e.g., `3.12.1`). |
| `python-path` | Absolute path to the installed Python executable. |
| `cache-hit` | `"true"` if package manager dependencies were restored from cache, `"false"` otherwise. |

## Version Resolution

The action resolves the Python version in the following order of precedence:

1. **`python-version`** -- If specified, this exact version string is used.
2. **`python-version-file`** -- If `python-version` is empty, the version is read from this file. Supported formats:
   - `.python-version` (plain text, one version per line)
   - Files with `python-` prefix (e.g., pyenv-style `python-3.12.1`)
3. If neither input yields a version, the action fails with an error.

## Installation Strategy

The action attempts to install Python using these strategies in order:

1. **Tool cache** -- Checks `${{ runner.tool_cache }}/Python/{version}/{architecture}/` for a pre-installed version (fastest).
2. **apt (deadsnakes PPA)** -- On Ubuntu runners, adds the deadsnakes PPA and installs via `apt-get` (moderate speed).
3. **Build from source** -- Downloads the source tarball from python.org and compiles with `--enable-optimizations` (slowest, but works anywhere).

## Caching

When the `cache` input is set, the action uses `actions/cache` to save and restore package manager dependencies:

- **pip**: Caches `~/.cache/pip` (or the output of `pip cache dir`)
- **pipenv**: Caches the virtualenvs directory
- **poetry**: Caches the poetry cache directory

The cache key is derived from the runner OS, architecture, Python version, and a hash of the relevant lock/requirements files.

## Runner Compatibility

| Runner | Supported |
|--------|-----------|
| `ubuntu-latest` | Yes |
| `ubuntu-22.04` | Yes |
| `ubuntu-24.04` | Yes |
| `macos-latest` | Yes |
| `macos-14` (ARM64) | Yes |

## Security Considerations

- The `token` input defaults to the automatic `GITHUB_TOKEN`, which is scoped to the current repository and expires after the workflow run.
- Python is installed from the official GitHub Actions tool cache, the deadsnakes PPA, or the official python.org source tarballs.
- Caching is handled through the GitHub Actions cache, which is scoped to the repository and branch.
- See [Security Practices](./security.md) for project-wide security details.
