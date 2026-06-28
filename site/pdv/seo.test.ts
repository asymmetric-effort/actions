import { test, expect } from '@playwright/test';

const SITE_URL = process.env.SITE_URL || 'https://actions.asymmetric-effort.com';

const expectedRoutes = [
  { slug: 'home', path: '/' },
  { slug: 'checkout', path: '/#checkout' },
  { slug: 'setup-bun', path: '/#setup-bun' },
  { slug: 'setup-go', path: '/#setup-go' },
  { slug: 'setup-node', path: '/#setup-node' },
  { slug: 'setup-python', path: '/#setup-python' },
  { slug: 'fossa-scan', path: '/#fossa-scan' },
  { slug: 'gh-release', path: '/#gh-release' },
  { slug: 'go-tooling', path: '/#go-tooling' },
  { slug: 'build-pkg-rpm', path: '/#build-pkg-rpm' },
  { slug: 'build-pkg-deb', path: '/#build-pkg-deb' },
  { slug: 'npm-publish', path: '/#npm-publish' },
  { slug: 'release', path: '/#release' },
  { slug: 'deploy-pages', path: '/#deploy-pages' },
  { slug: 'deploy-pages-api', path: '/#deploy-pages-api' },
  { slug: 'upload-pages-artifact', path: '/#upload-pages-artifact' },
  { slug: 'codeql-init', path: '/#codeql-init' },
  { slug: 'codeql-autobuild', path: '/#codeql-autobuild' },
  { slug: 'codeql-analyze', path: '/#codeql-analyze' },
  { slug: 'upload-artifact', path: '/#upload-artifact' },
  { slug: 'download-artifact', path: '/#download-artifact' },
  { slug: 'configure-pages', path: '/#configure-pages' },
  { slug: 'security', path: '/#security' },
];

test.describe('robots.txt', () => {
  let body: string;

  test.beforeAll(async ({ request }) => {
    const response = await request.get(`${SITE_URL}/robots.txt`);
    expect(response.status()).toBe(200);
    body = await response.text();
  });

  test('is served with correct content type', async ({ request }) => {
    const response = await request.get(`${SITE_URL}/robots.txt`);
    const contentType = response.headers()['content-type'] || '';
    expect(contentType).toContain('text/plain');
  });

  test('allows all user agents', async () => {
    expect(body).toContain('User-agent: *');
  });

  test('allows crawling', async () => {
    expect(body).toContain('Allow: /');
  });

  test('references sitemap with correct URL', async () => {
    expect(body).toContain('Sitemap: https://actions.asymmetric-effort.com/sitemap.xml');
  });

  test('does not disallow any paths', async () => {
    expect(body).not.toContain('Disallow:');
  });
});

test.describe('sitemap.xml', () => {
  let body: string;

  test.beforeAll(async ({ request }) => {
    const response = await request.get(`${SITE_URL}/sitemap.xml`);
    expect(response.status()).toBe(200);
    body = await response.text();
  });

  test('is served with XML content type', async ({ request }) => {
    const response = await request.get(`${SITE_URL}/sitemap.xml`);
    const contentType = response.headers()['content-type'] || '';
    expect(contentType).toMatch(/xml/);
  });

  test('has valid XML declaration', async () => {
    expect(body).toMatch(/^<\?xml version="1\.0" encoding="UTF-8"\?>/);
  });

  test('has urlset with sitemap namespace', async () => {
    expect(body).toContain('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"');
  });

  test('contains a URL entry for each route', async () => {
    for (const route of expectedRoutes) {
      const expectedLoc = `https://actions.asymmetric-effort.com${route.path}`;
      expect(body).toContain(`<loc>${expectedLoc}</loc>`);
    }
  });

  test('each URL has a lastmod date', async () => {
    const lastmodCount = (body.match(/<lastmod>\d{4}-\d{2}-\d{2}<\/lastmod>/g) || []).length;
    expect(lastmodCount).toBe(expectedRoutes.length);
  });

  test('has exactly the expected number of URL entries', async () => {
    const urlCount = (body.match(/<url>/g) || []).length;
    expect(urlCount).toBe(expectedRoutes.length);
  });
});

test.describe('llms.txt', () => {
  test('is served and contains site info', async ({ request }) => {
    const response = await request.get(`${SITE_URL}/llms.txt`);
    expect(response.status()).toBe(200);
    const body = await response.text();
    expect(body).toContain('Asymmetric Effort Actions');
  });
});

test.describe('SEO meta tags', () => {
  test('page has meta description', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#root');
    const desc = await page.getAttribute('meta[name="description"]', 'content');
    expect(desc).toBeTruthy();
    expect(desc!.length).toBeGreaterThan(20);
  });

  test('page has Open Graph tags', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#root');

    const ogTitle = await page.getAttribute('meta[property="og:title"]', 'content');
    expect(ogTitle).toBeTruthy();

    const ogDesc = await page.getAttribute('meta[property="og:description"]', 'content');
    expect(ogDesc).toBeTruthy();

    const ogType = await page.getAttribute('meta[property="og:type"]', 'content');
    expect(ogType).toBe('website');

    const ogSiteName = await page.getAttribute('meta[property="og:site_name"]', 'content');
    expect(ogSiteName).toBe('Asymmetric Effort Actions');
  });

  test('page has Twitter Card tags', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#root');

    const card = await page.getAttribute('meta[name="twitter:card"]', 'content');
    expect(card).toBe('summary');

    const title = await page.getAttribute('meta[name="twitter:title"]', 'content');
    expect(title).toBeTruthy();
  });

  test('page has canonical link', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#root');

    const canonical = await page.getAttribute('link[rel="canonical"]', 'href');
    expect(canonical).toContain('actions.asymmetric-effort.com');
  });

  test('noscript block contains pre-rendered content', async ({ page }) => {
    await page.goto('/');
    const noscript = await page.locator('noscript').innerHTML();
    expect(noscript).toContain('Asymmetric Effort Actions');
    expect(noscript).toContain('checkout');
    expect(noscript).toContain('setup-bun');
    expect(noscript).toContain('setup-go');
    expect(noscript).toContain('setup-node');
    expect(noscript).toContain('setup-python');
    expect(noscript).toContain('fossa-scan');
    expect(noscript).toContain('gh-release');
    expect(noscript).toContain('go-tooling');
    expect(noscript).toContain('npm-publish');
    expect(noscript).toContain('deploy-pages-api');
    expect(noscript).toContain('upload-pages-artifact');
    expect(noscript).toContain('codeql-init');
    expect(noscript).toContain('codeql-autobuild');
    expect(noscript).toContain('codeql-analyze');
    expect(noscript).toContain('upload-artifact');
    expect(noscript).toContain('download-artifact');
    expect(noscript).toContain('configure-pages');
    expect(noscript).toContain('security');
  });
});
