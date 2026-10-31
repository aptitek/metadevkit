---
name: material-3
description: >-
  Implement Google Material Design 3 (MD3) and Lock 3 Token Purity: semantic
  color pairing (primary/on-primary, surface-container/on-surface), MD3 shape
  scale, motion tokens, and @m3e/react or @material/web components. Use when
  designing or styling UI components.
---

# Skill: Material Design 3 & Lock 3 Token Purity (`material-3`)

Governed by `.guardrails/eslint/design-system.mjs` (**Lock 3: `m3-tokens`**).

## Core Rules
1. **Zero Hardcoded Colors**: Never hardcode hex/rgb/hsl/named colors outside `src/tokens/` and `src/theme/`.
2. **Mandatory Semantic Color Pairing**: Every `bg` token must be paired with its approved MD3 foreground `color` (`primary` ↔ `on-primary`, `surface-container` ↔ `on-surface`, `error-container` ↔ `on-error-container`).
3. **Shape, Motion & Typography Tokens**: Adhere to MD3 shape corners (`0, 4, 8, 12, 16, 20, 28, 32, 48, 9999`), MD3 motion tokens, and design system font families.
