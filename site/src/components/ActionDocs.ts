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
  slug: string;
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
    slug: 'setup-bun',
    description: 'Install and configure the Bun JavaScript runtime in your GitHub Actions workflows. Supports version pinning, version files, and binary caching for fast CI builds.',
    badge: 'Runtime',
    badgeColor: 'badge-orange',
    usage: `- uses: asymmetric-effort/actions/actions/setup-bun@main
  with:
    bun-version: "latest"

# Pin to a specific version
- uses: asymmetric-effort/actions/actions/setup-bun@main
  with:
    bun-version: "1.1.0"

# Read version from package.json
- uses: asymmetric-effort/actions/actions/setup-bun@main
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
    slug: 'fossa-scan',
    description: 'Run FOSSA license compliance and security scanning in your CI pipeline. Automatically installs the FOSSA CLI, runs analysis, and optionally tests for policy violations.',
    badge: 'Security',
    badgeColor: 'badge-blue',
    usage: `# Basic usage
- uses: asymmetric-effort/actions/actions/fossa-scan@main
  with:
    api-key: \${{ secrets.FOSSA_API_KEY }}

# With compliance testing
- uses: asymmetric-effort/actions/actions/fossa-scan@main
  with:
    api-key: \${{ secrets.FOSSA_API_KEY }}
    run-tests: "true"

# Custom project and branch
- uses: asymmetric-effort/actions/actions/fossa-scan@main
  with:
    api-key: \${{ secrets.FOSSA_API_KEY }}
    project: "my-project"
    branch: "develop"`,
    inputs: [
      { name: 'api-key', description: 'FOSSA API key', required: true },
      { name: 'run-tests', description: 'Run fossa test after analysis', required: false, default: 'false' },
      { name: 'endpoint', description: 'FOSSA server endpoint', required: false, default: 'https://app.fossa.com' },
      { name: 'project', description: 'Project name override', required: false },
      { name: 'branch', description: 'Branch name override', required: false },
      { name: 'working-directory', description: 'Working directory for analysis', required: false, default: '.' },
      { name: 'cli-version', description: 'FOSSA CLI version to install (e.g., v3.9.0)', required: false, default: 'latest' },
      { name: 'debug', description: 'Enable debug output', required: false, default: 'false' },
    ],
    outputs: [
      { name: 'test-result', description: 'Result of fossa test (pass/fail)' },
    ],
  },
  'gh-release': {
    name: 'GitHub Release',
    slug: 'gh-release',
    description: 'Create or update GitHub Releases with asset uploads. Supports draft releases, prereleases, auto-generated release notes, and glob-based file uploads.',
    badge: 'Release',
    badgeColor: 'badge-green',
    usage: `# Create a release on tag push
- uses: asymmetric-effort/actions/actions/gh-release@main
  with:
    tag_name: \${{ github.ref_name }}
    name: "Release \${{ github.ref_name }}"
    body: "Automated release"

# Upload build artifacts
- uses: asymmetric-effort/actions/actions/gh-release@main
  with:
    files: |
      dist/*.tar.gz
      dist/*.zip
    generate_release_notes: "true"

# Draft prerelease
- uses: asymmetric-effort/actions/actions/gh-release@main
  with:
    draft: "true"
    prerelease: "true"
    files: "build/output/*"`,
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
};

function escapeHtml(text: string): string {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function renderInputsTable(inputs: ActionInput[]): string {
  let html = `
    <table class="param-table">
      <thead>
        <tr>
          <th>Input</th>
          <th>Description</th>
          <th>Required</th>
          <th>Default</th>
        </tr>
      </thead>
      <tbody>
  `;

  for (const input of inputs) {
    html += `
      <tr>
        <td><span class="param-name">${escapeHtml(input.name)}</span></td>
        <td>${escapeHtml(input.description)}</td>
        <td>${input.required ? '<span class="param-required">Yes</span>' : 'No'}</td>
        <td>${input.default ? `<span class="param-default">${escapeHtml(input.default)}</span>` : '-'}</td>
      </tr>
    `;
  }

  html += '</tbody></table>';
  return html;
}

function renderOutputsTable(outputs: ActionOutput[]): string {
  let html = `
    <table class="param-table">
      <thead>
        <tr>
          <th>Output</th>
          <th>Description</th>
        </tr>
      </thead>
      <tbody>
  `;

  for (const output of outputs) {
    html += `
      <tr>
        <td><span class="param-name">${escapeHtml(output.name)}</span></td>
        <td>${escapeHtml(output.description)}</td>
      </tr>
    `;
  }

  html += '</tbody></table>';
  return html;
}

export function ActionDocs(container: HTMLElement, actionSlug: string): void {
  const action = actions[actionSlug];
  if (!action) {
    container.innerHTML = '<p>Action not found.</p>';
    return;
  }

  const section = document.createElement('div');
  section.className = 'section';

  section.innerHTML = `
    <div class="action-card">
      <div class="action-card-header">
        <span class="action-badge ${action.badgeColor}">${escapeHtml(action.badge)}</span>
        <h2 style="font-size: 20px; font-weight: 600; margin: 0;">${escapeHtml(action.name)}</h2>
      </div>
      <div class="action-card-body">
        <p>${escapeHtml(action.description)}</p>

        <h3>Usage</h3>
        <div class="code-block">
          <pre>${escapeHtml(action.usage)}</pre>
        </div>

        <h3>Inputs</h3>
        ${renderInputsTable(action.inputs)}

        <h3>Outputs</h3>
        ${renderOutputsTable(action.outputs)}
      </div>
    </div>
  `;

  container.appendChild(section);
}

export function HomePage(container: HTMLElement): void {
  const hero = document.createElement('div');
  hero.className = 'hero';
  hero.innerHTML = `
    <h1>Asymmetric Effort Actions</h1>
    <p>A collection of production-ready GitHub Actions for building, scanning, and releasing your projects.</p>
    <div class="hero-actions">
      <a href="#setup-bun" class="hero-btn hero-btn-primary">Get Started</a>
      <a href="https://github.com/asymmetric-effort/actions" target="_blank" rel="noopener" class="hero-btn hero-btn-secondary">View on GitHub</a>
    </div>
  `;
  container.appendChild(hero);

  const grid = document.createElement('div');
  grid.style.cssText = 'display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin-top: 32px;';

  const cards: { slug: string; name: string; desc: string; badge: string; badgeColor: string }[] = [
    {
      slug: 'setup-bun',
      name: 'Setup Bun',
      desc: 'Install and configure the Bun JavaScript runtime with version pinning and caching.',
      badge: 'Runtime',
      badgeColor: 'badge-orange',
    },
    {
      slug: 'fossa-scan',
      name: 'FOSSA Scan',
      desc: 'Run FOSSA license compliance and security scanning in your CI pipeline.',
      badge: 'Security',
      badgeColor: 'badge-blue',
    },
    {
      slug: 'gh-release',
      name: 'GitHub Release',
      desc: 'Create or update GitHub Releases with asset uploads and auto-generated notes.',
      badge: 'Release',
      badgeColor: 'badge-green',
    },
  ];

  for (const card of cards) {
    const el = document.createElement('a');
    el.href = `#${card.slug}`;
    el.className = 'action-card';
    el.style.cssText = 'display: block; text-decoration: none; color: inherit; transition: box-shadow 0.15s;';
    el.onmouseenter = () => { el.style.boxShadow = '0 2px 8px rgba(0,0,0,0.1)'; };
    el.onmouseleave = () => { el.style.boxShadow = 'none'; };
    el.innerHTML = `
      <div class="action-card-header">
        <span class="action-badge ${card.badgeColor}">${escapeHtml(card.badge)}</span>
        <strong>${escapeHtml(card.name)}</strong>
      </div>
      <div class="action-card-body">
        <p style="margin: 0; color: var(--color-text-muted); font-size: 14px;">${escapeHtml(card.desc)}</p>
      </div>
    `;
    grid.appendChild(el);
  }

  container.appendChild(grid);
}

export function SecurityPage(container: HTMLElement): void {
  const section = document.createElement('div');
  section.className = 'section';

  section.innerHTML = `
    <h2 class="section-title">Security</h2>
    <p class="section-desc">Best practices and security considerations when using these actions.</p>

    <div class="security-note">
      <div class="security-note-title">Important: Handling Secrets</div>
      <ul>
        <li>Never hardcode API keys or tokens in your workflow files.</li>
        <li>Always use <span class="param-default">\${{ secrets.YOUR_SECRET }}</span> to reference sensitive values.</li>
        <li>Rotate secrets regularly and use the minimum required permissions.</li>
      </ul>
    </div>

    <h3>Token Permissions</h3>
    <p>All actions that accept a <span class="param-default">token</span> input default to <span class="param-default">\${{ github.token }}</span>, which is automatically provisioned by GitHub with the permissions defined in your workflow's <span class="param-default">permissions</span> block.</p>
    <p>For least-privilege access, define explicit permissions in your workflow:</p>
    <div class="code-block">
      <pre>permissions:
  contents: write    # Required for gh-release
  actions: read      # Required for setup-bun caching</pre>
    </div>

    <h3>FOSSA API Key</h3>
    <p>The <span class="param-default">fossa-scan</span> action requires a FOSSA API key. Store this as a GitHub Actions secret:</p>
    <div class="code-block">
      <pre># In your repository settings, add FOSSA_API_KEY as a secret
# Then reference it in your workflow:
- uses: asymmetric-effort/actions/actions/fossa-scan@main
  with:
    api-key: \${{ secrets.FOSSA_API_KEY }}</pre>
    </div>

    <h3>Pinning Action Versions</h3>
    <p>For production workflows, pin actions to a specific commit SHA rather than a branch name to prevent supply-chain attacks:</p>
    <div class="code-block">
      <pre># Preferred: pin to a specific SHA
- uses: asymmetric-effort/actions/actions/gh-release@abc1234

# Acceptable: pin to a release tag
- uses: asymmetric-effort/actions/actions/gh-release@v1.0.0

# Less secure: track a branch
- uses: asymmetric-effort/actions/actions/gh-release@main</pre>
    </div>

    <h3>Reporting Vulnerabilities</h3>
    <p>If you discover a security vulnerability in any of these actions, please report it responsibly by emailing <a href="mailto:security@asymmetric-effort.com">security@asymmetric-effort.com</a> or by opening a private security advisory on the <a href="https://github.com/asymmetric-effort/actions/security/advisories" target="_blank" rel="noopener">GitHub repository</a>.</p>
  `;

  container.appendChild(section);
}
