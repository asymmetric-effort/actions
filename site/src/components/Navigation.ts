export type Route = 'home' | 'setup-bun' | 'fossa-scan' | 'gh-release' | 'security';

export function getRoute(): Route {
  const hash = window.location.hash.replace('#', '') || 'home';
  const valid: Route[] = ['home', 'setup-bun', 'fossa-scan', 'gh-release', 'security'];
  return valid.includes(hash as Route) ? (hash as Route) : 'home';
}

export function Navigation(parent: HTMLElement, onNavigate: (route: Route) => void): void {
  const nav = document.createElement('nav');
  nav.className = 'site-nav';

  const inner = document.createElement('div');
  inner.className = 'nav-inner';

  const links: { label: string; route: Route }[] = [
    { label: 'Home', route: 'home' },
    { label: 'setup-bun', route: 'setup-bun' },
    { label: 'fossa-scan', route: 'fossa-scan' },
    { label: 'gh-release', route: 'gh-release' },
    { label: 'Security', route: 'security' },
  ];

  const currentRoute = getRoute();

  links.forEach(({ label, route }) => {
    const a = document.createElement('a');
    a.className = 'nav-link' + (currentRoute === route ? ' active' : '');
    a.href = `#${route}`;
    a.textContent = label;
    a.addEventListener('click', (e) => {
      e.preventDefault();
      window.location.hash = route;
      onNavigate(route);
    });
    inner.appendChild(a);
  });

  nav.appendChild(inner);
  parent.appendChild(nav);
}

export function updateNavActive(route: Route): void {
  document.querySelectorAll('.nav-link').forEach((el) => {
    const href = (el as HTMLAnchorElement).getAttribute('href');
    el.classList.toggle('active', href === `#${route}`);
  });
}
