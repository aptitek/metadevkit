---
name: panda-css-theming
description: >-
  Design the token hierarchy, semanticTokens, multi-theme architecture, cva()
  recipes, and sva() slot recipe anatomy in Panda CSS. Use when structuring
  design tokens in src/tokens/ or designing component variant APIs.
---

# Skill: Panda CSS Theming & Slot Recipe Architecture (`panda-css-theming`)

## 1. The 4-Layer Token Architecture
1. **Primitive Tokens (`theme.tokens`)**: Raw scale values named by what they are.
2. **Semantic Tokens (`theme.semanticTokens`)**: Role-based MD3 tokens (`primary`, `onPrimary`, `surface`, `onSurface`, `surfaceContainer`, `outline`, `outlineVariant`) handling light/dark mode in one place.
3. **Composite Styles (`textStyles`, `layerStyles`, `animationStyles`)**: Reusable typography and surface bundles.
4. **Recipes (`cva` / `sva` / `defineRecipe` / `defineSlotRecipe`)**:
   - Every recipe with `variants` **must** declare `defaultVariants` (enforced by `missingDefaultVariants` in `design-system.mjs`).
   - Every slot declared in `sva({ slots: [...] })` **must** have styles under `base` (enforced by `unstyledRecipeSlot` in `design-system.mjs`).
   - Every recipe base that sets a background color (`bg`) **must** explicitly declare its paired MD3 foreground `color` (enforced by `missingColorPairing` in `design-system.mjs`).
