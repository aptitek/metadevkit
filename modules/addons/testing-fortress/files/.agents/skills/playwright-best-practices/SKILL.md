---
name: playwright-best-practices
description: >-
  Write resilient Playwright E2E and @axe-core/playwright WCAG 2.2 AA
  accessibility tests (playwright.config.ts). Use when creating, debugging, or
  running E2E and browser accessibility tests.
---

# Skill: Playwright E2E & Axe WCAG 2.2 AA (`playwright-best-practices`)

Governed by `playwright.config.ts` and `.guardrails/taskfiles/Taskfile.testing-fortress.yml`.

## 1. Core Playwright Rules
1. **Role-First Locators**: Prefer user-visible semantic locators (`page.getByRole()`, `page.getByLabel()`, `page.getByText()`) over brittle CSS/XPath selectors.
2. **Web-First Auto-Retrying Assertions**: Always use `await expect(locator).toBeVisible()`, `await expect(locator).toHaveAttribute(...)`. Never use `page.waitForTimeout()`.
3. **Automated WCAG 2.2 AA Audits (`@axe-core/playwright`)**:
   - Every E2E route test should verify zero WCAG 2.2 AA violations using `AxeBuilder`:
   ```typescript
   import AxeBuilder from "@axe-core/playwright";
   import { expect, test } from "@playwright/test";

   test("renders home page with zero WCAG 2.2 AA violations", async ({ page }) => {
     await page.goto("/");
     const results = await new AxeBuilder({ page })
       .withTags(["wcag2a", "wcag2aa", "wcag22aa"])
       .analyze();
     expect(results.violations).toEqual([]);
   });
   ```
4. **Execution**: Run `task testing-fortress:e2e` (or `task verify`).
