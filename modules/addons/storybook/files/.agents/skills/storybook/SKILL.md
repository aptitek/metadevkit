---
name: storybook
description: >-
  Write CSF3 Storybook stories (.stories.tsx) with 100% component coverage,
  autodocs, and interaction play tests. Use when creating or updating React
  components in projects with addon:storybook.
---

# Skill: Storybook CSF3 Fortress (`storybook`)

Governed by `.guardrails/eslint/storybook.mjs` and `.guardrails/scripts/lint-storybook-coverage.mjs`.

## 1. 100% Component Story Coverage (`lint-storybook-coverage.mjs`)
- Every React component (`.tsx`) in `src/components/` and `simulations/` (excluding `index.tsx`, `main.tsx`, `root.tsx`, `error-boundary.tsx`) **must** have a colocated `.stories.tsx` companion.

## 2. Strict CSF3 Object Notation (`storybook.mjs`)
- **Required**: Default `Meta<typeof Component>` export + named `StoryObj<typeof meta>` object exports (`export const Default: Story = { args: { ... } }`).
- **Forbidden**: Legacy `storiesOf()`, CSF2 `Template.bind({})`, and exported function/arrow-function stories.

```tsx
import type { Meta, StoryObj } from "@storybook/react";
import { Button } from "./Button";

const meta = {
  title: "Atoms/Button",
  component: Button,
  tags: ["autodocs"],
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {},
};
```

## 3. Verification
Run `task storybook:lint` (or `task check:quick`).
