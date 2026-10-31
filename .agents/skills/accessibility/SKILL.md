---
name: accessibility
description: >-
  Audit and implement WCAG 2.2 AA accessibility in React and Astro components
  following .guardrails/eslint/a11y.mjs. Use when building UI components, forms,
  navigation, dialogs, keyboard interactions, or running a11y audits.
---

# Skill: WCAG 2.2 AA Accessibility (`accessibility`)

All JSX components (including Panda CSS primitives and `@m3e/react` wrappers mapped in `.guardrails/eslint/a11y.mjs`) are checked against strict `jsx-a11y` rules and `@axe-core/playwright`.

## Mandatory WCAG 2.2 AA Requirements
1. **Perceivable**: Localized `alt` text from `src/i18n/strings.ts`, 4.5:1 text contrast, 3:1 UI contrast (via MD3 `bg` ↔ `color` token pairing).
2. **Operable**: Full keyboard navigation, `:focus-visible` indicator not obscured (`WCAG 2.4.11`), target size `>= 24x24px` (`WCAG 2.5.8`), `@media (prefers-reduced-motion: reduce)`.
3. **Understandable & Robust**: Valid `<html lang="...">`, programmatic form labels, `role="alert"` on Error Boundaries and form errors.
