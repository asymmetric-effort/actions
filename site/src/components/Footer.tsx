import { createElement } from '@asymmetric-effort/specifyjs';
import { Footer as SpecFooter } from '@asymmetric-effort/specifyjs/components';

export function Footer(): ReturnType<typeof createElement> {
  const left = createElement('span', null, `Actions v${__APP_VERSION__}`);

  const center = createElement('span', null,
    '\u00A9 2025-2026 ',
    createElement('a', {
      href: 'https://asymmetric-effort.com',
      style: 'color: rgb(59, 130, 246); text-decoration: none;',
    }, 'Asymmetric Effort, LLC'),
    '. MIT License.',
  );

  const right = createElement('a', {
    href: 'https://github.com/asymmetric-effort/actions',
    style: 'color: rgb(59, 130, 246); text-decoration: none;',
  }, 'GitHub Repository');

  return createElement(SpecFooter, {
    left,
    center,
    right,
    borderTop: '1px solid var(--color-border, #e2e8f0)',
    background: 'var(--color-bg, transparent)',
    color: 'var(--color-text-muted, #64748b)',
    fontSize: '13px',
    padding: '24px',
    ariaLabel: 'Site footer',
  });
}
