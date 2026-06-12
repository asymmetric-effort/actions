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
  'checkout': {
    name: 'Checkout',
    description: 'Check out repository source code in your GitHub Actions workflows. Supports shallow and full clones, submodules, Git LFS, custom refs, and credential management. Drop-in replacement for actions/checkout.',
    badge: 'Core',
    badgeColor: 'badge-blue',
    usage: `# Basic checkout
- uses: asymmetric-effort/actions/actions/checkout@v1

# Checkout a specific branch
- uses: asymmetric-effort/actions/actions/checkout@v1
  with:
    ref: "develop"

# Full clone with submodules
- uses: asymmetric-effort/actions/actions/checkout@v1
  with:
    fetch-depth: "0"
    submodules: "recursive"

# Checkout with LFS
- uses: asymmetric-effort/actions/actions/checkout@v1
  with:
    lfs: "true"`,
    inputs: [
      { name: 'repository', description: 'Repository name with owner (e.g., owner/repo)', required: false, default: '${{ github.repository }}' },
      { name: 'ref', description: 'Branch, tag, or SHA to checkout', required: false, default: '' },
      { name: 'token', description: 'GitHub token for authentication', required: false, default: '${{ github.token }}' },
      { name: 'path', description: 'Relative path to place the repository', required: false, default: '.' },
      { name: 'fetch-depth', description: 'Number of commits to fetch (0 for full history)', required: false, default: '1' },
      { name: 'submodules', description: 'Checkout submodules: false, true, or recursive', required: false, default: 'false' },
      { name: 'lfs', description: 'Download Git LFS objects', required: false, default: 'false' },
      { name: 'clean', description: 'Clean workspace before checkout', required: false, default: 'true' },
      { name: 'persist-credentials', description: 'Persist token in local git config', required: false, default: 'true' },
    ],
    outputs: [
      { name: 'ref', description: 'The ref that was checked out' },
      { name: 'commit', description: 'The commit SHA that was checked out' },
    ],
  },
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
  'release': {
    name: 'Release',
    description: 'Full-featured GitHub Release management with asset uploads. Create or update releases, upload artifacts via glob patterns, auto-generate notes, link discussions, and append to existing release bodies. Drop-in replacement for softprops/action-gh-release.',
    badge: 'Release',
    badgeColor: 'badge-green',
    usage: `# Basic release with auto-generated notes
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    generate_release_notes: "true"

# Upload build artifacts
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    files: |
      dist/*.tar.gz
      dist/*.zip

# Release notes from file with discussion
- uses: asymmetric-effort/actions/actions/release@v1
  with:
    body_path: CHANGELOG.md
    discussion_category_name: "Releases"`,
    inputs: [
      { name: 'tag_name', description: 'Git tag for the release', required: false, default: '${{ github.ref_name }}' },
      { name: 'name', description: 'Release name (defaults to tag)', required: false },
      { name: 'body', description: 'Release notes text', required: false },
      { name: 'body_path', description: 'Path to file with release notes', required: false },
      { name: 'append_body', description: 'Append body to existing notes', required: false, default: 'false' },
      { name: 'draft', description: 'Create as draft', required: false, default: 'false' },
      { name: 'prerelease', description: 'Mark as prerelease', required: false, default: 'false' },
      { name: 'files', description: 'Newline-delimited glob patterns', required: false },
      { name: 'working_directory', description: 'Base dir for file globs', required: false, default: '${{ github.workspace }}' },
      { name: 'overwrite_files', description: 'Replace existing assets', required: false, default: 'true' },
      { name: 'fail_on_unmatched_files', description: 'Fail if glob matches nothing', required: false, default: 'false' },
      { name: 'target_commitish', description: 'Commitish for tag creation', required: false },
      { name: 'generate_release_notes', description: 'Auto-generate notes', required: false, default: 'false' },
      { name: 'previous_tag', description: 'Base tag for auto-generated notes', required: false },
      { name: 'discussion_category_name', description: 'Link a discussion in this category', required: false },
      { name: 'make_latest', description: 'Latest release flag (true/false/legacy)', required: false },
      { name: 'token', description: 'GitHub token', required: false, default: '${{ github.token }}' },
      { name: 'repository', description: 'Target repo (owner/repo)', required: false, default: '${{ github.repository }}' },
    ],
    outputs: [
      { name: 'url', description: 'HTML URL of the release' },
      { name: 'id', description: 'Release ID' },
      { name: 'upload_url', description: 'Upload URL for additional assets' },
      { name: 'assets', description: 'JSON array of uploaded asset metadata' },
    ],
  },
  'setup-go': {
    name: 'Setup Go',
    description: 'Install and configure the Go toolchain in your GitHub Actions workflows. Supports version pinning, go.mod resolution, module and build caching, and architecture selection. Drop-in replacement for actions/setup-go.',
    badge: 'Runtime',
    badgeColor: 'badge-blue',
    usage: `# Install latest stable Go
- uses: asymmetric-effort/actions/actions/setup-go@v1
  with:
    go-version: "stable"

# Read version from go.mod
- uses: asymmetric-effort/actions/actions/setup-go@v1
  with:
    go-version-file: "go.mod"

# Pin a specific version
- uses: asymmetric-effort/actions/actions/setup-go@v1
  with:
    go-version: "1.26.3"`,
    inputs: [
      { name: 'go-version', description: 'Go version to install (e.g., 1.26.2, latest, stable)', required: false },
      { name: 'go-version-file', description: 'File to read Go version from (e.g., go.mod, .go-version)', required: false },
      { name: 'check-latest', description: 'Check for the latest available version', required: false, default: 'false' },
      { name: 'cache', description: 'Enable caching of Go modules', required: false, default: 'true' },
      { name: 'cache-dependency-path', description: 'Path to dependency file(s) for cache key', required: false },
      { name: 'token', description: 'GitHub token for API requests', required: false, default: '${{ github.token }}' },
      { name: 'architecture', description: 'Target architecture (amd64, arm64)', required: false },
    ],
    outputs: [
      { name: 'go-version', description: 'The installed Go version' },
      { name: 'cache-hit', description: 'Whether Go modules were restored from cache' },
    ],
  },
  'setup-node': {
    name: 'Setup Node.js',
    description: 'Install and configure Node.js in your GitHub Actions workflows. Supports version pinning, .nvmrc/.node-version files, LTS versions, npm/yarn/pnpm caching, and private registry configuration. Drop-in replacement for actions/setup-node.',
    badge: 'Runtime',
    badgeColor: 'badge-green',
    usage: `# Install Node.js 24
- uses: asymmetric-effort/actions/actions/setup-node@v1
  with:
    node-version: "24"
    cache: "npm"

# Read from .nvmrc
- uses: asymmetric-effort/actions/actions/setup-node@v1
  with:
    node-version-file: ".nvmrc"
    cache: "npm"

# Use latest LTS
- uses: asymmetric-effort/actions/actions/setup-node@v1
  with:
    node-version: "lts/*"`,
    inputs: [
      { name: 'node-version', description: 'Node.js version (semver, lts/*, lts/iron, latest)', required: false },
      { name: 'node-version-file', description: 'File to read version from (.nvmrc, .node-version, package.json)', required: false },
      { name: 'cache', description: 'Package manager to cache (npm, yarn, pnpm)', required: false },
      { name: 'registry-url', description: 'npm registry URL for .npmrc', required: false },
      { name: 'architecture', description: 'Target architecture (x64, arm64)', required: false, default: 'x64' },
      { name: 'token', description: 'GitHub token for API requests', required: false, default: '${{ github.token }}' },
    ],
    outputs: [
      { name: 'node-version', description: 'The installed Node.js version' },
      { name: 'cache-hit', description: 'Whether the package manager cache was restored' },
    ],
  },
  'setup-python': {
    name: 'Setup Python',
    description: 'Install and configure the Python runtime in your GitHub Actions workflows. Supports version pinning, .python-version files, tool cache / apt / source installation, and pip/pipenv/poetry caching. Drop-in replacement for actions/setup-python.',
    badge: 'Runtime',
    badgeColor: 'badge-yellow',
    usage: `# Install Python 3.12
- uses: asymmetric-effort/actions/actions/setup-python@v1
  with:
    python-version: "3.12"
    cache: "pip"

# Read from .python-version
- uses: asymmetric-effort/actions/actions/setup-python@v1
  with:
    cache: "pip"

# Poetry project
- uses: asymmetric-effort/actions/actions/setup-python@v1
  with:
    python-version: "3.11"
    cache: "poetry"`,
    inputs: [
      { name: 'python-version', description: 'Python version to install (e.g., 3.12, 3.11.5)', required: false },
      { name: 'python-version-file', description: 'File to read version from (e.g., .python-version)', required: false, default: '.python-version' },
      { name: 'cache', description: 'Package manager to cache (pip, pipenv, poetry)', required: false },
      { name: 'architecture', description: 'Target architecture (x64, arm64)', required: false, default: 'x64' },
      { name: 'token', description: 'GitHub token for API requests', required: false, default: '${{ github.token }}' },
    ],
    outputs: [
      { name: 'python-version', description: 'The installed Python version' },
      { name: 'python-path', description: 'Path to the Python executable' },
      { name: 'cache-hit', description: 'Whether the package cache was restored' },
    ],
  },
  'deploy-pages': {
    name: 'Deploy Pages',
    description: 'Deploy static files to GitHub Pages by pushing to a deploy branch. Supports custom domains, SSH deploy keys, orphan branches, Jekyll control, asset exclusion, and tagging. Drop-in replacement for peaceiris/actions-gh-pages.',
    badge: 'Deployment',
    badgeColor: 'badge-blue',
    usage: `# Basic deploy to gh-pages branch
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    token: \${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./dist

# Deploy with custom domain
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    token: \${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build
    cname: my-site.example.com

# Force orphan (single-commit history)
- uses: asymmetric-effort/actions/actions/deploy-pages@v1
  with:
    token: \${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./public
    force_orphan: "true"`,
    inputs: [
      { name: 'token', description: 'GitHub token for pushing', required: false, default: '${{ github.token }}' },
      { name: 'deploy_key', description: 'SSH private key for pushing', required: false },
      { name: 'publish_dir', description: 'Directory to deploy', required: false, default: 'public' },
      { name: 'publish_branch', description: 'Target branch', required: false, default: 'gh-pages' },
      { name: 'destination_dir', description: 'Subdirectory within the publish branch', required: false },
      { name: 'external_repository', description: 'Deploy to a different repo (owner/repo)', required: false },
      { name: 'allow_empty_commit', description: 'Allow empty commits', required: false, default: 'false' },
      { name: 'keep_files', description: 'Keep existing files in the branch', required: false, default: 'false' },
      { name: 'force_orphan', description: 'Single-commit history', required: false, default: 'false' },
      { name: 'user_name', description: 'Git committer name', required: false, default: 'github-actions[bot]' },
      { name: 'user_email', description: 'Git committer email', required: false },
      { name: 'commit_message', description: 'Custom commit message (SHA appended)', required: false },
      { name: 'full_commit_message', description: 'Full commit message (no SHA appended)', required: false },
      { name: 'tag_name', description: 'Create a tag on the deploy commit', required: false },
      { name: 'tag_message', description: 'Annotated tag message', required: false },
      { name: 'enable_jekyll', description: 'Enable Jekyll (skip .nojekyll)', required: false, default: 'false' },
      { name: 'cname', description: 'Custom domain (writes CNAME file)', required: false },
      { name: 'exclude_assets', description: 'Patterns to exclude from publish_dir', required: false, default: '.github' },
    ],
    outputs: [
      { name: 'deploy_branch', description: 'The branch deployed to' },
      { name: 'commit_hash', description: 'SHA of the deploy commit' },
    ],
  },
  'deploy-pages-api': {
    name: 'Deploy Pages (API)',
    description: 'Deploy to GitHub Pages using the Pages deployment API with OIDC token authentication. Downloads a previously uploaded artifact and creates a deployment via the GitHub API. Drop-in replacement for actions/deploy-pages.',
    badge: 'Deployment',
    badgeColor: 'badge-blue',
    usage: `# Deploy after uploading artifact
- uses: asymmetric-effort/actions/actions/deploy-pages-api@v1
  with:
    token: \${{ secrets.GITHUB_TOKEN }}

# With custom timeout
- uses: asymmetric-effort/actions/actions/deploy-pages-api@v1
  with:
    token: \${{ secrets.GITHUB_TOKEN }}
    timeout: "900000"`,
    inputs: [
      { name: 'token', description: 'GitHub token with pages:write permission', required: false, default: '${{ github.token }}' },
      { name: 'timeout', description: 'Maximum time (ms) to wait for deployment', required: false, default: '600000' },
      { name: 'error_count', description: 'Max consecutive polling errors before failing', required: false, default: '10' },
      { name: 'reporting_interval', description: 'Interval (ms) between status polls', required: false, default: '5000' },
      { name: 'artifact_name', description: 'Name of the artifact to deploy', required: false, default: 'github-pages' },
    ],
    outputs: [
      { name: 'page_url', description: 'The URL of the deployed GitHub Pages site' },
    ],
  },
  'upload-pages-artifact': {
    name: 'Upload Pages Artifact',
    description: 'Package a directory as a tar.gz archive and upload it as a GitHub Actions artifact named "github-pages" for use with deploy-pages-api. Automatically creates .nojekyll if not present. Drop-in replacement for actions/upload-pages-artifact.',
    badge: 'Deployment',
    badgeColor: 'badge-orange',
    usage: `# Upload dist/ for Pages deployment
- uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1
  with:
    path: ./dist

# With custom retention
- uses: asymmetric-effort/actions/actions/upload-pages-artifact@v1
  with:
    path: ./build
    retention-days: "3"`,
    inputs: [
      { name: 'path', description: 'Directory containing static files to deploy', required: false, default: '.' },
      { name: 'retention-days', description: 'Number of days to retain the artifact', required: false, default: '1' },
    ],
    outputs: [
      { name: 'artifact-id', description: 'The ID of the uploaded artifact' },
    ],
  },
  'codeql-init': {
    name: 'CodeQL Init',
    description: 'Initialize CodeQL databases for security analysis. Downloads the CodeQL CLI, creates databases for specified languages, and prepares the environment for autobuild and analysis. Replaces github/codeql-action/init.',
    badge: 'Security',
    badgeColor: 'badge-purple',
    usage: `# Initialize for Go
- uses: asymmetric-effort/actions/actions/codeql-init@v1
  with:
    languages: "go"

# Multiple languages
- uses: asymmetric-effort/actions/actions/codeql-init@v1
  with:
    languages: "go,javascript"`,
    inputs: [
      { name: 'languages', description: 'Comma-separated languages to analyze (e.g., go,javascript)', required: true },
      { name: 'config-file', description: 'Path to CodeQL configuration file', required: false },
      { name: 'queries', description: 'Additional query packs or suites', required: false },
      { name: 'tools', description: 'CodeQL CLI version (latest or specific)', required: false, default: 'latest' },
      { name: 'token', description: 'GitHub token for downloading CodeQL CLI', required: false, default: '${{ github.token }}' },
    ],
    outputs: [
      { name: 'codeql-path', description: 'Path to the CodeQL CLI binary' },
    ],
  },
  'codeql-autobuild': {
    name: 'CodeQL Autobuild',
    description: 'Auto-detect the build system and compile the project for CodeQL analysis. Supports Go, JavaScript/TypeScript, Java (Maven/Gradle), C/C++ (CMake/Make), C# (.NET), and Swift. Replaces github/codeql-action/autobuild.',
    badge: 'Security',
    badgeColor: 'badge-purple',
    usage: `# Auto-detect build system
- uses: asymmetric-effort/actions/actions/codeql-autobuild@v1

# Specify language
- uses: asymmetric-effort/actions/actions/codeql-autobuild@v1
  with:
    language: "go"

# Custom build command
- uses: asymmetric-effort/actions/actions/codeql-autobuild@v1
  with:
    build-command: "make release"`,
    inputs: [
      { name: 'language', description: 'Language to build (if empty, builds all initialized)', required: false },
      { name: 'build-command', description: 'Custom build command instead of auto-detection', required: false },
    ],
    outputs: [],
  },
  'codeql-analyze': {
    name: 'CodeQL Analyze',
    description: 'Run CodeQL queries against built databases and upload SARIF results to GitHub Code Scanning. Supports result categorization, local output, and automatic upload. Replaces github/codeql-action/analyze.',
    badge: 'Security',
    badgeColor: 'badge-purple',
    usage: `# Basic analysis with upload
- uses: asymmetric-effort/actions/actions/codeql-analyze@v1

# With category and local output
- uses: asymmetric-effort/actions/actions/codeql-analyze@v1
  with:
    category: "/language:go"
    output: "./sarif-results"

# Analysis without upload
- uses: asymmetric-effort/actions/actions/codeql-analyze@v1
  with:
    upload: "false"
    output: "./sarif-results"`,
    inputs: [
      { name: 'category', description: 'Category for SARIF upload (distinguishes multiple analyses)', required: false },
      { name: 'output', description: 'Directory to write SARIF output files', required: false },
      { name: 'upload', description: 'Upload SARIF results to GitHub Code Scanning', required: false, default: 'true' },
      { name: 'token', description: 'GitHub token for uploading results', required: false, default: '${{ github.token }}' },
    ],
    outputs: [
      { name: 'sarif-output', description: 'Path to the directory containing SARIF files' },
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
