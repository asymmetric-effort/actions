import { createElement } from '@asymmetric-effort/specifyjs';

interface ActionInput {
  name: string;
  description: string;
  required: boolean;
  default?: string;
}

interface ActionOutput {
  name: string;
  description: string;
}

interface ActionData {
  name: string;
  description: string;
  badge: string;
  badgeColor: string;
  usage: string;
  inputs: ActionInput[];
  outputs: ActionOutput[];
}

const actions: Record<string, ActionData> = {
  'setup-bun': {
    name: 'Setup Bun',
    description: 'Install and configure the Bun JavaScript runtime in your GitHub Actions workflows. Supports version pinning, version files, and binary caching for fast CI builds.',
    badge: 'Runtime',
    badgeColor: 'badge-orange',
    usage: `- uses: asymmetric-effort/actions/actions/setup-bun@v1
  with:
    bun-version: "latest"

# Pin to a specific version
- uses: asymmetric-effort/actions/actions/setup-bun@v1
  with:
    bun-version: "1.1.0"

# Read version from package.json
- uses: asymmetric-effort/actions/actions/setup-bun@v1
  with:
    bun-version-file: "package.json"`,
    inputs: [
      { name: 'bun-version', description: 'Bun version to install (semver, "latest", or "canary")', required: false, default: 'latest' },
      { name: 'bun-version-file', description: 'File to read Bun version from (e.g., package.json, .tool-versions)', required: false },
      { name: 'no-cache', description: 'Disable caching of the Bun binary', required: false, default: 'false' },
      { name: 'token', description: 'GitHub token for API requests (avoids rate limits)', required: false, default: '${{ github.token }}' },
    ],
    outputs: [
      { name: 'bun-version', description: 'The installed Bun version' },
      { name: 'bun-path', description: 'Path to the Bun binary' },
      { name: 'cache-hit', description: 'Whether the Bun binary was restored from cache' },
    ],
  },
  'fossa-scan': {
    name: 'FOSSA Scan',
    description: 'Run FOSSA license compliance and security scanning in your CI pipeline. Automatically installs the FOSSA CLI, runs analysis, and optionally tests for policy violations.',
    badge: 'Security',
    badgeColor: 'badge-blue',
    usage: `# Basic usage
- uses: asymmetric-effort/actions/actions/fossa-scan@v1
  with:
    api-key: \${{ secrets.FOSSA_API_KEY }}

# With compliance testing
- uses: asymmetric-effort/actions/actions/fossa-scan@v1
  with:
    api-key: \${{ secrets.FOSSA_API_KEY }}
    run-tests: "true"`,
    inputs: [
      { name: 'api-key', description: 'FOSSA API key', required: true },
      { name: 'run-tests', description: 'Run fossa test after analysis', required: false, default: 'false' },
      { name: 'endpoint', description: 'FOSSA server endpoint', required: false, default: 'https://app.fossa.com' },
      { name: 'project', description: 'Project name override', required: false },
      { name: 'branch', description: 'Branch name override', required: false },
      { name: 'working-directory', description: 'Working directory for analysis', required: false, default: '.' },
      { name: 'cli-version', description: 'FOSSA CLI version to install', required: false, default: 'latest' },
      { name: 'debug', description: 'Enable debug output', required: false, default: 'false' },
    ],
    outputs: [
      { name: 'test-result', description: 'Result of fossa test (pass/fail)' },
    ],
  },
  'gh-release': {
    name: 'GitHub Release',
    description: 'Create or update GitHub Releases with asset uploads. Supports draft releases, prereleases, auto-generated release notes, and glob-based file uploads.',
    badge: 'Release',
    badgeColor: 'badge-green',
    usage: `# Create a release on tag push
- uses: asymmetric-effort/actions/actions/gh-release@v1
  with:
    tag_name: \${{ github.ref_name }}
    generate_release_notes: "true"

# Upload build artifacts
- uses: asymmetric-effort/actions/actions/gh-release@v1
  with:
    files: |
      dist/*.tar.gz
      dist/*.zip`,
    inputs: [
      { name: 'tag_name', description: 'Git tag for the release', required: false, default: '${{ github.ref_name }}' },
      { name: 'name', description: 'Release name (defaults to tag name)', required: false },
      { name: 'body', description: 'Release notes text', required: false },
      { name: 'body_path', description: 'Path to file containing release notes', required: false },
      { name: 'draft', description: 'Create as draft release', required: false, default: 'false' },
      { name: 'prerelease', description: 'Mark as prerelease', required: false, default: 'false' },
      { name: 'files', description: 'Newline-delimited glob patterns for assets to upload', required: false },
      { name: 'working_directory', description: 'Base directory for resolving file globs', required: false, default: '${{ github.workspace }}' },
      { name: 'overwrite_files', description: 'Replace existing assets with the same name', required: false, default: 'true' },
      { name: 'fail_on_unmatched_files', description: 'Fail if a glob pattern matches no files', required: false, default: 'false' },
      { name: 'target_commitish', description: 'Commitish for tag creation', required: false },
      { name: 'generate_release_notes', description: 'Auto-generate release notes via GitHub API', required: false, default: 'false' },
      { name: 'make_latest', description: 'Mark as latest release (true/false/legacy)', required: false },
      { name: 'token', description: 'GitHub token', required: false, default: '${{ github.token }}' },
      { name: 'repository', description: 'Target repository (owner/repo)', required: false, default: '${{ github.repository }}' },
    ],
    outputs: [
      { name: 'url', description: 'HTML URL of the release' },
      { name: 'id', description: 'Release ID' },
      { name: 'upload_url', description: 'Upload URL for additional assets' },
      { name: 'assets', description: 'JSON array of uploaded asset metadata' },
    ],
  },
  'go-tooling': {
    name: 'Go Tooling',
    description: 'Install and configure the complete Go toolchain with govulncheck and intelligent caching. Supports version pinning, go.mod resolution, and caches the Go SDK, module cache, and build cache for fast CI runs.',
    badge: 'Toolchain',
    badgeColor: 'badge-blue',
    usage: `# Default: Go 1.26.2 + govulncheck
- uses: asymmetric-effort/actions/actions/go-tooling@v1

# Read version from go.mod
- uses: asymmetric-effort/actions/actions/go-tooling@v1
  with:
    go-version-file: "go.mod"

# Full workflow
- uses: asymmetric-effort/actions/actions/go-tooling@v1
  with:
    go-version: "1.26.2"
- run: go build ./...
- run: go test ./...
- run: govulncheck ./...`,
    inputs: [
      { name: 'go-version', description: 'Go version to install (e.g., 1.26.2, latest, stable)', required: false, default: '1.26.2' },
      { name: 'go-version-file', description: 'File to read Go version from (e.g., go.mod, .go-version)', required: false },
      { name: 'govulncheck-version', description: 'govulncheck version to install', required: false, default: 'latest' },
      { name: 'no-cache', description: 'Disable caching of Go toolchain and modules', required: false, default: 'false' },
      { name: 'token', description: 'GitHub token for API requests', required: false, default: '${{ github.token }}' },
      { name: 'cache-key-suffix', description: 'Optional suffix for cache key isolation', required: false },
    ],
    outputs: [
      { name: 'go-version', description: 'The installed Go version' },
      { name: 'go-path', description: 'GOPATH value' },
      { name: 'govulncheck-version', description: 'The installed govulncheck version' },
      { name: 'cache-hit', description: 'Whether the toolchain was restored from cache' },
    ],
  },
  'build-pkg-rpm': {
    name: 'Build RPM Package',
    description: 'Build RPM packages for Red Hat, CentOS, Fedora, and other RPM-based Linux distributions. Generate a spec file from inline inputs or provide your own.',
    badge: 'Packaging',
    badgeColor: 'badge-orange',
    usage: `# Inline metadata
- uses: asymmetric-effort/actions/actions/build-pkg-rpm@v1
  with:
    name: "myapp"
    version: "1.0.0"
    summary: "My Application"
    source-dir: "./build/output"

# From a spec file
- uses: asymmetric-effort/actions/actions/build-pkg-rpm@v1
  with:
    spec-file: "./packaging/myapp.spec"
    source-dir: "./build/output"`,
    inputs: [
      { name: 'spec-file', description: 'Path to an RPM .spec file', required: false },
      { name: 'name', description: 'Package name (required without spec-file)', required: false },
      { name: 'version', description: 'Package version', required: false },
      { name: 'release', description: 'Package release number', required: false, default: '1' },
      { name: 'arch', description: 'Target architecture', required: false, default: 'x86_64' },
      { name: 'summary', description: 'One-line package summary', required: false },
      { name: 'license', description: 'Package license', required: false, default: 'MIT' },
      { name: 'source-dir', description: 'Directory containing files to package', required: true },
      { name: 'install-prefix', description: 'Install prefix inside the RPM', required: false, default: '/usr/local/bin' },
      { name: 'output-dir', description: 'Directory for built RPM output', required: false, default: './rpmbuild-output' },
      { name: 'requires', description: 'Newline-delimited package dependencies', required: false },
      { name: 'scripts-pre', description: 'Pre-install script content', required: false },
      { name: 'scripts-post', description: 'Post-install script content', required: false },
    ],
    outputs: [
      { name: 'rpm-path', description: 'Path to the built RPM file' },
      { name: 'rpm-name', description: 'Filename of the built RPM' },
    ],
  },
  'build-pkg-deb': {
    name: 'Build DEB Package',
    description: 'Build Debian .deb packages for Ubuntu, Debian, and other dpkg-based distributions. Generate a control file from inline inputs or provide your own.',
    badge: 'Packaging',
    badgeColor: 'badge-green',
    usage: `# Inline metadata
- uses: asymmetric-effort/actions/actions/build-pkg-deb@v1
  with:
    name: "myapp"
    version: "1.0.0"
    maintainer: "Team <team@example.com>"
    source-dir: "./build/output"

# From a control file
- uses: asymmetric-effort/actions/actions/build-pkg-deb@v1
  with:
    control-file: "./debian/control"
    source-dir: "./build/output"`,
    inputs: [
      { name: 'control-file', description: 'Path to a debian/control file', required: false },
      { name: 'name', description: 'Package name (required without control-file)', required: false },
      { name: 'version', description: 'Package version', required: false },
      { name: 'arch', description: 'Target architecture (amd64, arm64, all)', required: false, default: 'amd64' },
      { name: 'maintainer', description: 'Package maintainer (Name <email>)', required: false },
      { name: 'summary', description: 'Short package description', required: false },
      { name: 'section', description: 'Package section', required: false, default: 'utils' },
      { name: 'priority', description: 'Package priority', required: false, default: 'optional' },
      { name: 'source-dir', description: 'Directory containing files to package', required: true },
      { name: 'install-prefix', description: 'Install prefix inside the package', required: false, default: '/usr/local/bin' },
      { name: 'output-dir', description: 'Directory for built .deb output', required: false, default: './debbuild-output' },
      { name: 'depends', description: 'Comma-separated package dependencies', required: false },
      { name: 'scripts-preinst', description: 'Pre-install script content', required: false },
      { name: 'scripts-postinst', description: 'Post-install script content', required: false },
    ],
    outputs: [
      { name: 'deb-path', description: 'Path to the built .deb file' },
      { name: 'deb-name', description: 'Filename of the built .deb' },
    ],
  },
  'npm-publish': {
    name: 'NPM Publish',
    description: 'Publish packages to npm using OIDC trusted publisher. No long-lived NPM_TOKEN secret required. The npm package must already exist with trusted publishing configured.',
    badge: 'Publishing',
    badgeColor: 'badge-orange',
    usage: `# Basic publish (requires id-token: write permission)
- uses: asymmetric-effort/actions/actions/npm-publish@v1

# Publish with a custom tag
- uses: asymmetric-effort/actions/actions/npm-publish@v1
  with:
    tag: "next"
    access: "public"

# Publish from a subdirectory
- uses: asymmetric-effort/actions/actions/npm-publish@v1
  with:
    package-dir: "./packages/core"

# Dry run
- uses: asymmetric-effort/actions/actions/npm-publish@v1
  with:
    dry-run: "true"`,
    inputs: [
      { name: 'package-dir', description: 'Directory containing the package.json', required: false, default: '.' },
      { name: 'tag', description: 'npm dist-tag (latest, next, beta, etc.)', required: false, default: 'latest' },
      { name: 'access', description: 'Package access level (public or restricted)', required: false, default: 'public' },
      { name: 'dry-run', description: 'Perform a dry run without publishing', required: false, default: 'false' },
      { name: 'registry', description: 'npm registry URL', required: false, default: 'https://registry.npmjs.org' },
      { name: 'provenance', description: 'Generate provenance attestation', required: false, default: 'true' },
    ],
    outputs: [
      { name: 'version', description: 'The published package version' },
      { name: 'package', description: 'The published package name' },
      { name: 'registry-url', description: 'The registry URL used' },
    ],
  },
};

function InputsTable(props: { inputs: ActionInput[] }): ReturnType<typeof createElement> {
  return createElement('table', { className: 'param-table' },
    createElement('thead', null,
      createElement('tr', null,
        createElement('th', null, 'Input'),
        createElement('th', null, 'Description'),
        createElement('th', null, 'Required'),
        createElement('th', null, 'Default'),
      ),
    ),
    createElement('tbody', null,
      ...props.inputs.map((input) =>
        createElement('tr', { key: input.name },
          createElement('td', null, createElement('span', { className: 'param-name' }, input.name)),
          createElement('td', null, input.description),
          createElement('td', null, input.required
            ? createElement('span', { className: 'param-required' }, 'Yes')
            : 'No'),
          createElement('td', null, input.default
            ? createElement('span', { className: 'param-default' }, input.default)
            : '-'),
        ),
      ),
    ),
  );
}

function OutputsTable(props: { outputs: ActionOutput[] }): ReturnType<typeof createElement> {
  return createElement('table', { className: 'param-table' },
    createElement('thead', null,
      createElement('tr', null,
        createElement('th', null, 'Output'),
        createElement('th', null, 'Description'),
      ),
    ),
    createElement('tbody', null,
      ...props.outputs.map((output) =>
        createElement('tr', { key: output.name },
          createElement('td', null, createElement('span', { className: 'param-name' }, output.name)),
          createElement('td', null, output.description),
        ),
      ),
    ),
  );
}

interface ActionDocsProps {
  slug: string;
}

export function ActionDocs(props: ActionDocsProps): ReturnType<typeof createElement> {
  const action = actions[props.slug];
  if (!action) {
    return createElement('p', null, 'Action not found.');
  }

  return createElement('div', { className: 'section' },
    createElement('div', { className: 'action-card' },
      createElement('div', { className: 'action-card-header' },
        createElement('span', { className: `action-badge ${action.badgeColor}` }, action.badge),
        createElement('h2', { style: 'font-size:20px;font-weight:600;margin:0;' }, action.name),
      ),
      createElement('div', { className: 'action-card-body' },
        createElement('p', null, action.description),
        createElement('h3', null, 'Usage'),
        createElement('div', { className: 'code-block' },
          createElement('pre', null, action.usage),
        ),
        createElement('h3', null, 'Inputs'),
        createElement(InputsTable, { inputs: action.inputs }),
        createElement('h3', null, 'Outputs'),
        createElement(OutputsTable, { outputs: action.outputs }),
      ),
    ),
  );
}
