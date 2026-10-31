---
name: panda-css
description: >-
  Write and edit styles with Panda CSS and Lock 5 Recipe Purity: JSX layout
  primitives (<Box>, <Flex>, <Grid>, <Stack>), max 3 inline style props, zero
  conditional style ternaries, zero prop spreading, and cva()/sva() recipes.
---

# Skill: Panda CSS & Lock 5 Recipe Purity (`panda-css`)

Governed by `panda.config.ts` (`strictTokens: true`, `strictPropertyValues: true`) and `.guardrails/eslint/design-system.mjs` (**Lock 5: `panda-recipes/enforce-recipe-usage`**).

## 1. Lock 5 — Strict Panda CSS Rules
1. **Max 3 Inline Style Props on JSX Containers**:
   - `<Box>`, `<Flex>`, `<Grid>`, `<Stack>`, `<HStack>`, `<VStack>`, `<Center>`, `<Container>`, and semantic `<panda.*>` elements may have at most **3 static inline layout props**.
   - If an element needs `> 3` style properties, extract a declarative `cva()` or `sva()` recipe.
2. **Zero Conditional / Ternary Expressions in Style Props**:
   - Writing `bg={isActive ? "primary" : "surface"}` is forbidden. Define a `cva()` recipe with `variants` and `defaultVariants`.
3. **Zero JSX Prop Spreading (`{...props}`)**:
   - Prop spreading on Panda layout elements is forbidden so static extraction remains 100% deterministic.
4. **No Aliased `styled-system` Imports**:
   - Always use canonical export names from `styled-system/css` and `styled-system/jsx`.
5. **Canonical Commutative Recipe Deduplication**:
   - Two recipe `base` or slot blocks sharing `>= 4` identical `key=value` pairs (regardless of property order) are flagged as duplicates. Reuse or compose existing recipes instead.

## 2. Codegen Workflow
Run `task design-system:setup` (or `task verify`) after modifying `panda.config.ts` or token definitions.
