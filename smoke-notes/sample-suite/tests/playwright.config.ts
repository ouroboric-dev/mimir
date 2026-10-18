import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  testMatch: '*.spec.ts',
  workers: Number(process.env.WORKERS ?? 2),
  timeout: 20_000,
  retries: 0,
  use: { baseURL: 'http://localhost:3000' },
});
