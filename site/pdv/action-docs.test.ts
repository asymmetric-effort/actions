import { test, expect } from '@playwright/test';

const actionSlugs = ['checkout', 'setup-bun', 'setup-go', 'setup-node', 'setup-python', 'fossa-scan', 'gh-release', 'deploy-pages-api', 'upload-pages-artifact', 'codeql-init', 'codeql-autobuild', 'codeql-analyze'] as const;

for (const slug of actionSlugs) {
  test.describe(`${slug} documentation page`, () => {
    test.beforeEach(async ({ page }) => {
      await page.goto(`/#${slug}`);
      await page.waitForSelector('.action-card-body');
    });

    test('renders action card with header', async ({ page }) => {
      const header = page.locator('.action-card-header');
      await expect(header).toBeVisible();
    });

    test('renders action badge', async ({ page }) => {
      const badge = page.locator('.action-badge');
      await expect(badge).toBeVisible();
      const text = await badge.textContent();
      expect(['Core', 'Runtime', 'Security', 'Release', 'Deployment', 'Toolchain', 'Packaging', 'Publishing']).toContain(text);
    });

    test('renders action name in h2', async ({ page }) => {
      const heading = page.locator('.action-card-header h2');
      await expect(heading).toBeVisible();
      const text = await heading.textContent();
      expect(text!.length).toBeGreaterThan(0);
    });

    test('renders description paragraph', async ({ page }) => {
      const desc = page.locator('.action-card-body > p').first();
      await expect(desc).toBeVisible();
      const text = await desc.textContent();
      expect(text!.length).toBeGreaterThan(20);
    });

    test('renders Usage section with code block', async ({ page }) => {
      const usageHeading = page.locator('h3', { hasText: 'Usage' });
      await expect(usageHeading).toBeVisible();

      const codeBlock = page.locator('.code-block pre');
      await expect(codeBlock.first()).toBeVisible();

      const code = await codeBlock.first().textContent();
      expect(code).toContain('asymmetric-effort/actions');
    });

    test('renders Inputs table with headers', async ({ page }) => {
      const inputsHeading = page.locator('h3', { hasText: 'Inputs' });
      await expect(inputsHeading).toBeVisible();

      const table = page.locator('.param-table').first();
      await expect(table).toBeVisible();

      const headers = await table.locator('th').allTextContents();
      expect(headers).toEqual(['Input', 'Description', 'Required', 'Default']);
    });

    test('inputs table has at least one row', async ({ page }) => {
      const rows = page.locator('.param-table').first().locator('tbody tr');
      const count = await rows.count();
      expect(count).toBeGreaterThanOrEqual(1);
    });

    test('renders Outputs section', async ({ page }) => {
      const outputsHeading = page.locator('h3', { hasText: 'Outputs' });
      await expect(outputsHeading).toBeVisible();

      // codeql-autobuild has no outputs, so it may not render a table
      if (slug !== 'codeql-autobuild') {
        const tables = page.locator('.param-table');
        const lastTable = tables.last();
        await expect(lastTable).toBeVisible();

        const headers = await lastTable.locator('th').allTextContents();
        expect(headers).toEqual(['Output', 'Description']);

        const rows = lastTable.locator('tbody tr');
        const count = await rows.count();
        expect(count).toBeGreaterThanOrEqual(1);
      }
    });

    test('input names use monospace styling', async ({ page }) => {
      const paramNames = page.locator('.param-name');
      const count = await paramNames.count();
      expect(count).toBeGreaterThan(0);
    });
  });
}

test.describe('setup-bun specific content', () => {
  test('shows bun-version input', async ({ page }) => {
    await page.goto('/#setup-bun');
    await page.waitForSelector('.action-card-body');

    const paramNames = await page.locator('.param-name').allTextContents();
    expect(paramNames).toContain('bun-version');
    expect(paramNames).toContain('bun-version-file');
    expect(paramNames).toContain('no-cache');
  });
});

test.describe('fossa-scan specific content', () => {
  test('shows api-key as required', async ({ page }) => {
    await page.goto('/#fossa-scan');
    await page.waitForSelector('.action-card-body');

    const requiredBadges = page.locator('.param-required');
    await expect(requiredBadges.first()).toContainText('Yes');
  });
});

test.describe('gh-release specific content', () => {
  test('shows files input', async ({ page }) => {
    await page.goto('/#gh-release');
    await page.waitForSelector('.action-card-body');

    const paramNames = await page.locator('.param-name').allTextContents();
    expect(paramNames).toContain('files');
    expect(paramNames).toContain('tag_name');
    expect(paramNames).toContain('draft');
  });

  test('shows four outputs', async ({ page }) => {
    await page.goto('/#gh-release');
    await page.waitForSelector('.action-card-body');

    const tables = page.locator('.param-table');
    const outputTable = tables.last();
    const rows = outputTable.locator('tbody tr');
    await expect(rows).toHaveCount(4);
  });
});
