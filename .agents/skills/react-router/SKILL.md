---
name: react-router
description: >-
  Build and validate React Router v7 applications enforcing route parsimony,
  nested <Outlet /> layouts, loader/action separation, and Atomic Design route
  boundaries. Use when configuring routes, loaders, actions, or navigation.
---

# Skill: React Router v7 Fortress (`react-router`)

Governed by `.guardrails/eslint/react-router.mjs`, `.guardrails/ast/react-router.yml`, and `.guardrails/scripts/lint-routes.mjs`.

## Core Rules
- **Route Parsimony**: Max 2 top-level layout groups and max 12 total route definitions in `src/routes.ts` / `app/routes.ts`.
- **No Direct Atom/Molecule Imports in Routes**: Route modules (`routes/**`) must compose pages, templates, or organisms.
- **Strict `loader` vs `action` Separation**: `loader` functions must be read-only; mutations belong in `action` exports.
