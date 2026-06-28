import { defineConfig } from 'vite';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { specifyJsSeoPlugin, specifyJsNoscriptPlugin } from '@asymmetric-effort/specifyjs/build';
import { createElement } from '@asymmetric-effort/specifyjs';
import { renderToStaticMarkup } from '@asymmetric-effort/specifyjs/server';

const version = readFileSync(resolve(__dirname, '../VERSION'), 'utf-8').trim();
const h = createElement;

const actions: Record<string, { name: string; desc: string; inputs: string[]; outputs: string[] }> = {
  'checkout': { name: 'Checkout', desc: 'Check out repository source code with support for submodules, LFS, and shallow clones.', inputs: ['repository', 'ref', 'token', 'path', 'fetch-depth', 'submodules', 'lfs', 'clean', 'persist-credentials'], outputs: ['ref', 'commit'] },
  'setup-bun': { name: 'Setup Bun', desc: 'Install and configure the Bun JavaScript runtime with version pinning and caching.', inputs: ['bun-version', 'bun-version-file', 'no-cache', 'token'], outputs: ['bun-version', 'bun-path', 'cache-hit'] },
  'setup-go': { name: 'Setup Go', desc: 'Install and configure the Go toolchain with module and build caching.', inputs: ['go-version', 'go-version-file', 'check-latest', 'cache', 'cache-dependency-path', 'token', 'architecture'], outputs: ['go-version', 'cache-hit'] },
  'setup-node': { name: 'Setup Node.js', desc: 'Install and configure Node.js with npm/yarn/pnpm caching and LTS support.', inputs: ['node-version', 'node-version-file', 'cache', 'registry-url', 'architecture', 'token'], outputs: ['node-version', 'cache-hit'] },
  'setup-python': { name: 'Setup Python', desc: 'Install and configure Python with pip/pipenv/poetry caching.', inputs: ['python-version', 'python-version-file', 'cache', 'architecture', 'token'], outputs: ['python-version', 'python-path', 'cache-hit'] },
  'fossa-scan': { name: 'FOSSA Scan', desc: 'Run FOSSA license compliance and security scanning in your CI pipeline.', inputs: ['api-key', 'run-tests', 'endpoint', 'project', 'branch', 'working-directory', 'cli-version', 'debug'], outputs: ['test-result'] },
  'gh-release': { name: 'GitHub Release', desc: 'Create or update GitHub Releases with asset uploads and auto-generated notes.', inputs: ['tag_name', 'name', 'body', 'body_path', 'draft', 'prerelease', 'files', 'working_directory', 'overwrite_files', 'fail_on_unmatched_files', 'target_commitish', 'generate_release_notes', 'make_latest', 'token', 'repository'], outputs: ['url', 'id', 'upload_url', 'assets'] },
  'go-tooling': { name: 'Go Tooling', desc: 'Install the complete Go toolchain with govulncheck and intelligent caching.', inputs: ['go-version', 'go-version-file', 'govulncheck-version', 'no-cache', 'token', 'cache-key-suffix'], outputs: ['go-version', 'go-path', 'govulncheck-version', 'cache-hit'] },
  'build-pkg-rpm': { name: 'Build RPM Package', desc: 'Build RPM packages from a spec file or inline metadata for RHEL, Fedora, and CentOS.', inputs: ['spec-file', 'name', 'version', 'release', 'arch', 'summary', 'license', 'source-dir', 'install-prefix', 'output-dir', 'requires', 'scripts-pre', 'scripts-post'], outputs: ['rpm-path', 'rpm-name'] },
  'build-pkg-deb': { name: 'Build DEB Package', desc: 'Build Debian .deb packages from a control file or inline metadata.', inputs: ['control-file', 'name', 'version', 'arch', 'maintainer', 'summary', 'section', 'priority', 'source-dir', 'install-prefix', 'output-dir', 'depends', 'scripts-preinst', 'scripts-postinst'], outputs: ['deb-path', 'deb-name'] },
  'npm-publish': { name: 'NPM Publish', desc: 'Publish to npm using OIDC trusted publisher. No NPM_TOKEN secret required.', inputs: ['package-dir', 'tag', 'access', 'dry-run', 'registry', 'provenance'], outputs: ['version', 'package', 'registry-url'] },
  'release': { name: 'Release', desc: 'Full-featured GitHub Release management. Replaces softprops/action-gh-release.', inputs: ['tag_name', 'name', 'body', 'body_path', 'append_body', 'draft', 'prerelease', 'files', 'working_directory', 'overwrite_files', 'fail_on_unmatched_files', 'target_commitish', 'generate_release_notes', 'previous_tag', 'discussion_category_name', 'make_latest', 'token', 'repository'], outputs: ['url', 'id', 'upload_url', 'assets'] },
  'deploy-pages': { name: 'Deploy Pages', desc: 'Deploy static files to GitHub Pages via branch push. Replaces peaceiris/actions-gh-pages.', inputs: ['token', 'deploy_key', 'publish_dir', 'publish_branch', 'destination_dir', 'external_repository', 'allow_empty_commit', 'keep_files', 'force_orphan', 'user_name', 'user_email', 'commit_message', 'full_commit_message', 'tag_name', 'tag_message', 'enable_jekyll', 'cname', 'exclude_assets'], outputs: ['deploy_branch', 'commit_hash'] },
  'deploy-pages-api': { name: 'Deploy Pages (API)', desc: 'Deploy to GitHub Pages using the Pages deployment API with OIDC authentication.', inputs: ['token', 'timeout', 'error_count', 'reporting_interval', 'artifact_name'], outputs: ['page_url'] },
  'upload-pages-artifact': { name: 'Upload Pages Artifact', desc: 'Package and upload a directory as a GitHub Pages deployment artifact.', inputs: ['path', 'retention-days'], outputs: ['artifact-id'] },
  'codeql-init': { name: 'CodeQL Init', desc: 'Initialize CodeQL databases for security analysis.', inputs: ['languages', 'config-file', 'queries', 'tools', 'token'], outputs: ['codeql-path'] },
  'codeql-autobuild': { name: 'CodeQL Autobuild', desc: 'Auto-detect and build the project for CodeQL analysis.', inputs: ['language', 'build-command'], outputs: [] },
  'codeql-analyze': { name: 'CodeQL Analyze', desc: 'Run CodeQL analysis and upload SARIF results to GitHub Code Scanning.', inputs: ['category', 'output', 'upload', 'token'], outputs: ['sarif-output'] },
  'upload-artifact': { name: 'Upload Artifact', desc: 'Upload build artifacts from a workflow run with glob support and compression.', inputs: ['name', 'path', 'retention-days', 'if-no-files-found', 'compression-level', 'overwrite'], outputs: ['artifact-id', 'artifact-url'] },
  'download-artifact': { name: 'Download Artifact', desc: 'Download artifacts from a workflow run with cross-run and merge support.', inputs: ['name', 'path', 'merge-multiple', 'run-id', 'github-token'], outputs: ['download-path'] },
  'configure-pages': { name: 'Configure Pages', desc: 'Configure GitHub Pages and output site URL metadata for deployment workflows.', inputs: ['token', 'enablement', 'static_site_generator'], outputs: ['base_url', 'origin', 'host', 'base_path'] },
};

function actionHtml(slug: string): string {
  const a = actions[slug];
  return renderToStaticMarkup(h('div', null,
    h('h2', null, a.name), h('p', null, a.desc),
    h('h3', null, 'Usage'), h('pre', null, h('code', null, `- uses: asymmetric-effort/actions/actions/${slug}@v1`)),
    h('h3', null, 'Inputs'), h('ul', null, ...a.inputs.map(i => h('li', null, h('code', null, i)))),
    h('h3', null, 'Outputs'), h('ul', null, ...a.outputs.map(o => h('li', null, h('code', null, o)))),
  ));
}

export default defineConfig({
  base: '/',
  define: { '__APP_VERSION__': JSON.stringify(version) },
  plugins: [
    specifyJsSeoPlugin({
      siteUrl: 'https://actions.asymmetric-effort.com',
      title: 'Asymmetric Effort Actions',
      description: 'Secure, self-contained GitHub Actions for building, scanning, and releasing your projects. Zero third-party dependencies.',
      routes: ['/', ...Object.keys(actions).map(s => `/#${s}`), '/#security'],
      author: 'Asymmetric Effort, LLC',
      license: 'MIT',
      repository: 'https://github.com/asymmetric-effort/actions',
    }),
    specifyJsNoscriptPlugin({
      title: 'Asymmetric Effort Actions',
      description: 'Secure, self-contained GitHub Actions. Zero third-party dependencies.',
      sections: [
        { id: 'home', title: 'Home', html: renderToStaticMarkup(h('div', null, h('h1', null, 'Asymmetric Effort Actions'), h('p', null, `Version ${version}. All actions are pure bash composites with zero third-party dependencies.`), h('ul', null, ...Object.keys(actions).map(s => h('li', null, h('a', { href: `#${s}` }, actions[s].name), ' \u2014 ', actions[s].desc))))) },
        ...Object.keys(actions).map(s => ({ id: s, title: actions[s].name, html: actionHtml(s) })),
        { id: 'security', title: 'Security', html: renderToStaticMarkup(h('div', null, h('h2', null, 'Security'), h('p', null, 'Best practices for using these actions.'), h('h3', null, 'Handling Secrets'), h('ul', null, h('li', null, 'Never hardcode API keys or tokens.'), h('li', null, 'Use ${{ secrets.YOUR_SECRET }}.'), h('li', null, 'Rotate secrets regularly.')), h('h3', null, 'Reporting Vulnerabilities'), h('p', null, 'Report to security@asymmetric-effort.com.'))) },
      ],
      copyright: '\u00A9 2025-2026 Asymmetric Effort, LLC. MIT License.',
    }),
  ],
  build: { outDir: 'dist', emptyOutDir: true },
  server: { port: 3000 },
});
