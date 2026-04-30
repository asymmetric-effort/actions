#!/usr/bin/env node
/**
 * prerender.mjs — Static pre-rendering for SEO.
 *
 * Uses renderToStaticMarkup from @asymmetric-effort/specifyjs/server
 * to render all routes to static HTML at build time. The pre-rendered
 * content is injected into the built index.html so search engines
 * see full page content without executing JavaScript.
 *
 * The client-side JS then takes over for interactive navigation.
 */

import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { createElement } from '@asymmetric-effort/specifyjs';
import { renderToStaticMarkup } from '@asymmetric-effort/specifyjs/server';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DIST = resolve(__dirname, '../dist');
const VERSION = readFileSync(resolve(__dirname, '../../VERSION'), 'utf-8').trim();
const SITE_URL = 'https://actions.asymmetric-effort.com';

// ─── Route metadata ─────────────────────────────────────────────

const routes = [
  {
    slug: 'home',
    title: 'Asymmetric Effort Actions',
    description: 'Secure, self-contained GitHub Actions for building, scanning, and releasing your projects. Zero third-party dependencies.',
  },
  {
    slug: 'setup-bun',
    title: 'Setup Bun — Asymmetric Effort Actions',
    description: 'Install and configure the Bun JavaScript runtime in GitHub Actions with version pinning and caching.',
  },
  {
    slug: 'fossa-scan',
    title: 'FOSSA Scan — Asymmetric Effort Actions',
    description: 'Run FOSSA license compliance and security scanning in your CI pipeline.',
  },
  {
    slug: 'gh-release',
    title: 'GitHub Release — Asymmetric Effort Actions',
    description: 'Create or update GitHub Releases with asset uploads and auto-generated notes.',
  },
  {
    slug: 'go-tooling',
    title: 'Go Tooling — Asymmetric Effort Actions',
    description: 'Install the complete Go toolchain with govulncheck and intelligent caching.',
  },
  {
    slug: 'build-pkg-rpm',
    title: 'Build RPM Package — Asymmetric Effort Actions',
    description: 'Build RPM packages from a spec file or inline metadata for RHEL, Fedora, and CentOS.',
  },
  {
    slug: 'build-pkg-deb',
    title: 'Build DEB Package — Asymmetric Effort Actions',
    description: 'Build Debian .deb packages from a control file or inline metadata for Ubuntu and Debian.',
  },
  {
    slug: 'npm-publish',
    title: 'NPM Publish — Asymmetric Effort Actions',
    description: 'Publish to npm using OIDC trusted publisher. No long-lived NPM_TOKEN secret required.',
  },
  {
    slug: 'security',
    title: 'Security — Asymmetric Effort Actions',
    description: 'Security best practices for using Asymmetric Effort GitHub Actions.',
  },
];

// ─── Action data for pre-rendering ──────────────────────────────

const actions = {
  'setup-bun': {
    name: 'Setup Bun', badge: 'Runtime',
    desc: 'Install and configure the Bun JavaScript runtime in your GitHub Actions workflows. Supports version pinning, version files, and binary caching for fast CI builds.',
    inputs: ['bun-version', 'bun-version-file', 'no-cache', 'token'],
    outputs: ['bun-version', 'bun-path', 'cache-hit'],
  },
  'fossa-scan': {
    name: 'FOSSA Scan', badge: 'Security',
    desc: 'Run FOSSA license compliance and security scanning in your CI pipeline. Automatically installs the FOSSA CLI, runs analysis, and optionally tests for policy violations.',
    inputs: ['api-key', 'run-tests', 'endpoint', 'project', 'branch', 'working-directory', 'cli-version', 'debug'],
    outputs: ['test-result'],
  },
  'gh-release': {
    name: 'GitHub Release', badge: 'Release',
    desc: 'Create or update GitHub Releases with asset uploads. Supports draft releases, prereleases, auto-generated release notes, and glob-based file uploads.',
    inputs: ['tag_name', 'name', 'body', 'body_path', 'draft', 'prerelease', 'files', 'working_directory', 'overwrite_files', 'fail_on_unmatched_files', 'target_commitish', 'generate_release_notes', 'make_latest', 'token', 'repository'],
    outputs: ['url', 'id', 'upload_url', 'assets'],
  },
  'go-tooling': {
    name: 'Go Tooling', badge: 'Toolchain',
    desc: 'Install and configure the complete Go toolchain with govulncheck and intelligent caching.',
    inputs: ['go-version', 'go-version-file', 'govulncheck-version', 'no-cache', 'token', 'cache-key-suffix'],
    outputs: ['go-version', 'go-path', 'govulncheck-version', 'cache-hit'],
  },
  'build-pkg-rpm': {
    name: 'Build RPM Package', badge: 'Packaging',
    desc: 'Build RPM packages from a spec file or inline metadata for RHEL, Fedora, and CentOS.',
    inputs: ['spec-file', 'name', 'version', 'release', 'arch', 'summary', 'license', 'source-dir', 'install-prefix', 'output-dir', 'requires', 'scripts-pre', 'scripts-post'],
    outputs: ['rpm-path', 'rpm-name'],
  },
  'build-pkg-deb': {
    name: 'Build DEB Package', badge: 'Packaging',
    desc: 'Build Debian .deb packages from a control file or inline metadata for Ubuntu and Debian.',
    inputs: ['control-file', 'name', 'version', 'arch', 'maintainer', 'summary', 'section', 'priority', 'source-dir', 'install-prefix', 'output-dir', 'depends', 'scripts-preinst', 'scripts-postinst'],
    outputs: ['deb-path', 'deb-name'],
  },
  'npm-publish': {
    name: 'NPM Publish', badge: 'Publishing',
    desc: 'Publish to npm using OIDC trusted publisher. No long-lived NPM_TOKEN secret required.',
    inputs: ['package-dir', 'tag', 'access', 'dry-run', 'registry', 'provenance'],
    outputs: ['version', 'package', 'registry-url'],
  },
};

// ─── Build static HTML for each action ──────────────────────────

function renderActionSection(slug, action) {
  const h = createElement;
  return h('section', { id: slug },
    h('h2', null, action.name),
    h('p', null, action.desc),
    h('h3', null, 'Usage'),
    h('pre', null, h('code', null, `- uses: asymmetric-effort/actions/actions/${slug}@v1`)),
    h('h3', null, 'Inputs'),
    h('ul', null, ...action.inputs.map(i => h('li', null, h('code', null, i)))),
    h('h3', null, 'Outputs'),
    h('ul', null, ...action.outputs.map(o => h('li', null, h('code', null, o)))),
  );
}

function renderSecuritySection() {
  const h = createElement;
  return h('section', { id: 'security' },
    h('h2', null, 'Security'),
    h('p', null, 'Best practices and security considerations when using these actions.'),
    h('h3', null, 'Handling Secrets'),
    h('ul', null,
      h('li', null, 'Never hardcode API keys or tokens in your workflow files.'),
      h('li', null, 'Always use ${{ secrets.YOUR_SECRET }} to reference sensitive values.'),
      h('li', null, 'Rotate secrets regularly and use the minimum required permissions.'),
    ),
    h('h3', null, 'Token Permissions'),
    h('p', null, 'All actions that accept a token input default to ${{ github.token }}.'),
    h('h3', null, 'Pinning Action Versions'),
    h('p', null, 'For production workflows, pin actions to a specific commit SHA.'),
    h('h3', null, 'Reporting Vulnerabilities'),
    h('p', null, 'Report vulnerabilities to security@asymmetric-effort.com.'),
  );
}

function renderFullPage() {
  const h = createElement;

  const navLinks = routes.map(r =>
    h('a', { href: `#${r.slug}` }, r.slug === 'home' ? 'Home' : r.slug === 'security' ? 'Security' : r.slug)
  );

  const actionSections = Object.keys(actions).map(slug =>
    renderActionSection(slug, actions[slug])
  );

  return h('div', { id: 'prerendered-content' },
    h('header', null,
      h('h1', null, 'Asymmetric Effort Actions'),
      h('p', null, 'Secure, self-contained GitHub Actions for building, scanning, and releasing your projects. Zero third-party dependencies.'),
    ),
    h('nav', { 'aria-label': 'Site navigation' },
      ...navLinks,
    ),
    h('main', null,
      h('section', { id: 'home' },
        h('h2', null, 'Available Actions'),
        h('p', null, `Version ${VERSION}. All actions are pure bash composites with zero third-party dependencies.`),
        h('ul', null,
          ...Object.keys(actions).map(slug =>
            h('li', null, h('a', { href: `#${slug}` }, actions[slug].name), ' — ', actions[slug].desc)
          ),
        ),
      ),
      ...actionSections,
      renderSecuritySection(),
    ),
    h('footer', null,
      h('p', null, `Actions v${VERSION}`),
      h('p', null, '\u00A9 2025-2026 Asymmetric Effort, LLC. MIT License.'),
      h('a', { href: 'https://github.com/asymmetric-effort/actions' }, 'GitHub Repository'),
    ),
  );
}

// ─── Main ────────────────────────────────────────────────────────

function buildMetaTags() {
  const tags = [];
  tags.push(`<meta name="author" content="Asymmetric Effort, LLC">`);
  tags.push(`<meta name="description" content="${routes[0].description}">`);
  tags.push(`<meta property="og:title" content="${routes[0].title}">`);
  tags.push(`<meta property="og:description" content="${routes[0].description}">`);
  tags.push(`<meta property="og:type" content="website">`);
  tags.push(`<meta property="og:site_name" content="Asymmetric Effort Actions">`);
  tags.push(`<meta property="og:url" content="${SITE_URL}">`);
  tags.push(`<meta name="twitter:card" content="summary">`);
  tags.push(`<meta name="twitter:title" content="${routes[0].title}">`);
  tags.push(`<meta name="twitter:description" content="${routes[0].description}">`);
  tags.push(`<link rel="canonical" href="${SITE_URL}">`);
  return tags.join('\n    ');
}

function main() {
  const indexPath = resolve(DIST, 'index.html');
  let html = readFileSync(indexPath, 'utf-8');

  // Render the full static content
  const staticContent = renderToStaticMarkup(renderFullPage());

  // Build meta tags
  const metaTags = buildMetaTags();

  // Inject meta tags into <head>
  html = html.replace('</head>', `    ${metaTags}\n  </head>`);

  // Inject pre-rendered content for search engines:
  // 1. <noscript> block — visible to crawlers that don't run JS
  // 2. JSON-LD structured data — machine-readable site metadata
  const jsonLd = JSON.stringify({
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: 'Asymmetric Effort Actions',
    url: SITE_URL,
    description: routes[0].description,
    publisher: {
      '@type': 'Organization',
      name: 'Asymmetric Effort, LLC',
      url: 'https://asymmetric-effort.com',
    },
    version: VERSION,
    license: 'https://github.com/asymmetric-effort/actions/blob/main/LICENSE',
  });

  const prerenderedBlock = `
    <noscript>
      <style>#root { display: none; }</style>
      ${staticContent}
    </noscript>
    <script type="application/ld+json">${jsonLd}</script>`;

  // Insert before the closing </body>
  html = html.replace('</body>', `${prerenderedBlock}\n  </body>`);

  writeFileSync(indexPath, html, 'utf-8');

  console.log(`Pre-rendered ${routes.length} routes into ${indexPath}`);
  console.log(`  Meta tags: OG, Twitter Card, canonical, description`);
  console.log(`  Static content: ${(staticContent.length / 1024).toFixed(1)} KB`);
}

main();
