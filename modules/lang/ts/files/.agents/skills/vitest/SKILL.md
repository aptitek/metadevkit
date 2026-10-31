---
name: vitest
description: >-
  Vitest 5 unit testing and 95% per-file V8 coverage enforcement. Use when
  writing unit tests, type-level tests (expectTypeOf), or troubleshooting
  coverage thresholds in lang:ts projects.
---

# Skill: Vitest Unit & Coverage Fortress (`vitest`)

## 1. Per-File Coverage Thresholds (`vitest.config.ts`)
`vitest.config.ts` enforces strict V8 coverage thresholds with `perFile: true`:
- **Lines**: `>= 95%`
- **Functions**: `>= 95%`
- **Statements**: `>= 95%`
- **Branches**: `>= 90%`

## 2. Writing High-Signal Unit Tests
1. **Test pure behavior through public interfaces**: Pass dependencies explicitly as function arguments instead of using module mocks (`vi.mock()` and `jest.mock()` are forbidden by Lock 6).
2. **Use exact semantic assertions**:
   - Prefer `.toBe()`, `.toEqual()`, `.toStrictEqual()`, `.toContain()`, `.toHaveLength()`.
   - Weak/tautological matchers (`.toBeTruthy()`, `.toBeFalsy()`, `.toBeDefined()`, `.toMatchSnapshot()`, `.toMatchInlineSnapshot()`) are forbidden.
3. **Type-level testing**:
   - Use `expectTypeOf` from `vitest` to verify generic contracts and discriminated unions.
4. **Commands**:
   - Fast inner-loop run: `task test:quick`
   - Full coverage run: `task test` (or `task ts:test`)
