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
    createElement('div', { style: 'display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px;margin-top:32px;' },
      ...cards.map((card) =>
        createElement(ActionCard, { key: card.slug, card }),
      ),
    ),
  );
}
