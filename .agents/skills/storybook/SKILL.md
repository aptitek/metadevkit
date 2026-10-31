---
name: storybook
description: >-
  Write CSF3 Storybook stories (.stories.tsx) with 100% component coverage,
  autodocs, and interaction play tests. Use when creating or updating React
  components in projects with addon:storybook.
---

# Skill: Storybook CSF3 Fortress (`storybook`)

Governed by `.guardrails/eslint/storybook.mjs` and `lint-storybook-coverage.mjs`.

## Core Rules
- Every React component (`.tsx`) in `src/components/` and `simulations/` must have a colocated `.stories.tsx` companion.
- Use CSF3 object notation (`Meta` default export + `StoryObj` object exports). Legacy `storiesOf()`, `Template.bind({})`, and function stories are forbidden.
