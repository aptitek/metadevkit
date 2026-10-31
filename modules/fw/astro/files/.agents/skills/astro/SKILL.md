---
name: astro
description: >-
  Build content-focused websites and interactive islands with Astro (fw:astro).
  Use when working with .astro files, Astro.props, content collections, island
  hydration directives (client:visible, client:idle), or astro check.
---

# Skill: Astro Islands & Content Architecture (`astro`)

Governed by `.guardrails/eslint/astro.mjs` and `.guardrails/taskfiles/Taskfile.astro.yml`.

## 1. Islands Architecture & Hydration Discipline
- **Zero JS by default**: Keep layouts and static sections as `.astro` components.
- **Selective hydration**:
  - Prefer `client:visible` or `client:idle` for interactive React islands (e.g., simulations).
  - Avoid `client:load` unless the island is above-the-fold and immediately interactive.
  - Never use `client:only` without an explicit framework string (`client:only="react"`).
- **Wrap hydrated islands in `<ErrorBoundary>`** so any client island failure degrades gracefully with `role="alert"`.

## 2. Type-Safe Content Collections & Security
- Define Zod schemas in `src/content.config.ts` (or `src/content/config.ts`) for all Markdown/MDX collections.
- Never use `set:html` with unsanitized input (blocked by `.guardrails/eslint/astro.mjs`).
- Never expose non-`PUBLIC_` environment variables to client islands.
- Run `task astro:lint` (or `task verify`) to validate `astro check` and island directives.
