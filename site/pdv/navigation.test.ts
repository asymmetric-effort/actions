import { test, expect } from '@playwright/test';

test.describe('Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('.site-nav');
  });

  test('renders all navigation links', async ({ page }) => {
    const navLinks = page.locator('.nav-link');
    const count = await navLinks.count();
    expect(count).toBeGreaterThanOrEqual(18);

    const labels = await navLinks.allTextContents();
    expect(labels).toContain('Home');
    expect(labels).toContain('checkout');
    expect(labels).toContain('setup-bun');
    expect(labels).toContain('setup-go');
    expect(labels).toContain('setup-node');
    expect(labels).toContain('setup-python');
    expect(labels).toContain('fossa-scan');
    expect(labels).toContain('gh-release');
    expect(labels).toContain('go-tooling');
    expect(labels).toContain('build-pkg-rpm');
    expect(labels).toContain('build-pkg-deb');
    expect(labels).toContain('npm-publish');
    expect(labels).toContain('deploy-pages');
    expect(labels).toContain('deploy-pages-api');
    expect(labels).toContain('upload-pages-artifact');
    expect(labels).toContain('codeql-init');
    expect(labels).toContain('codeql-autobuild');
    expect(labels).toContain('codeql-analyze');
    expect(labels).toContain('Security');
  });

  test('Home link is active by default', async ({ page }) => {
    const homeLink = page.locator('.nav-link.active');
    await expect(homeLink).toContainText('Home');
  });

  test('clicking setup-bun navigates and updates active state', async ({ page }) => {
    await page.locator('.nav-link', { hasText: 'setup-bun' }).click();
    await page.waitForSelector('.action-card-body');

    expect(page.url()).toContain('#setup-bun');
    const active = page.locator('.nav-link.active');
    await expect(active).toContainText('setup-bun');
  });

  test('clicking fossa-scan navigates and updates active state', async ({ page }) => {
    await page.locator('.nav-link', { hasText: 'fossa-scan' }).click();
    await page.waitForSelector('.action-card-body');

    expect(page.url()).toContain('#fossa-scan');
    const active = page.locator('.nav-link.active');
    await expect(active).toContainText('fossa-scan');
  });

  test('clicking gh-release navigates and updates active state', async ({ page }) => {
    await page.locator('.nav-link', { hasText: 'gh-release' }).click();
    await page.waitForSelector('.action-card-body');

    expect(page.url()).toContain('#gh-release');
    const active = page.locator('.nav-link.active');
    await expect(active).toContainText('gh-release');
  });

  test('clicking Security navigates and updates active state', async ({ page }) => {
    await page.locator('.nav-link', { hasText: 'Security' }).click();
    await page.waitForSelector('.section-title');

    expect(page.url()).toContain('#security');
    const active = page.locator('.nav-link.active');
    await expect(active).toContainText('Security');
  });

  test('browser back navigates to previous route', async ({ page }) => {
    await page.locator('.nav-link', { hasText: 'setup-bun' }).click();
    await page.waitForSelector('.action-card-body');

    await page.locator('.nav-link', { hasText: 'Security' }).click();
    await page.waitForSelector('.section-title');

    await page.goBack();
    await page.waitForSelector('.action-card-body');
    expect(page.url()).toContain('#setup-bun');
  });
});
