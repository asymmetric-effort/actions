import { test, expect } from '@playwright/test';

test.describe('Deep linking', () => {
  test('direct navigation to #setup-bun renders docs', async ({ page }) => {
    await page.goto('/#setup-bun');
    await page.waitForSelector('.action-card-body');

    const heading = page.locator('.action-card-header h2');
    await expect(heading).toContainText('Setup Bun');
  });

  test('direct navigation to #fossa-scan renders docs', async ({ page }) => {
    await page.goto('/#fossa-scan');
    await page.waitForSelector('.action-card-body');

    const heading = page.locator('.action-card-header h2');
    await expect(heading).toContainText('FOSSA Scan');
  });

  test('direct navigation to #gh-release renders docs', async ({ page }) => {
    await page.goto('/#gh-release');
    await page.waitForSelector('.action-card-body');

    const heading = page.locator('.action-card-header h2');
    await expect(heading).toContainText('GitHub Release');
  });

  test('direct navigation to #security renders security page', async ({ page }) => {
    await page.goto('/#security');
    await page.waitForSelector('.section-title');

    const title = page.locator('.section-title');
    await expect(title).toContainText('Security');
  });

  test('direct navigation to #home renders home page', async ({ page }) => {
    await page.goto('/#home');
    await page.waitForSelector('.hero');

    const title = page.locator('.hero h1');
    await expect(title).toContainText('Asymmetric Effort Actions');
  });

  test('unknown hash falls back to home page', async ({ page }) => {
    await page.goto('/#nonexistent-route');
    await page.waitForSelector('.hero');

    const title = page.locator('.hero h1');
    await expect(title).toBeVisible();
  });

  test('no hash defaults to home page', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('.hero');

    const title = page.locator('.hero h1');
    await expect(title).toBeVisible();
  });
});
