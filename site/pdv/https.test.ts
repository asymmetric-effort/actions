import { test, expect } from '@playwright/test';

test.describe('HTTPS enforcement', () => {
  test('site is served over HTTPS', async ({ page }) => {
    const response = await page.goto('/');
    expect(response).not.toBeNull();
    expect(page.url()).toMatch(/^https:\/\//);
  });

  test('HTTP redirects to HTTPS', async ({ page }) => {
    // Attempt HTTP — should end up on HTTPS after redirect
    const response = await page.goto('http://actions.asymmetric-effort.com/', {
      waitUntil: 'domcontentloaded',
    });
    expect(response).not.toBeNull();
    expect(page.url()).toMatch(/^https:\/\/actions\.asymmetric-effort\.com/);
  });

  test('custom domain resolves correctly', async ({ page }) => {
    await page.goto('/');
    expect(page.url()).toContain('actions.asymmetric-effort.com');
  });
});
