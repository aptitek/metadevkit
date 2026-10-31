---
name: typescript-expert
description: >-
  TypeScript and Lock 1 Functional Purity expert: strict tsconfig.base.json,
  total functions, discriminated unions, branded types, Dependency Cruiser DAG
  boundaries, and Knip dead-code elimination. Use when writing, typing, or
  refactoring TypeScript modules.
---

# Skill: TypeScript & Lock 1 Functional Purity (`typescript-expert`)

## 1. Lock 1 — Functional Purity & Total Functions (`src/`)
Every file in `src/` is enforced by `.guardrails/eslint/ts.mjs`:
- **Biometric limits**: `complexity <= 3`, `max-depth <= 1`, `max-lines <= 150`, `max-lines-per-function <= 28`, `max-params <= 3`, `max-statements <= 12`.
- **Immutability**:
  - `let` and `var` are forbidden; use `const` exclusively.
  - Variable reassignment and object/array property mutation (`obj.x = 1`) are forbidden.
  - Mutating array methods (`.push`, `.pop`, `.shift`, `.unshift`, `.splice`, `.sort`, `.reverse`, `.fill`) are forbidden; use `.map()`, `.filter()`, `.reduce()`, `.flatMap()`, `.toSorted()`, `.toReversed()`.
- **Control flow & Totality**:
  - Imperative loops (`for`, `for..in`, `for..of`, `while`, `do..while`) and `else` branches are forbidden; use early return guard clauses and declarative array combinators.
  - `throw` and `try..catch` are forbidden in pure modules; return a discriminated union `Result<T, E>`.
- **Sound Type System**:
  - `any`, `as T` (except `as const`), `x!`, and user-defined type predicates (`x is T`) are forbidden.
  - Use `satisfies` for compile-time constraint validation without widening.
