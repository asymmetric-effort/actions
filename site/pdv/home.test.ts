import { test, expect } from '@playwright/test';

test.describe('Home page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/#home');
    await page.waitForSelector('.hero');
  });

  test('renders hero section with title', async ({ page }) => {
    const title = page.locator('.hero h1');
    await expect(title).toBeVisible();
    await expect(title).toContainText('Asymmetric Effort Actions');
  });

  test('renders hero description', async ({ page }) => {
    const desc = page.locator('.hero p');
    await expect(desc).toBeVisible();
    await expect(desc).toContainText('GitHub Actions');
  });

  test('renders Get Started button linking to setup-bun', async ({ page }) => {
    const btn = page.locator('.hero-btn-primary');
    await expect(btn).toBeVisible();
    await expect(btn).toHaveAttribute('href', '#setup-bun');
  });

  test('renders View on GitHub button', async ({ page }) => {
    const btn = page.locator('.hero-btn-secondary');
    await expect(btn).toBeVisible();
    await expect(btn).toHaveAttribute('href', /github\.com\/asymmetric-effort\/actions/);
  });

  test('renders three action cards', async ({ page }) => {
    const cards = page.locator('.action-card');
    await expect(cards).toHaveCount(3);
  });

  test('action cards have correct names', async ({ page }) => {
    const cardTexts = await page.locator('.action-card strong').allTextContents();
    expect(cardTexts).toContain('Setup Bun');
    expect(cardTexts).toContain('FOSSA Scan');
    expect(cardTexts).toContain('GitHub Release');
  });

  test('action cards have category badges', async ({ page }) => {
    const badges = await page.locator('.action-badge').allTextContents();
    expect(badges).toContain('Runtime');
    expect(badges).toContain('Security');
    expect(badges).toContain('Release');
  });

  test('clicking an action card navigates to its docs', async ({ page }) => {
    await page.locator('.action-card').first().click();
    await page.waitForSelector('.action-card-body');
    expect(page.url()).toContain('#setup-bun');
  });
});
