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

  test('renders action cards for all actions', async ({ page }) => {
    const cards = page.locator('.action-card');
    const count = await cards.count();
    expect(count).toBeGreaterThanOrEqual(7);
  });

  test('action cards have correct names', async ({ page }) => {
    const cardTexts = await page.locator('.action-card strong').allTextContents();
    expect(cardTexts).toContain('Setup Bun');
    expect(cardTexts).toContain('FOSSA Scan');
    expect(cardTexts).toContain('GitHub Release');
    expect(cardTexts).toContain('Go Tooling');
    expect(cardTexts).toContain('Build RPM Package');
    expect(cardTexts).toContain('Build DEB Package');
    expect(cardTexts).toContain('NPM Publish');
  });

  test('action cards have category badges', async ({ page }) => {
    const badges = await page.locator('.action-badge').allTextContents();
    expect(badges).toContain('Runtime');
    expect(badges).toContain('Security');
    expect(badges).toContain('Release');
    expect(badges).toContain('Toolchain');
    expect(badges).toContain('Packaging');
    expect(badges).toContain('Publishing');
  });

  test('clicking an action card navigates to its docs', async ({ page }) => {
    await page.locator('.action-card').first().click();
    await page.waitForSelector('.action-card-body');
    expect(page.url()).toContain('#setup-bun');
  });
});
