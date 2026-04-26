import { injectStyles } from './styles';
import { Header } from './components/Header';
import { Navigation, getRoute, updateNavActive, Route } from './components/Navigation';
import { ActionDocs, HomePage, SecurityPage } from './components/ActionDocs';
import { Footer } from './components/Footer';

export function App(root: HTMLElement): void {
  injectStyles();

  // Build the shell (header, nav, content area, footer)
  Header(root);

  const contentContainer = document.createElement('main');
  contentContainer.className = 'site-main';

  const renderRoute = (route: Route): void => {
    contentContainer.innerHTML = '';
    updateNavActive(route);

    switch (route) {
      case 'home':
        HomePage(contentContainer);
        break;
      case 'setup-bun':
      case 'fossa-scan':
      case 'gh-release':
        ActionDocs(contentContainer, route);
        break;
      case 'security':
        SecurityPage(contentContainer);
        break;
      default:
        HomePage(contentContainer);
    }

    window.scrollTo(0, 0);
  };

  Navigation(root, renderRoute);
  root.appendChild(contentContainer);
  Footer(root);

  // Render the initial route
  renderRoute(getRoute());

  // Listen for back/forward navigation
  window.addEventListener('hashchange', () => {
    renderRoute(getRoute());
  });
}
