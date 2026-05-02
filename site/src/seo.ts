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
  'security': {
    title: 'Security',
    description: 'Security best practices for using Asymmetric Effort GitHub Actions. Handling secrets, token permissions, and version pinning.',
    canonical: `${SITE_URL}/#security`,
  },
};
