export function Footer(parent: HTMLElement): void {
  const footer = document.createElement('footer');
  footer.className = 'site-footer';

  const year = new Date().getFullYear();

  footer.innerHTML = `
    <div class="footer-inner">
      <div class="footer-links">
        <a href="https://github.com/asymmetric-effort/actions" target="_blank" rel="noopener">GitHub Repository</a>
        <a href="https://github.com/asymmetric-effort/actions/issues" target="_blank" rel="noopener">Report an Issue</a>
        <a href="https://github.com/asymmetric-effort/actions/blob/main/LICENSE" target="_blank" rel="noopener">License</a>
        <a href="https://asymmetric-effort.com" target="_blank" rel="noopener">Asymmetric Effort</a>
      </div>
      <div>&copy; ${year} Asymmetric Effort, LLC. All rights reserved.</div>
    </div>
  `;

  parent.appendChild(footer);
}
