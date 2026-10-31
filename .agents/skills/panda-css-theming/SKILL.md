---
name: panda-css-theming
description: >-
  Design the token hierarchy, semanticTokens, multi-theme architecture, cva()
  recipes, and sva() slot recipe anatomy in Panda CSS. Use when structuring
  design tokens in src/tokens/ or designing component variant APIs.
---

# Skill: Panda CSS Theming & Slot Recipe Architecture (`panda-css-theming`)

## Core Rules
- Every recipe with `variants` must declare `defaultVariants`.
- Every slot declared in `sva({ slots: [...] })` must have styles under `base`.
- Every recipe base that sets `bg` must explicitly declare its paired MD3 foreground `color`.
- Avoid duplicate recipe blocks (`>= 4` shared `key=value` pairs regardless of property order).
