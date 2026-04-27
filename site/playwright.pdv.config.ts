import { defineConfig } from '@playwright/test';

const SITE_URL = process.env.SITE_URL || 'https://actions.asymmetric-effort.com';

export default defineConfig({
  testDir: './pdv',
  testMatch: '**/*.test.ts',
  timeout: 30_000,
  retries: 2,
  fullyParallel: true,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: 'pdv-report' }],
  ],
  use: {
    baseURL: SITE_URL,
    headless: true,
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
