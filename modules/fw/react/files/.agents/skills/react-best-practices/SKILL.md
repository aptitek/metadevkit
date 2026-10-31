---
name: react-best-practices
description: >-
  React 19 and Lock 4 True Atomic Purity guidelines: stateless atoms, zero raw
  lowercase HTML tags, zero useEffect in UI/routes, strategic Error Boundaries,
  and Vercel React performance patterns. Use when writing or refactoring React
  components.
---

# Skill: React 19 & Lock 4 True Atomic Purity (`react-best-practices`)

## 1. Lock 4 — True Atomic Purity & Stateless Atoms (`.guardrails/eslint/react.mjs`)
1. **No Raw HTML Tags or `<panda.div>`**:
   - Lowercase HTML elements (`<div>`, `<span>`, `<p>`, `<button>`, `<input>`, `<svg>`) and generic `<panda.div>`, `<panda.span>`, `<panda.button>`, or `panda('div')` are forbidden in `.tsx`.
   - Use Panda CSS layout primitives (`<Box>`, `<Flex>`, `<Grid>`, `<Stack>`, `<HStack>`, `<VStack>`, `<Center>`, `<Container>`), semantic `<panda.main>` / `<panda.header>` / `<panda.section>` / `<panda.h1>`, or `@m3e/react` / `<md-*>` Material Design 3 components.
2. **No Inline Styles or Tailwind Classes**:
   - `style={{ ... }}` and Tailwind utility class names (`flex`, `items-center`, `px-4`) are strictly forbidden.
3. **100% Stateless Atoms (`src/components/atoms/`)**:
   - Every atom in `src/components/atoms/` must be a pure function of its `props`.
   - **All React hooks (`useState`, `useRef`, `useContext`, `useTranslation`, custom `use*`) are banned in `src/components/atoms/`**. Pass localized labels and callbacks via `props` from molecules/organisms.
4. **Zero `useEffect` / `useLayoutEffect` in UI & Routes**:
   - Derive values during render, handle side effects in event handlers, or use route `loader`/`action` functions.
5. **Component Size Limit**:
   - Every `.tsx` component file is capped at **150 non-blank/non-comment lines** (`max-lines-per-function <= 28`).

## 2. Strategic Error Boundaries (`lint-error-boundaries.mjs`)
- `src/components/error-boundary.tsx` must define a class extending `Component` with `getDerivedStateFromError`, `role="alert"`, and `data-error-boundary`.
- Interactive organisms and simulations must be wrapped in `<ErrorBoundary>`.

## 3. Performance Optimization Rules
- Eliminate async waterfalls (`Promise.all` in loaders).
- Avoid barrel imports for heavy third-party libraries; import individual `@m3e/react/*` or `@material/web/*` entrypoints.
- Use `startTransition` and `useDeferredValue` for non-urgent UI updates.
