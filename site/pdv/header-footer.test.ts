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

  test('has aria-label for accessibility', async ({ page }) => {
    const footer = page.locator('footer');
    await expect(footer).toHaveAttribute('aria-label', 'Site footer');
  });

  test('left section shows project name and version', async ({ page }) => {
    const footer = page.locator('footer');
    const text = await footer.innerText();
    expect(text).toMatch(/Actions v\d+\.\d+\.\d+/);
  });

  test('center section shows copyright with Asymmetric Effort link', async ({ page }) => {
    const footer = page.locator('footer');
    await expect(footer).toContainText('Asymmetric Effort, LLC');
    await expect(footer).toContainText('MIT License');

    const orgLink = page.locator('footer a', { hasText: 'Asymmetric Effort, LLC' });
    await expect(orgLink).toBeVisible();
    await expect(orgLink).toHaveAttribute('href', /asymmetric-effort\.com/);
  });

  test('right section shows GitHub Repository link', async ({ page }) => {
    const link = page.locator('footer a', { hasText: 'GitHub Repository' });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute('href', /github\.com\/asymmetric-effort\/actions$/);
  });

  test('footer has exactly 2 links', async ({ page }) => {
    const links = page.locator('footer a');
    await expect(links).toHaveCount(2);
  });
});
