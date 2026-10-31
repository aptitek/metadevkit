---
name: panda-css
description: >-
  Write and edit styles with Panda CSS and Lock 5 Recipe Purity: JSX layout
  primitives (<Box>, <Flex>, <Grid>, <Stack>), max 3 inline style props, zero
  conditional style ternaries, zero prop spreading, and cva()/sva() recipes.
---

# Skill: Panda CSS & Lock 5 Recipe Purity (`panda-css`)

Governed by `panda.config.ts` and `.guardrails/eslint/design-system.mjs` (**Lock 5: `panda-recipes/enforce-recipe-usage`**).

## Core Rules
- Max 3 static inline style props on JSX layout containers (`<Box>`, `<Flex>`, `<Grid>`, `<Stack>`, `<HStack>`, `<VStack>`, `<Center>`, `<Container>`).
- Zero conditional/ternary expressions in style props and zero JSX prop spreading (`{...props}`).
- Extract `cva()` or `sva()` recipes with `defaultVariants` whenever `> 3` style props or variants are needed.
