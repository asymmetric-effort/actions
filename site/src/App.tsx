import { createElement, useState, useEffect } from '@asymmetric-effort/specifyjs';
import { injectStyles } from './styles';
import { Header } from './components/Header';
import { Navigation } from './components/Navigation';
import { HomePage } from './components/HomePage';
import { ActionDocs } from './components/ActionDocs';
import { SecurityPage } from './components/SecurityPage';
import { Footer } from './components/Footer';

export type Route = 'home' | 'setup-bun' | 'fossa-scan' | 'gh-release' | 'security';

function getRoute(): Route {
  const hash = window.location.hash.replace('#', '') || 'home';
  const valid: Route[] = ['home', 'setup-bun', 'fossa-scan', 'gh-release', 'security'];
  return valid.includes(hash as Route) ? (hash as Route) : 'home';
}

export function App(): ReturnType<typeof createElement> {
  injectStyles();

  const [route, setRoute] = useState<Route>(getRoute);

  useEffect(() => {
    const handler = (): void => {
      setRoute(getRoute());
      window.scrollTo(0, 0);
    };
    window.addEventListener('hashchange', handler);
    return () => window.removeEventListener('hashchange', handler);
  }, []);

  let content: ReturnType<typeof createElement>;
  switch (route) {
    case 'setup-bun':
    case 'fossa-scan':
    case 'gh-release':
      content = createElement(ActionDocs, { slug: route });
      break;
    case 'security':
      content = createElement(SecurityPage, null);
      break;
    default:
      content = createElement(HomePage, null);
  }

  return createElement('div', { className: 'site-wrapper' },
    createElement(Header, null),
    createElement(Navigation, { route, onNavigate: setRoute }),
    createElement('main', { className: 'site-main' }, content),
    createElement(Footer, null),
  );
}
