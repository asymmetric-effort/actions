export function injectStyles(): void {
  const style = document.createElement('style');
  style.textContent = `
    :root {
      --color-bg: #ffffff;
      --color-bg-alt: #f8f9fa;
      --color-bg-code: #f1f3f5;
      --color-text: #212529;
      --color-text-muted: #6c757d;
      --color-primary: #0969da;
      --color-primary-dark: #0550ae;
      --color-border: #d0d7de;
      --color-border-light: #e8ecf0;
      --color-success: #1a7f37;
      --color-warning: #9a6700;
      --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      --font-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
      --max-width: 960px;
      --radius: 6px;
    }

    *, *::before, *::after {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      font-family: var(--font-sans);
      font-size: 16px;
      line-height: 1.6;
      color: var(--color-text);
      background: var(--color-bg);
    }

    a {
      color: var(--color-primary);
      text-decoration: none;
    }

    a:hover {
      text-decoration: underline;
    }

    /* Header */
    .site-header {
      background: var(--color-text);
      color: #fff;
      padding: 0;
      position: sticky;
      top: 0;
      z-index: 100;
      box-shadow: 0 1px 3px rgba(0,0,0,0.12);
    }

    .header-inner {
      max-width: var(--max-width);
      margin: 0 auto;
      padding: 16px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .header-title {
      font-size: 20px;
      font-weight: 600;
      color: #fff;
    }

    .header-links a {
      color: rgba(255,255,255,0.8);
      margin-left: 20px;
      font-size: 14px;
    }

    .header-links a:hover {
      color: #fff;
      text-decoration: none;
    }

    /* Layout: sidebar + main */
    .site-body {
      display: flex;
      max-width: 1200px;
      margin: 0 auto;
      min-height: calc(100vh - 130px);
    }

    /* Side Navigation */
    .site-nav {
      width: 220px;
      min-width: 220px;
      background: var(--color-bg-alt);
      border-right: 1px solid var(--color-border);
      padding: 20px 0;
      position: sticky;
      top: 57px;
      height: calc(100vh - 57px);
      overflow-y: auto;
    }

    .nav-section-heading {
      padding: 16px 20px 6px;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--color-text-muted);
    }

    .nav-link {
      display: block;
      padding: 7px 20px;
      font-size: 14px;
      font-weight: 500;
      color: var(--color-text-muted);
      border-left: 3px solid transparent;
      transition: color 0.15s, border-color 0.15s, background 0.15s;
      cursor: pointer;
    }

    .nav-link:hover {
      color: var(--color-text);
      background: rgba(0,0,0,0.03);
      text-decoration: none;
    }

    .nav-link.active {
      color: var(--color-primary);
      border-left-color: var(--color-primary);
      background: rgba(9,105,218,0.04);
    }

    /* Main Content */
    .site-main {
      flex: 1;
      max-width: 960px;
      padding: 32px 40px;
      min-width: 0;
    }

    /* Section */
    .section {
      margin-bottom: 48px;
    }

    .section:last-child {
      margin-bottom: 0;
    }

    .section-title {
      font-size: 28px;
      font-weight: 600;
      margin-bottom: 8px;
      padding-bottom: 8px;
      border-bottom: 1px solid var(--color-border);
    }

    .section-desc {
      font-size: 16px;
      color: var(--color-text-muted);
      margin-bottom: 24px;
    }

    /* Action Card */
    .action-card {
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      margin-bottom: 24px;
      overflow: hidden;
    }

    .action-card-header {
      background: var(--color-bg-alt);
      padding: 16px 20px;
      border-bottom: 1px solid var(--color-border-light);
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .action-badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 500;
      color: #fff;
    }

    .badge-green { background: var(--color-success); }
    .badge-orange { background: #d97706; }
    .badge-blue { background: var(--color-primary); }

    .action-card-body {
      padding: 20px;
    }

    /* Tables */
    .param-table {
      width: 100%;
      border-collapse: collapse;
      margin: 16px 0;
      font-size: 14px;
    }

    .param-table th {
      text-align: left;
      padding: 8px 12px;
      background: var(--color-bg-alt);
      border: 1px solid var(--color-border);
      font-weight: 600;
      font-size: 13px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--color-text-muted);
    }

    .param-table td {
      padding: 8px 12px;
      border: 1px solid var(--color-border-light);
      vertical-align: top;
    }

    .param-table tr:hover td {
      background: var(--color-bg-alt);
    }

    .param-name {
      font-family: var(--font-mono);
      font-size: 13px;
      color: var(--color-primary-dark);
      font-weight: 500;
    }

    .param-required {
      color: #cf222e;
      font-size: 12px;
      font-weight: 600;
    }

    .param-default {
      font-family: var(--font-mono);
      font-size: 12px;
      color: var(--color-text-muted);
      background: var(--color-bg-code);
      padding: 1px 6px;
      border-radius: 3px;
    }

    /* Code Blocks */
    .code-block {
      background: var(--color-bg-code);
      border: 1px solid var(--color-border-light);
      border-radius: var(--radius);
      padding: 16px;
      overflow-x: auto;
      margin: 16px 0;
    }

    .code-block pre {
      margin: 0;
      font-family: var(--font-mono);
      font-size: 13px;
      line-height: 1.5;
      white-space: pre;
      color: var(--color-text);
    }

    .code-label {
      font-size: 12px;
      font-weight: 600;
      color: var(--color-text-muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
    }

    /* Sub headings */
    h3 {
      font-size: 18px;
      font-weight: 600;
      margin: 24px 0 12px;
    }

    h4 {
      font-size: 15px;
      font-weight: 600;
      margin: 16px 0 8px;
    }

    p {
      margin-bottom: 12px;
    }

    /* Security section */
    .security-note {
      background: #fff8c5;
      border: 1px solid #d4a72c;
      border-radius: var(--radius);
      padding: 16px 20px;
      margin: 16px 0;
    }

    .security-note-title {
      font-weight: 600;
      margin-bottom: 8px;
    }

    .security-note ul {
      margin-left: 20px;
    }

    .security-note li {
      margin-bottom: 4px;
    }

    /* Footer */
    .site-footer {
      background: var(--color-bg-alt);
      border-top: 1px solid var(--color-border);
      padding: 24px;
      text-align: center;
      font-size: 14px;
      color: var(--color-text-muted);
    }

    .footer-inner {
      max-width: var(--max-width);
      margin: 0 auto;
    }

    .footer-links {
      margin-bottom: 8px;
    }

    .footer-links a {
      margin: 0 12px;
      color: var(--color-text-muted);
    }

    .footer-links a:hover {
      color: var(--color-primary);
    }

    .footer-version {
      margin-top: 8px;
      font-family: var(--font-mono);
      font-size: 12px;
      color: var(--color-border);
    }

    /* Hero section */
    .hero {
      text-align: center;
      padding: 48px 0 32px;
    }

    .hero h1 {
      font-size: 36px;
      font-weight: 700;
      margin-bottom: 12px;
    }

    .hero p {
      font-size: 18px;
      color: var(--color-text-muted);
      max-width: 600px;
      margin: 0 auto 24px;
    }

    .hero-actions {
      display: flex;
      gap: 12px;
      justify-content: center;
      flex-wrap: wrap;
    }

    .hero-btn {
      display: inline-block;
      padding: 10px 20px;
      border-radius: var(--radius);
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      transition: background 0.15s;
    }

    .hero-btn-primary {
      background: var(--color-primary);
      color: #fff;
    }

    .hero-btn-primary:hover {
      background: var(--color-primary-dark);
      text-decoration: none;
    }

    .hero-btn-secondary {
      background: var(--color-bg);
      color: var(--color-text);
      border: 1px solid var(--color-border);
    }

    .hero-btn-secondary:hover {
      background: var(--color-bg-alt);
      text-decoration: none;
    }

    /* Card links */
    .action-card-link {
      display: block;
      text-decoration: none;
      color: inherit;
      transition: box-shadow 0.15s;
    }

    .action-card-link:hover {
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      text-decoration: none;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .site-body {
        flex-direction: column;
      }

      .site-nav {
        width: 100%;
        min-width: 100%;
        height: auto;
        position: static;
        border-right: none;
        border-bottom: 1px solid var(--color-border);
        padding: 12px 0;
        display: flex;
        flex-wrap: wrap;
        gap: 0;
      }

      .nav-section-heading {
        width: 100%;
        padding: 8px 16px 4px;
      }

      .nav-link {
        border-left: none;
        border-bottom: 2px solid transparent;
        padding: 8px 12px;
      }

      .nav-link.active {
        border-left-color: transparent;
        border-bottom-color: var(--color-primary);
      }

      .site-main {
        padding: 24px 16px;
      }

      .header-inner {
        flex-direction: column;
        gap: 8px;
      }

      .hero h1 {
        font-size: 28px;
      }

      .param-table {
        font-size: 13px;
      }

      .param-table th,
      .param-table td {
        padding: 6px 8px;
      }
    }
  `;
  document.head.appendChild(style);
}
