### `lang:ts` — TypeScript Functional Purity & Total Functions (Lock 1)
- **Locked Configs**: `tsconfig.base.json`, `eslint.config.mjs`, `knip.json`, `vitest.config.ts`, `.dependency-cruiser.cjs`, `.prettierrc.mjs`, `commitlint.config.mjs`, `.secretlintrc.json`, `.jscpd.json`.
- **Lock 1 (`src/`)**: `complexity <= 3`, `max-depth <= 1`, `max-lines <= 150`, `max-lines-per-function <= 28`, `max-params <= 3`. Bans `let`/`var`, mutation, imperative loops, `else`, `as T`, `x!`, `is T` type predicates, `throw`/`try-catch` in pure modules, and wildcard `export *`.
- **Coverage Gate**: `vitest.config.ts` enforces `>= 95%` per-file lines, functions, branches, and statements.
