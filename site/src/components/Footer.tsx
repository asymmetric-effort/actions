import { createElement } from '@asymmetric-effort/specifyjs';

export function Footer(): ReturnType<typeof createElement> {
  const year = new Date().getFullYear();

  return createElement('footer', { className: 'site-footer' },
    createElement('div', { className: 'footer-inner' },
      createElement('div', { className: 'footer-links' },
        createElement('a', { href: 'https://github.com/asymmetric-effort/actions', target: '_blank', rel: 'noopener' }, 'GitHub Repository'),
        createElement('a', { href: 'https://github.com/asymmetric-effort/actions/issues', target: '_blank', rel: 'noopener' }, 'Report an Issue'),
        createElement('a', { href: 'https://github.com/asymmetric-effort/actions/blob/main/LICENSE', target: '_blank', rel: 'noopener' }, 'License'),
        createElement('a', { href: 'https://asymmetric-effort.com', target: '_blank', rel: 'noopener' }, 'Asymmetric Effort'),
      ),
      createElement('div', null, `\u00A9 ${year} Asymmetric Effort, LLC. All rights reserved.`),
      createElement('div', { className: 'footer-version' }, `v${__APP_VERSION__}`),
    ),
  );
}
