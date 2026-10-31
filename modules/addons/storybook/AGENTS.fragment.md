### `addon:storybook` — 100% CSF3 Component Story Coverage
- **Locked Configs**: `.storybook/main.ts`, `.storybook/preview.ts`, `.guardrails/eslint/storybook.mjs`, `.guardrails/depcruise/storybook.cjs`.
- **Quality Gates**: Requires a 1:1 `.stories.tsx` CSF3 companion (`satisfies Meta<typeof Component>`) for every UI component under `src/components/`.
