import { createElement } from '@asymmetric-effort/specifyjs';

const LOGO_SVG = `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="18" fill="#0969da"/><text x="50" y="50" text-anchor="middle" dominant-baseline="central" font-family="serif" font-size="72" font-weight="bold" fill="white">\u0394</text></svg>')}`;

export function Header(): ReturnType<typeof createElement> {
  return createElement('header', { className: 'site-header' },
    createElement('div', { className: 'header-inner' },
      createElement('a', { href: '#home', className: 'header-brand' },
        createElement('img', { src: LOGO_SVG, alt: 'Actions', className: 'header-logo' }),
        createElement('span', { className: 'header-title' }, 'Asymmetric Effort Actions'),
      ),
      createElement('span', { className: 'header-links' },
        createElement('a', { href: 'https://github.com/asymmetric-effort/actions', target: '_blank', rel: 'noopener' }, 'GitHub'),
        createElement('a', { href: 'https://asymmetric-effort.com', target: '_blank', rel: 'noopener' }, 'Asymmetric Effort'),
      ),
    ),
  );
}
