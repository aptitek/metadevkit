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

## 1. Mandatory Semantic Color Pairing (`m3-tokens/enforce-color-pairing`)
Never hardcode hex/rgb/hsl/named colors outside `src/tokens/` and `src/theme/`. Every background token (`bg`, `background`, `backgroundColor`) MUST be paired with its approved MD3 foreground token (`color`):

| Background Token (`bg`) | Allowed Foreground Token(s) (`color`) |
| :--- | :--- |
| `primary` | `on-primary`, `onPrimary` |
| `primary-container`, `primaryContainer` | `on-primary-container`, `onPrimaryContainer` |
| `secondary` | `on-secondary`, `onSecondary` |
| `secondary-container`, `secondaryContainer` | `on-secondary-container`, `onSecondaryContainer` |
| `tertiary` | `on-tertiary`, `onTertiary` |
| `tertiary-container`, `tertiaryContainer` | `on-tertiary-container`, `onTertiaryContainer` |
| `error` | `on-error`, `onError` |
| `error-container`, `errorContainer` | `on-error-container`, `onErrorContainer` |
| `surface`, `surface-dim`, `surface-bright`, `surface-container*` | `on-surface`, `onSurface`, `on-surface-variant`, `onSurfaceVariant`, `primary`, `secondary`, `tertiary` |
| `inverse-surface`, `inverseSurface` | `inverse-on-surface`, `inverseOnSurface`, `inverse-primary`, `inversePrimary` |

## 2. Shape, Motion, and Typography Tokens
- **Shape corners (`m3-tokens/enforce-shape-tokens`)**: Only MD3 corner scale values (`0`, `4`, `8`, `12`, `16`, `20`, `28`, `32`, `48`, `9999`) or semantic tokens (`none`, `extraSmall`, `small`, `medium`, `large`, `extraLarge`, `full`) are allowed.
- **Motion (`m3-tokens/enforce-motion-tokens`)**: Raw `cubic-bezier(...)` and raw durations (`300ms`, `0.2s`) are banned in components; use MD3 duration/easing tokens (`short3`, `medium1`, `long2`, `emphasized`, `standard`). `transition: all` is forbidden in CSS.
- **Typography (`m3-tokens/enforce-typography-tokens`)**: Raw `font-family` strings are forbidden; use `var(--font-family-*)` or MD3 typescale tokens.
