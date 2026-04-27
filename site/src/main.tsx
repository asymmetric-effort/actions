import { createRoot } from '@asymmetric-effort/specifyjs/dom';
import { createElement } from '@asymmetric-effort/specifyjs';
import { App } from './App';

const container = document.getElementById('root');
if (container) {
  const root = createRoot(container);
  root.render(createElement(App, null));
}
