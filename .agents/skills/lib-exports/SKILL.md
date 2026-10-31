---
name: lib-exports
description: >-
  Maintain explicit named barrel exports in src/index.ts and ESM package.json
  export maps (addon:lib-exports). Use when adding, renaming, or exporting public
  components, hooks, themes, or tokens in a shared library.
---

# Skill: Library Barrel & Package Exports (`lib-exports`)

## Core Rules
- Wildcard `export * from` is forbidden in `src/index.ts`; use explicit named exports.
- Import `"./index.css"` at the top of `src/index.ts` when `src/index.css` is present.
- Ensure `package.json` `"exports"` defines a valid `"."` entry.
