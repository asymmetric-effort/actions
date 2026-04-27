import { createElement } from '@asymmetric-effort/specifyjs';

export function SecurityPage(): ReturnType<typeof createElement> {
  return createElement('div', { className: 'section' },
    createElement('h2', { className: 'section-title' }, 'Security'),
    createElement('p', { className: 'section-desc' }, 'Best practices and security considerations when using these actions.'),

    createElement('div', { className: 'security-note' },
      createElement('div', { className: 'security-note-title' }, 'Important: Handling Secrets'),
      createElement('ul', null,
        createElement('li', null, 'Never hardcode API keys or tokens in your workflow files.'),
        createElement('li', null, 'Always use ', createElement('span', { className: 'param-default' }, '${{ secrets.YOUR_SECRET }}'), ' to reference sensitive values.'),
        createElement('li', null, 'Rotate secrets regularly and use the minimum required permissions.'),
      ),
    ),

    createElement('h3', null, 'Token Permissions'),
    createElement('p', null, 'All actions that accept a ', createElement('span', { className: 'param-default' }, 'token'), ' input default to ', createElement('span', { className: 'param-default' }, '${{ github.token }}'), ', which is automatically provisioned by GitHub with the permissions defined in your workflow\'s ', createElement('span', { className: 'param-default' }, 'permissions'), ' block.'),
    createElement('div', { className: 'code-block' },
      createElement('pre', null, `permissions:
  contents: write    # Required for gh-release
  actions: read      # Required for setup-bun caching`),
    ),

    createElement('h3', null, 'FOSSA API Key'),
    createElement('p', null, 'The ', createElement('span', { className: 'param-default' }, 'fossa-scan'), ' action requires a FOSSA API key. Store this as a GitHub Actions secret:'),
    createElement('div', { className: 'code-block' },
      createElement('pre', null, `- uses: asymmetric-effort/actions/actions/fossa-scan@v1
  with:
    api-key: \${{ secrets.FOSSA_API_KEY }}`),
    ),

    createElement('h3', null, 'Pinning Action Versions'),
    createElement('p', null, 'For production workflows, pin actions to a specific commit SHA to prevent supply-chain attacks:'),
    createElement('div', { className: 'code-block' },
      createElement('pre', null, `# Preferred: pin to a specific SHA
- uses: asymmetric-effort/actions/actions/gh-release@abc1234

# Acceptable: pin to a release tag
- uses: asymmetric-effort/actions/actions/gh-release@v1.0.0

# Less secure: track a branch
- uses: asymmetric-effort/actions/actions/gh-release@main`),
    ),

    createElement('h3', null, 'Reporting Vulnerabilities'),
    createElement('p', null,
      'If you discover a security vulnerability, please report it responsibly by emailing ',
      createElement('a', { href: 'mailto:security@asymmetric-effort.com' }, 'security@asymmetric-effort.com'),
      ' or by opening a private security advisory on the ',
      createElement('a', { href: 'https://github.com/asymmetric-effort/actions/security/advisories', target: '_blank', rel: 'noopener' }, 'GitHub repository'),
      '.',
    ),
  );
}
