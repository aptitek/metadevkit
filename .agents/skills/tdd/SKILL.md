---
name: tdd
description: >-
  Test-Driven Development (Red-Green-Refactor) and Lock 6 Testing Fortress:
  mandatory 1:1 .test.ts(x) companions, zero module mocking (vi.mock), zero weak
  matchers, and >= 95% StrykerJS mutation score. Use when building features or
  fixing bugs.
---

# Skill: TDD & Lock 6 Testing Fortress (`tdd`)

Governed by `.guardrails/eslint/testing-fortress.mjs`, `lint-tdd-companions.mjs`, `verify-tdd-staged.mjs`, and `stryker.config.mjs`.

## Core Rules
- Every implementation module in `src/`, `simulations/`, and `scripts/` must have a colocated `.test.ts(x)` unit test companion.
- `it.skip`, `test.only`, `it.todo`, hollow tests without `expect()`, weak matchers (`.toBeTruthy()`, `.toBeFalsy()`, `.toBeDefined()`, `.toMatchSnapshot()`), and `vi.mock()`/`jest.mock()` are strictly forbidden.
- StrykerJS enforces a `>= 95%` mutation score threshold (`task testing-fortress:mutation`).
