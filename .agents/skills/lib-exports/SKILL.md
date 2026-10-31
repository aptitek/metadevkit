---
name: lib-exports
description: >-
  Maintain explicit named barrel exports in src/index.ts and ESM package.json
  export maps (addon:lib-exports). Use when adding, renaming, or exporting public
  components, hooks, themes, or tokens in a shared library.
---

# Skill: Library Barrel & Package Exports (`lib-exports`)

Governed by `.guardrails/scripts/lint-exports.mjs` and `.guardrails/taskfiles/Taskfile.lib-exports.yml`.

## 1. Contract for `src/index.ts`
1. **Zero Wildcard Re-Exports**:
   - `export * from "..."` is strictly forbidden in `src/index.ts` (and across all `src/` modules). Explicitly list every exported symbol and type (`export { Button, type ButtonProps } from "./components/atoms/Button"`).
2. **Stylesheet Entrypoint**:
   - When `src/index.css` exists, `src/index.ts` must import `"./index.css"` at the top of the barrel file.
3. **ESM `package.json` Exports**:
   - When `package.json` defines an `"exports"` map, it must include a valid root `"."` entry with `"types"` and `"import"` targets.
4. **Verification**:
   - Run `task lib-exports:lint` (or `task verify`).
