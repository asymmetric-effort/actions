import { createElement } from '@asymmetric-effort/specifyjs';
import { Footer as SpecFooter } from '@asymmetric-effort/specifyjs/components';

export function Footer(): ReturnType<typeof createElement> {
  const year = new Date().getFullYear();

  const links = createElement('div', { className: 'footer-links' },
    createElement('a', { href: 'https://github.com/asymmetric-effort/actions', target: '_blank', rel: 'noopener' }, 'GitHub Repository'),
    createElement('a', { href: 'https://github.com/asymmetric-effort/actions/issues', target: '_blank', rel: 'noopener' }, 'Report an Issue'),
    createElement('a', { href: 'https://github.com/asymmetric-effort/actions/blob/main/LICENSE', target: '_blank', rel: 'noopener' }, 'License'),
    createElement('a', { href: 'https://asymmetric-effort.com', target: '_blank', rel: 'noopener' }, 'Asymmetric Effort'),
  );

  const copyright = createElement('div', null,
    `\u00A9 ${year} Asymmetric Effort, LLC. All rights reserved.`,
  );

  const version = createElement('div', { className: 'footer-version' },
    `v${__APP_VERSION__}`,
  );

  return createElement(SpecFooter, {
    center: createElement('div', null, links, copyright, version),
    background: 'var(--color-bg-alt)',
    color: 'var(--color-text-muted)',
    borderTop: '1px solid var(--color-border)',
    fontSize: '14px',
    padding: '24px',
    ariaLabel: 'Site footer',
  });
}
