// =============================================================================
// playwright.config.ts — Playwright E2E + Axe WCAG 2.2 AA Verification Config
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
export default {
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "list",
  use: {
    baseURL: "http://localhost:4173",
    trace: "on-first-retry",
  },
};
