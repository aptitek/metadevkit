---
name: tdd
description: >-
  Test-Driven Development (Red-Green-Refactor) and Lock 6 Testing Fortress:
  mandatory 1:1 .test.ts(x) companions, zero module mocking (vi.mock), zero weak
  matchers, and >= 95% StrykerJS mutation score. Use when building features or
  fixing bugs.
---

# Skill: TDD & Lock 6 Testing Fortress (`tdd`)

Governed by `.guardrails/eslint/testing-fortress.mjs`, `.guardrails/scripts/lint-tdd-companions.mjs`, `.guardrails/scripts/verify-tdd-staged.mjs`, and `stryker.config.mjs`.

## 1. Mandatory 1:1 Unit Test Companions
- Every implementation file in `src/`, `simulations/`, and `scripts/` (excluding pure barrel `index.ts`, `types.ts`, `tokens/`, `i18n/`) **must** have a colocated `.test.ts` or `.test.tsx` companion.
- Storybook `.stories.tsx` files do **not** substitute for `.test.tsx` unit tests.
- Staging an implementation file without its `.test.ts(x)` companion is blocked by `verify-tdd-staged.mjs`.

## 2. Lock 6 — Test Assertion Purity (`testing-fortress.mjs`)
1. **No Skipped, Focused, or Todo Tests**: `it.skip`, `test.only`, `describe.skip`, `it.todo` are strictly forbidden.
2. **No Hollow Tests**: Every `it(...)` / `test(...)` block must contain at least one `expect(...)` or `assert*(...)` call.
3. **No Weak or Snapshot Matchers**: `.toBeTruthy()`, `.toBeFalsy()`, `.toBeDefined()`, `.toMatchSnapshot()`, and `.toMatchInlineSnapshot()` are forbidden. Assert exact values (`.toBe()`, `.toEqual()`, `.toStrictEqual()`).
4. **No Module Mocking**: `vi.mock()`, `jest.mock()`, `vi.spyOn()`, and `vi.doMock()` are forbidden. Inject dependencies explicitly via function parameters or React props.

## 3. Verification Commands
- Inner-loop unit test run: `task test:quick`
- Companion & assertion lint: `task testing-fortress:lint`
- StrykerJS mutation gate (`>= 95%` break threshold): `task testing-fortress:mutation`
