import { createElement } from '@asymmetric-effort/specifyjs';
import type { Route } from '../App';

interface NavigationProps {
  route: Route;
}

interface NavSection {
  heading: string;
  links: { label: string; route: Route }[];
}

const sections: NavSection[] = [
  {
    heading: '',
    links: [
      { label: 'Home', route: 'home' },
    ],
  },
  {
    heading: '',
    links: [
      { label: 'setup-bun', route: 'setup-bun' },
      { label: 'fossa-scan', route: 'fossa-scan' },
      { label: 'gh-release', route: 'gh-release' },
      { label: 'go-tooling', route: 'go-tooling' },
      { label: 'build-pkg-rpm', route: 'build-pkg-rpm' },
      { label: 'build-pkg-deb', route: 'build-pkg-deb' },
      { label: 'npm-publish', route: 'npm-publish' },
    ],
  },
  {
    heading: '',
    links: [
      { label: 'Security', route: 'security' },
    ],
  },
];

export function Navigation(props: NavigationProps): ReturnType<typeof createElement> {
  const children: ReturnType<typeof createElement>[] = [];

  let idx = 0;
  while (idx < sections.length) {
    const section = sections[idx];
    if (section.heading) {
      children.push(
        createElement('div', { key: `h-${idx}`, className: 'nav-section-heading' }, section.heading),
      );
    }
    let linkIdx = 0;
    while (linkIdx < section.links.length) {
      const { label, route } = section.links[linkIdx];
      children.push(
        createElement('a', {
          key: route,
          className: 'nav-link' + (props.route === route ? ' active' : ''),
          href: `#${route}`,
        }, label),
      );
      linkIdx += 1;
    }
    idx += 1;
  }

  return createElement('nav', { className: 'site-nav' },
    ...children,
  );
}
