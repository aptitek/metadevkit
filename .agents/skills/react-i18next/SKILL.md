---
name: react-i18next
description: >-
  Implement Lock 2 Strict Internationalization (i18n) in React applications using
  src/i18n/strings.ts, react-i18next, and A11Y_STRINGS locale parity. Use whenever
  adding or modifying user-facing text, labels, or translations.
---

# Skill: Lock 2 Strict Internationalization (`react-i18next`)

`.guardrails/eslint/react.mjs` enforces **Lock 2 (`strict-i18n-strings`)**: hardcoded user-facing strings in JSX text, JSX attributes (`aria-label`, `title`, `placeholder`, `alt`), and functions inside `.tsx` files are strictly forbidden.

## 1. Architecture of `src/i18n/strings.ts`
- All UI and accessibility strings must be registered in `src/i18n/strings.ts` with 100% key parity across all supported locales (e.g. `en`, `fr`).
- `src/i18n/` is a pure leaf module (`.dependency-cruiser.cjs` forbids `src/i18n/` from importing components, routes, or tokens).

## 2. Consuming Translations by Atomic Layer
1. **In Organisms, Templates, and Pages**:
   - Resolve translations via `const { t } = useTranslation()` or `resolveA11yString(locale, key)` and pass the resolved string down to stateless atoms/molecules as typed props.
2. **In Stateless Atoms (`src/components/atoms/`)**:
   - Remember Lock 4: atoms cannot call `useTranslation()` (all `use*` hooks are banned in `atoms/`). Accept `readonly label: string` or `readonly ariaLabel: string` via `props`.
3. **No Raw HTML Tags**:
   - Never render `<h1>{t('title')}</h1>` or `<div>{t('body')}</div>`; use `<panda.h1>{t('title')}</panda.h1>`, `<Box>{t('body')}</Box>`, or `@m3e/react` components.
