import { createElement } from '@asymmetric-effort/specifyjs';
import type { Route } from '../App';

interface NavigationProps {
  route: Route;
  onNavigate: (route: Route) => void;
}

const links: { label: string; route: Route }[] = [
  { label: 'Home', route: 'home' },
  { label: 'setup-bun', route: 'setup-bun' },
  { label: 'fossa-scan', route: 'fossa-scan' },
  { label: 'gh-release', route: 'gh-release' },
  { label: 'Security', route: 'security' },
];

export function Navigation(props: NavigationProps): ReturnType<typeof createElement> {
  return createElement('nav', { className: 'site-nav' },
    createElement('div', { className: 'nav-inner' },
      ...links.map(({ label, route }) =>
        createElement('a', {
          key: route,
          className: 'nav-link' + (props.route === route ? ' active' : ''),
          href: `#${route}`,
          onClick: (e: Event) => {
            e.preventDefault();
            window.location.hash = route;
            props.onNavigate(route);
          },
        }, label),
      ),
    ),
  );
}
