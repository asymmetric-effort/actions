/**
 * SEO metadata management — sets document title, meta description,
 * Open Graph tags, and canonical URL. Mirrors the SpecifyJS useHead
 * API but works without hooks (workaround for hook dispatcher bug
 * in published npm package).
 *
 * Call setPageMeta() on each route change to update head tags.
 */

interface PageMeta {
  title: string;
  description: string;
  canonical?: string;
  og?: Record<string, string>;
}

const BASE_TITLE = 'Asymmetric Effort Actions';
const SITE_URL = 'https://actions.asymmetric-effort.com';

function setMetaTag(attr: string, key: string, content: string): void {
  const selector = `meta[${attr}="${key}"]`;
  let el = document.querySelector(selector) as HTMLMetaElement | null;
  if (!el) {
    el = document.createElement('meta');
    el.setAttribute(attr, key);
    document.head.appendChild(el);
  }
  el.content = content;
}

function setCanonical(href: string): void {
  let el = document.querySelector('link[rel="canonical"]') as HTMLLinkElement | null;
  if (!el) {
    el = document.createElement('link');
    el.rel = 'canonical';
    document.head.appendChild(el);
  }
  el.href = href;
}

export function setPageMeta(meta: PageMeta): void {
  document.title = meta.title ? `${meta.title} — ${BASE_TITLE}` : BASE_TITLE;

  setMetaTag('name', 'description', meta.description);
  setMetaTag('name', 'author', 'Asymmetric Effort, LLC');

  // Open Graph
  setMetaTag('property', 'og:title', meta.title || BASE_TITLE);
  setMetaTag('property', 'og:description', meta.description);
  setMetaTag('property', 'og:type', 'website');
  setMetaTag('property', 'og:site_name', BASE_TITLE);

  if (meta.og) {
    const keys = Object.keys(meta.og);
    let i = 0;
    while (i < keys.length) {
      setMetaTag('property', `og:${keys[i]}`, meta.og[keys[i]]);
      i += 1;
    }
  }

  // Twitter card
  setMetaTag('name', 'twitter:card', 'summary');
  setMetaTag('name', 'twitter:title', meta.title || BASE_TITLE);
  setMetaTag('name', 'twitter:description', meta.description);

  // Canonical URL
  const canonical = meta.canonical || SITE_URL;
  setCanonical(canonical);
}

export const routeMeta: Record<string, PageMeta> = {
  'home': {
    title: '',
    description: 'Secure, self-contained GitHub Actions for building, scanning, and releasing your projects. Zero third-party dependencies.',
    canonical: SITE_URL,
  },
  'setup-bun': {
    title: 'Setup Bun',
    description: 'Install and configure the Bun JavaScript runtime in GitHub Actions with version pinning, caching, and go.mod support.',
    canonical: `${SITE_URL}/#setup-bun`,
  },
  'fossa-scan': {
    title: 'FOSSA Scan',
    description: 'Run FOSSA license compliance and security scanning in your CI pipeline. Automatically installs the FOSSA CLI.',
    canonical: `${SITE_URL}/#fossa-scan`,
  },
  'gh-release': {
    title: 'GitHub Release',
    description: 'Create or update GitHub Releases with asset uploads, auto-generated notes, and glob-based file matching.',
    canonical: `${SITE_URL}/#gh-release`,
  },
  'go-tooling': {
    title: 'Go Tooling',
    description: 'Install the complete Go toolchain with govulncheck and intelligent caching for fast CI builds.',
    canonical: `${SITE_URL}/#go-tooling`,
  },
  'build-pkg-rpm': {
    title: 'Build RPM Package',
    description: 'Build RPM packages from a spec file or inline metadata for RHEL, Fedora, and CentOS.',
    canonical: `${SITE_URL}/#build-pkg-rpm`,
  },
  'build-pkg-deb': {
    title: 'Build DEB Package',
    description: 'Build Debian .deb packages from a control file or inline metadata for Ubuntu and Debian.',
    canonical: `${SITE_URL}/#build-pkg-deb`,
  },
  'npm-publish': {
    title: 'NPM Publish',
    description: 'Publish to npm using OIDC trusted publisher. No long-lived NPM_TOKEN secret required.',
    canonical: `${SITE_URL}/#npm-publish`,
  },
  'release': {
    title: 'Release',
    description: 'Full-featured GitHub Release management with asset uploads, auto-generated notes, and discussion linking.',
    canonical: `${SITE_URL}/#release`,
  },
  'deploy-pages': {
    title: 'Deploy Pages',
    description: 'Deploy static files to GitHub Pages via branch push with custom domains, deploy keys, and orphan branches.',
    canonical: `${SITE_URL}/#deploy-pages`,
  },
  'checkout': {
    title: 'Checkout',
    description: 'Check out repository source code with support for shallow clones, submodules, LFS, and credential management. Replaces actions/checkout.',
    canonical: `${SITE_URL}/#checkout`,
  },
  'setup-go': {
    title: 'Setup Go',
    description: 'Install and configure the Go toolchain with version resolution, module caching, and go.mod support. Replaces actions/setup-go.',
    canonical: `${SITE_URL}/#setup-go`,
  },
  'setup-node': {
    title: 'Setup Node.js',
    description: 'Install and configure Node.js with version resolution, LTS support, npm/yarn/pnpm caching, and registry configuration. Replaces actions/setup-node.',
    canonical: `${SITE_URL}/#setup-node`,
  },
  'setup-python': {
    title: 'Setup Python',
    description: 'Install and configure the Python runtime with version resolution, tool cache support, and pip/pipenv/poetry caching. Replaces actions/setup-python.',
    canonical: `${SITE_URL}/#setup-python`,
  },
  'upload-pages-artifact': {
    title: 'Upload Pages Artifact',
    description: 'Package and upload a directory as a GitHub Pages deployment artifact with automatic .nojekyll injection. Replaces actions/upload-pages-artifact.',
    canonical: `${SITE_URL}/#upload-pages-artifact`,
  },
  'deploy-pages-api': {
    title: 'Deploy Pages (API)',
    description: 'Deploy to GitHub Pages using the Pages deployment API with OIDC authentication and status polling. Replaces actions/deploy-pages.',
    canonical: `${SITE_URL}/#deploy-pages-api`,
  },
  'codeql-init': {
    title: 'CodeQL Init',
    description: 'Initialize CodeQL databases for security analysis. Downloads CodeQL CLI and creates databases for specified languages. Replaces github/codeql-action/init.',
    canonical: `${SITE_URL}/#codeql-init`,
  },
  'codeql-autobuild': {
    title: 'CodeQL Autobuild',
    description: 'Auto-detect and build the project for CodeQL analysis with support for Go, JavaScript, Java, C/C++, and more. Replaces github/codeql-action/autobuild.',
    canonical: `${SITE_URL}/#codeql-autobuild`,
  },
  'codeql-analyze': {
    title: 'CodeQL Analyze',
    description: 'Run CodeQL analysis and upload SARIF results to GitHub Code Scanning. Replaces github/codeql-action/analyze.',
    canonical: `${SITE_URL}/#codeql-analyze`,
  },
  'upload-artifact': {
    title: 'Upload Artifact',
    description: 'Upload build artifacts from a workflow run with glob patterns, compression control, and retention settings. Replaces actions/upload-artifact.',
    canonical: `${SITE_URL}/#upload-artifact`,
  },
  'download-artifact': {
    title: 'Download Artifact',
    description: 'Download artifacts from a workflow run with cross-run and merge-multiple support. Replaces actions/download-artifact.',
    canonical: `${SITE_URL}/#download-artifact`,
  },
  'configure-pages': {
    title: 'Configure Pages',
    description: 'Configure GitHub Pages and output site URL metadata for deployment workflows. Replaces actions/configure-pages.',
    canonical: `${SITE_URL}/#configure-pages`,
  },
  'security': {
    title: 'Security',
    description: 'Security best practices for using Asymmetric Effort GitHub Actions. Handling secrets, token permissions, and version pinning.',
    canonical: `${SITE_URL}/#security`,
  },
};
