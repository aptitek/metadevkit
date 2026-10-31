---
name: accessibility
description: >-
  Audit and implement WCAG 2.2 AA accessibility in React and Astro components
  following .guardrails/eslint/a11y.mjs. Use when building UI components, forms,
  navigation, dialogs, keyboard interactions, or running a11y audits.
---

# Skill: WCAG 2.2 AA Accessibility (`accessibility`)

All JSX components (including Panda CSS primitives and `@m3e/react` wrappers mapped in `.guardrails/eslint/a11y.mjs`) are checked against strict `jsx-a11y` rules and `@axe-core/playwright`.

## 1. Mandatory WCAG 2.2 AA Requirements
1. **Perceivable**:
   - Every image/graphic requires localized `alt` text from `src/i18n/strings.ts` (or `alt="" role="presentation"` if purely decorative).
   - Color contrast must meet **4.5:1** for normal text and **3:1** for large text and UI boundaries (guaranteed when using valid MD3 `bg` ↔ `color` token pairs).
2. **Operable**:
   - Full keyboard navigation (`Tab`, `Shift+Tab`, `Enter`, `Space`, `Escape`). Never use `tabIndex > 0`.
   - Visible focus indicator (`:focus-visible` with `>= 3:1` contrast) that is never obscured by sticky headers (`WCAG 2.4.11`).
   - Touch/pointer target size must be at least **24 × 24 CSS pixels** (`WCAG 2.5.8`; 44 × 44dp recommended in MD3).
   - Respect `@media (prefers-reduced-motion: reduce)`.
3. **Understandable & Robust**:
   - Every `<html lang="...">` must declare a valid BCP-47 locale.
   - Every form control must have a programmatic label (`aria-label`, `aria-labelledby`, or associated `<label>`) with `control-has-associated-label`.
   - Announce dynamic errors via `role="alert"` or `aria-live="polite"`.
   - Every icon-only button (`<M3eIconButton>`, `<md-icon-button>`) must have a localized `aria-label`.
