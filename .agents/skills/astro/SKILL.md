---
name: astro
description: >-
  Build content-focused websites and interactive islands with Astro (fw:astro).
  Use when working with .astro files, Astro.props, content collections, island
  hydration directives (client:visible, client:idle), or astro check.
---

# Skill: Astro Islands & Content Architecture (`astro`)

Governed by `.guardrails/eslint/astro.mjs` and `.guardrails/taskfiles/Taskfile.astro.yml`.

## Core Rules
- Keep layouts and static sections as `.astro` components (zero JS by default).
- Prefer `client:visible` or `client:idle` over `client:load`, and never use `client:only` without an explicit framework string.
- Never use `set:html` with unsanitized input.
