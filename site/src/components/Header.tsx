import { createElement } from '@asymmetric-effort/specifyjs';

export function Header(): ReturnType<typeof createElement> {
  return createElement('header', { className: 'site-header' },
    createElement('div', { className: 'header-inner' },
      createElement('span', { className: 'header-title' }, 'Asymmetric Effort Actions'),
      createElement('span', { className: 'header-links' },
        createElement('a', { href: 'https://github.com/asymmetric-effort/actions', target: '_blank', rel: 'noopener' }, 'GitHub'),
        createElement('a', { href: 'https://asymmetric-effort.com', target: '_blank', rel: 'noopener' }, 'Asymmetric Effort'),
      ),
    ),
  );
}
