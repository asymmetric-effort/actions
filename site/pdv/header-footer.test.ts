import { test, expect } from '@playwright/test';

test.describe('Header', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('.site-header');
  });

  test('renders header with title', async ({ page }) => {
    const title = page.locator('.header-title');
    await expect(title).toBeVisible();
    await expect(title).toContainText('Asymmetric Effort Actions');
  });

  test('renders GitHub link', async ({ page }) => {
    const link = page.locator('.header-links a', { hasText: 'GitHub' });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute('href', /github\.com\/asymmetric-effort\/actions/);
    await expect(link).toHaveAttribute('target', '_blank');
  });

  test('renders Asymmetric Effort link', async ({ page }) => {
    const link = page.locator('.header-links a', { hasText: 'Asymmetric Effort' });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute('href', /asymmetric-effort\.com/);
    await expect(link).toHaveAttribute('target', '_blank');
  });

  test('header is sticky at top', async ({ page }) => {
    const header = page.locator('.site-header');
    const position = await header.evaluate(el => getComputedStyle(el).position);
    expect(position).toBe('sticky');
  });
});

test.describe('Footer', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('footer');
  });

  test('renders footer with copyright', async ({ page }) => {
    const footer = page.locator('footer');
    await expect(footer).toBeVisible();
    await expect(footer).toContainText('Asymmetric Effort, LLC');
    await expect(footer).toContainText(new Date().getFullYear().toString());
  });

  test('renders GitHub Repository link', async ({ page }) => {
    const link = page.locator('.footer-links a', { hasText: 'GitHub Repository' });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute('href', /github\.com\/asymmetric-effort\/actions$/);
  });

  test('renders Report an Issue link', async ({ page }) => {
    const link = page.locator('.footer-links a', { hasText: 'Report an Issue' });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute('href', /\/issues$/);
  });

  test('renders License link', async ({ page }) => {
    const link = page.locator('.footer-links a', { hasText: 'License' });
    await expect(link).toBeVisible();
  });

  test('has at least 4 footer links', async ({ page }) => {
    const links = page.locator('.footer-links a');
    const count = await links.count();
    expect(count).toBeGreaterThanOrEqual(4);
  });

  test('renders project version', async ({ page }) => {
    const version = page.locator('.footer-version');
    await expect(version).toBeVisible();
    const text = await version.textContent();
    expect(text).toMatch(/^v\d+\.\d+\.\d+$/);
  });
});
