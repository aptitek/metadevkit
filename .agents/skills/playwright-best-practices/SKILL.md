---
name: playwright-best-practices
description: >-
  Write resilient Playwright E2E and @axe-core/playwright WCAG 2.2 AA
  accessibility tests (playwright.config.ts). Use when creating, debugging, or
  running E2E and browser accessibility tests.
---

# Skill: Playwright E2E & Axe WCAG 2.2 AA (`playwright-best-practices`)

## Core Rules
- Use role-first locators (`page.getByRole()`, `page.getByLabel()`) and web-first auto-retrying assertions (`await expect(locator).toBeVisible()`).
- Verify zero WCAG 2.2 AA violations on every route using `@axe-core/playwright` (`AxeBuilder`).
- Run `task testing-fortress:e2e`.
