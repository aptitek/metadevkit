---
name: react-i18next
description: >-
  Implement Lock 2 Strict Internationalization (i18n) in React applications using
  src/i18n/strings.ts, react-i18next, and A11Y_STRINGS locale parity. Use whenever
  adding or modifying user-facing text, labels, or translations.
---

# Skill: Lock 2 Strict Internationalization (`react-i18next`)

`.guardrails/eslint/react.mjs` enforces **Lock 2 (`strict-i18n-strings`)**: hardcoded user-facing strings in JSX text, JSX attributes (`aria-label`, `title`, `placeholder`, `alt`), and functions inside `.tsx` files are strictly forbidden.

## Architecture of `src/i18n/strings.ts`
- All UI and accessibility strings must be registered in `src/i18n/strings.ts` with 100% key parity across all supported locales (e.g. `en`, `fr`).
- Resolve translations in organisms/templates/pages via `useTranslation()` or `resolveA11yString(locale, key)` and pass resolved strings as props to stateless atoms.
