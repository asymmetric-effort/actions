import { createElement } from '@asymmetric-effort/specifyjs';
import { render } from '@asymmetric-effort/specifyjs/dom';
import { App } from './App';
import { injectStyles } from './styles';

injectStyles();

const container = document.getElementById('root');
if (container) {
  render(createElement(App, null), container);
}
