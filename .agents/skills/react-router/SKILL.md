---
name: react-router
description: >-
  Build and validate React Router v7 applications enforcing route parsimony,
  nested <Outlet /> layouts, loader/action separation, and Atomic Design route
  boundaries. Use when configuring routes, loaders, actions, or navigation.
---

# Skill: React Router v7 Fortress (`react-router`)

Governed by `.guardrails/eslint/react-router.mjs`, `.guardrails/ast/react-router.yml`, and `.guardrails/scripts/lint-routes.mjs`.

## 1. Route Parsimony & Hierarchy (`lint-routes.mjs`)
- **Max 2 top-level layout groups** and **max 12 total route definitions** in `src/routes.ts` / `app/routes.ts`.
- Every layout route must render a nested `<Outlet />` to compose child routes cleanly.

## 2. Strict Atomic & Data Boundaries
1. **No Direct Atom/Molecule Imports in Routes (`.guardrails/eslint/react-router.mjs`)**:
   - Route modules (`routes/**`) must compose **pages**, **templates**, or **organisms**—never import directly from `components/atoms/` or `components/molecules/`.
2. **Strict `loader` vs `action` Separation (`.guardrails/ast/react-router.yml`)**:
   - `loader` functions must be read-only (never perform `POST`/`PUT`/`DELETE`/`PATCH` mutations inside a `loader`).
   - All state mutations belong in `action` exports.
   - Never call `fetch()` directly inside React component render bodies; use `loader`, `action`, `useFetcher()`, or `<Form>`.
3. **Verification**:
   - Run `task react-router:lint` or `task check:quick` after editing routes.
