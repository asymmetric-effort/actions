import { createElement } from '@asymmetric-effort/specifyjs';
import { render } from '@asymmetric-effort/specifyjs/dom';
import { Header } from './components/Header';
import { Navigation } from './components/Navigation';
import { HomePage } from './components/HomePage';
import { ActionDocs } from './components/ActionDocs';
import { SecurityPage } from './components/SecurityPage';
import { Footer } from './components/Footer';
import { setPageMeta, routeMeta } from './seo';

export type Route = 'home' | 'setup-bun' | 'fossa-scan' | 'gh-release' | 'go-tooling' | 'build-pkg-rpm' | 'build-pkg-deb' | 'npm-publish' | 'release' | 'security';

function getRoute(): Route {
  const hash = window.location.hash.replace('#', '') || 'home';
  const valid: Route[] = ['home', 'setup-bun', 'fossa-scan', 'gh-release', 'go-tooling', 'build-pkg-rpm', 'build-pkg-deb', 'npm-publish', 'release', 'security'];
  return valid.includes(hash as Route) ? (hash as Route) : 'home';
}

function renderContent(route: Route): ReturnType<typeof createElement> {
  switch (route) {
    case 'setup-bun':
    case 'fossa-scan':
    case 'gh-release':
    case 'go-tooling':
    case 'build-pkg-rpm':
    case 'build-pkg-deb':
    case 'npm-publish':
    case 'release':
      return createElement(ActionDocs, { slug: route });
    case 'security':
      return createElement(SecurityPage, null);
    default:
      return createElement(HomePage, null);
  }
}

function renderApp(): void {
  const route = getRoute();
  setPageMeta(routeMeta[route] || routeMeta['home']);
  const container = document.getElementById('root');
  if (!container) return;

  const tree = createElement('div', { className: 'site-wrapper' },
    createElement(Header, null),
    createElement('div', { className: 'site-body' },
      createElement(Navigation, { route }),
      createElement('main', { className: 'site-main' }, renderContent(route)),
    ),
    createElement(Footer, null),
  );

  render(tree, container);
}

export function App(): ReturnType<typeof createElement> {
  const route = getRoute();
  setPageMeta(routeMeta[route] || routeMeta['home']);

  // Set up hash-based routing via DOM events (outside render cycle)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const win = window as any;
  if (typeof window !== 'undefined' && !win.__routerInit) {
    win.__routerInit = true;
    window.addEventListener('hashchange', () => {
      renderApp();
      window.scrollTo(0, 0);
    });
  }

  return createElement('div', { className: 'site-wrapper' },
    createElement(Header, null),
    createElement('div', { className: 'site-body' },
      createElement(Navigation, { route }),
      createElement('main', { className: 'site-main' }, renderContent(route)),
    ),
    createElement(Footer, null),
  );
}
