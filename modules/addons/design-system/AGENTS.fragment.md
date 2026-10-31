### `addon:design-system` — M3 Token Purity (Lock 3) & Panda CSS Recipes (Lock 5)
- **Locked Configs**: `panda.config.ts`, `.guardrails/eslint/design-system.mjs`, `.guardrails/depcruise/design-system.cjs`.
- **Lock 3 & Lock 5**: Bans hardcoded colors/durations/radii/fonts, enforces MD3 `bg` ↔ `color` semantic token pairing, limits JSX containers to max 3 inline layout props, and requires `defaultVariants` + commutative recipe deduplication.
