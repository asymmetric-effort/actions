import { test, expect } from '@playwright/test';

test.describe('Security page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/#security');
    await page.waitForSelector('.section-title');
  });

  test('renders Security heading', async ({ page }) => {
    const title = page.locator('.section-title');
    await expect(title).toContainText('Security');
  });

  test('renders description', async ({ page }) => {
    const desc = page.locator('.section-desc');
    await expect(desc).toBeVisible();
    await expect(desc).toContainText('Best practices');
  });

  test('renders secrets warning note', async ({ page }) => {
    const note = page.locator('.security-note');
    await expect(note).toBeVisible();
    await expect(note).toContainText('Handling Secrets');
  });

  test('secrets note has list items', async ({ page }) => {
    const items = page.locator('.security-note li');
    const count = await items.count();
    expect(count).toBeGreaterThanOrEqual(3);
  });

  test('renders Token Permissions section with code block', async ({ page }) => {
    const heading = page.locator('h3', { hasText: 'Token Permissions' });
    await expect(heading).toBeVisible();

    const codeBlock = page.locator('.code-block pre').first();
    await expect(codeBlock).toBeVisible();
    await expect(codeBlock).toContainText('permissions');
  });

  test('renders FOSSA API Key section', async ({ page }) => {
    const heading = page.locator('h3', { hasText: 'FOSSA API Key' });
    await expect(heading).toBeVisible();
  });

  test('renders Pinning Action Versions section', async ({ page }) => {
    const heading = page.locator('h3', { hasText: 'Pinning Action Versions' });
    await expect(heading).toBeVisible();

    const codeBlocks = page.locator('.code-block pre');
    const allCode = await codeBlocks.allTextContents();
    const pinningCode = allCode.find(c => c.includes('@abc1234'));
    expect(pinningCode).toBeDefined();
  });

  test('renders Reporting Vulnerabilities section', async ({ page }) => {
    const heading = page.locator('h3', { hasText: 'Reporting Vulnerabilities' });
    await expect(heading).toBeVisible();
  });

  test('has email link for vulnerability reporting', async ({ page }) => {
    const emailLink = page.locator('a[href="mailto:security@asymmetric-effort.com"]');
    await expect(emailLink).toBeVisible();
  });

  test('has link to GitHub security advisories', async ({ page }) => {
    const link = page.locator('a[href*="security/advisories"]');
    await expect(link).toBeVisible();
  });
});
