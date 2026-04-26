export function Header(parent: HTMLElement): void {
  const header = document.createElement('header');
  header.className = 'site-header';

  header.innerHTML = `
    <div class="header-inner">
      <span class="header-title">Asymmetric Effort Actions</span>
      <span class="header-links">
        <a href="https://github.com/asymmetric-effort/actions" target="_blank" rel="noopener">GitHub</a>
        <a href="https://asymmetric-effort.com" target="_blank" rel="noopener">Asymmetric Effort</a>
      </span>
    </div>
  `;

  parent.appendChild(header);
}
