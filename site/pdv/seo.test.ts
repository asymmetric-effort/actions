import { test, expect } from '@playwright/test';

const SITE_URL = process.env.SITE_URL || 'https://actions.asymmetric-effort.com';

const expectedRoutes = [
  { slug: 'home', path: '/', priority: '1.0' },
  { slug: 'setup-bun', path: '/#setup-bun', priority: '0.8' },
  { slug: 'fossa-scan', path: '/#fossa-scan', priority: '0.8' },
  { slug: 'gh-release', path: '/#gh-release', priority: '0.8' },
  { slug: 'go-tooling', path: '/#go-tooling', priority: '0.8' },
  { slug: 'build-pkg-rpm', path: '/#build-pkg-rpm', priority: '0.8' },
  { slug: 'build-pkg-deb', path: '/#build-pkg-deb', priority: '0.8' },
  { slug: 'npm-publish', path: '/#npm-publish', priority: '0.8' },
  { slug: 'security', path: '/#security', priority: '0.6' },
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

  test('each URL has a changefreq of weekly', async () => {
    const freqCount = (body.match(/<changefreq>weekly<\/changefreq>/g) || []).length;
    expect(freqCount).toBe(expectedRoutes.length);
  });

  test('home page has priority 1.0', async () => {
    // Extract the <url> block containing the home page loc
    const homeBlock = body.match(/<url>[\s\S]*?<loc>https:\/\/actions\.asymmetric-effort\.com\/<\/loc>[\s\S]*?<\/url>/);
    expect(homeBlock).not.toBeNull();
    expect(homeBlock![0]).toContain('<priority>1.0</priority>');
  });

  test('action pages have priority 0.8', async () => {
    for (const route of expectedRoutes.filter(r => r.priority === '0.8')) {
      const escapedPath = route.path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(`<url>[\\s\\S]*?<loc>https://actions\\.asymmetric-effort\\.com${escapedPath}</loc>[\\s\\S]*?</url>`);
      const block = body.match(regex);
      expect(block).not.toBeNull();
      expect(block![0]).toContain('<priority>0.8</priority>');
    }
  });

  test('security page has priority 0.6', async () => {
    const secBlock = body.match(/<url>[\s\S]*?<loc>https:\/\/actions\.asymmetric-effort\.com\/#security<\/loc>[\s\S]*?<\/url>/);
    expect(secBlock).not.toBeNull();
    expect(secBlock![0]).toContain('<priority>0.6</priority>');
  });

  test('has exactly the expected number of URL entries', async () => {
    const urlCount = (body.match(/<url>/g) || []).length;
    expect(urlCount).toBe(expectedRoutes.length);
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

  test('page has JSON-LD structured data', async ({ page }) => {
    await page.goto('/');
    const jsonLd = await page.locator('script[type="application/ld+json"]').textContent();
    expect(jsonLd).toBeTruthy();

    const data = JSON.parse(jsonLd!);
    expect(data['@context']).toBe('https://schema.org');
    expect(data['@type']).toBe('WebSite');
    expect(data.name).toBe('Asymmetric Effort Actions');
    expect(data.url).toBe('https://actions.asymmetric-effort.com');
    expect(data.publisher.name).toBe('Asymmetric Effort, LLC');
  });

  test('page has sitemap link in head', async ({ page }) => {
    await page.goto('/');
    const href = await page.getAttribute('link[rel="sitemap"]', 'href');
    expect(href).toBe('/sitemap.xml');
  });

  test('noscript block contains pre-rendered content', async ({ page }) => {
    await page.goto('/');
    const noscript = await page.locator('noscript').innerHTML();
    expect(noscript).toContain('Asymmetric Effort Actions');
    expect(noscript).toContain('setup-bun');
    expect(noscript).toContain('fossa-scan');
    expect(noscript).toContain('gh-release');
    expect(noscript).toContain('go-tooling');
    expect(noscript).toContain('npm-publish');
    expect(noscript).toContain('security');
  });
});
