### `fw:react` — React Strict i18n (Lock 2) & Stateless Atomic Purity (Lock 4)
- **Locked Configs**: `.size-limit.json`, `.guardrails/eslint/react.mjs`, `.guardrails/depcruise/react.cjs`.
- **Lock 2 (Strict i18n)**: Bans raw user-facing string literals in JSX and functions; requires `src/i18n/strings.ts`.
- **Lock 4 (True Atomic Purity)**: Max 150 lines per `.tsx` component; bans raw HTML (`<div>`), `<panda.div>`, `style={}`, Tailwind classes, `useEffect` in UI/routes, and all `use*` hooks in `src/components/atoms/`.
