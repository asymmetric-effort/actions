import { createElement } from '@asymmetric-effort/specifyjs';

interface CardInfo {
  slug: string;
  name: string;
  desc: string;
  badge: string;
  badgeColor: string;
}

const cards: CardInfo[] = [
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
  {
    slug: 'go-tooling',
    name: 'Go Tooling',
    desc: 'Install the complete Go toolchain with govulncheck and intelligent caching.',
    badge: 'Toolchain',
    badgeColor: 'badge-blue',
  },
  {
    slug: 'build-pkg-rpm',
    name: 'Build RPM Package',
    desc: 'Build RPM packages from a spec file or inline metadata for RHEL/Fedora/CentOS.',
    badge: 'Packaging',
    badgeColor: 'badge-orange',
  },
  {
    slug: 'build-pkg-deb',
    name: 'Build DEB Package',
    desc: 'Build Debian .deb packages from a control file or inline metadata for Ubuntu/Debian.',
    badge: 'Packaging',
    badgeColor: 'badge-green',
  },
  {
    slug: 'npm-publish',
    name: 'NPM Publish',
    desc: 'Publish to npm using OIDC trusted publisher. No NPM_TOKEN secret required.',
    badge: 'Publishing',
    badgeColor: 'badge-orange',
  },
  {
    slug: 'release',
    name: 'Release',
    desc: 'Full-featured GitHub Release management. Replaces softprops/action-gh-release.',
    badge: 'Release',
    badgeColor: 'badge-green',
  },
  {
    slug: 'deploy-pages',
    name: 'Deploy Pages',
    desc: 'Deploy static files to GitHub Pages via branch push. Replaces peaceiris/actions-gh-pages.',
    badge: 'Deployment',
    badgeColor: 'badge-blue',
  },
];

interface BenefitInfo {
  title: string;
  desc: string;
}

const benefits: BenefitInfo[] = [
  {
    title: 'Secure Supply Chain',
    desc: 'Every action is a clean-room implementation with zero third-party npm, pip, or Go dependencies. The only external references are official GitHub actions (actions/cache, actions/checkout). Fewer dependencies mean fewer attack vectors.',
  },
  {
    title: 'Intelligent Caching',
    desc: 'Actions like go-tooling and setup-bun cache toolchains, module downloads, and build artifacts across CI runs. Cache keys are scoped by OS, architecture, version, and dependency hash \u2014 so builds are fast and cache invalidation is precise.',
  },
  {
    title: 'Minimal and Focused',
    desc: 'Each action does one thing well. Pure bash composite actions with no build step, no transpilation, no bundled node_modules. The source code is the artifact \u2014 what you audit is what runs.',
  },
  {
    title: 'Reusable Across Repositories',
    desc: 'Reference any action from any repository in your organization. Caches are scoped per-repo automatically. Pin to a version tag or commit SHA for reproducible builds.',
  },
];

function ActionCard(props: { card: CardInfo }): ReturnType<typeof createElement> {
  const { card } = props;
  return createElement('a', {
    href: `#${card.slug}`,
    className: 'action-card action-card-link',
  },
    createElement('div', { className: 'action-card-header' },
      createElement('span', { className: `action-badge ${card.badgeColor}` }, card.badge),
      createElement('strong', null, card.name),
    ),
    createElement('div', { className: 'action-card-body' },
      createElement('p', { style: 'margin:0;color:var(--color-text-muted);font-size:14px;' }, card.desc),
    ),
  );
}

function WhyCard(): ReturnType<typeof createElement> {
  return createElement('div', { className: 'why-card' },
    createElement('h2', { className: 'why-card-title' }, 'Why self-contained actions?'),
    createElement('p', { className: 'why-card-intro' },
      'Third-party GitHub Actions are a supply chain risk. A compromised upstream action can exfiltrate secrets, inject code, or tamper with artifacts \u2014 and you may never know. These actions eliminate that risk entirely.',
    ),
    createElement('div', { className: 'why-card-grid' },
      ...benefits.map((b, i) =>
        createElement('div', { key: `b-${i}`, className: 'why-benefit' },
          createElement('h3', null, b.title),
          createElement('p', null, b.desc),
        ),
      ),
    ),
  );
}

export function HomePage(): ReturnType<typeof createElement> {
  return createElement('div', null,
    createElement('div', { className: 'hero' },
      createElement('h1', null, 'Asymmetric Effort Actions'),
      createElement('p', null, 'Secure, self-contained GitHub Actions for building, scanning, and releasing your projects. Zero third-party dependencies.'),
      createElement('div', { className: 'hero-actions' },
        createElement('a', { href: '#setup-bun', className: 'hero-btn hero-btn-primary' }, 'Get Started'),
        createElement('a', { href: 'https://github.com/asymmetric-effort/actions', target: '_blank', rel: 'noopener', className: 'hero-btn hero-btn-secondary' }, 'View on GitHub'),
      ),
    ),
    createElement(WhyCard, null),
    createElement('div', { style: 'display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px;margin-top:32px;' },
      ...cards.map((card) =>
        createElement(ActionCard, { key: card.slug, card }),
      ),
    ),
  );
}
