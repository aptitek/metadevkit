---
name: mutation-testing
description: Run and enforce cross-language mutation testing (task mutate) using StrykerJS (TypeScript >=95%), mutmut (Python >=90%), PITest + Arcmutate (Java/Kotlin >=85%), and Infection + PHPStan (PHP >=85%) with unified mutation-testing-elements reporting.
---

# Polyglot Mutation Testing (`addon:testing-fortress`)

## 1. Universal Command Contract (`task mutate`)
Never invoke `stryker`, `mutmut`, `./gradlew pitest`, or `infection` directly. Always run:
- `task mutate` — Executes mutation testing across all active language modules (`ts:mutate`, `python:mutate`, `java:mutate`, `kotlin:mutate`, `php:mutate`).

## 2. Homogenous Cross-Language Mutation Matrix

| Language Module | Engine | Locked Config | MSI Threshold | Surviving Mutants | Unified Report |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`lang:ts`** | **StrykerJS** (`@stryker-mutator/vitest-runner`) | `stryker.config.mjs` | **`>= 95%`** (`break: 95`) | `0` critical | `reports/mutation/mutation.json` |
| **`lang:python`** | **mutmut 3.x** (`pytest` runner) | `.guardrails/python/mutmut.toml` | **`>= 90%`** | `0` (`max_survivors = 0`) | `reports/mutation/mutation.json` |
| **`lang:java`** | **PITest 1.30.0** (`pitest-junit5-plugin`) | `.guardrails/java/pitest.gradle.kts` | **`>= 85%`** (`coverage >= 85%`) | `0` in domain | `build/reports/pitest/` (`XML` + `HTML`) |
| **`lang:kotlin`** | **PITest 1.30.0 + Arcmutate Kotlin** | `.guardrails/kotlin/pitest-kotlin.gradle.kts` | **`>= 85%`** (`STRONGER`) | `0` in domain | `build/reports/pitest/` (`XML` + `HTML`) |
| **`lang:php`** | **Infection PHP + PHPStan** | `infection.json5` | **`>= 85%`** (`covered >= 90%`) | `0` escaped | `reports/mutation/mutation.json` |

## 3. Eliminating Surviving Mutants (Lock 6 Assertion Purity)
1. **Boundary Mutants (`<` vs `<=`)**: Always write explicit boundary value tests (`n - 1`, `n`, `n + 1`).
2. **Return Value Mutants (`Boolean` / `Optional` / `Result`)**: Never assert `toBeTruthy()` or `assert res`. Assert exact return payloads (`expect(res).toEqual({ ok: true, value: 42 })`).
3. **Kotlin Coroutine & Null-Safety Bytecode Mutants**: Always apply `.guardrails/kotlin/pitest-kotlin.gradle.kts` which enables `com.arcmutate:pitest-kotlin-plugin` to filter compiler-generated null-check and coroutine continuation bytecode.
4. **Minecraft Mixin Classes**: `*.mixin.*` packages are automatically excluded from PITest bytecode mutation because Mixin classes are transformed at runtime by SpongePowered Mixin.

## 4. Deep-Dive Reference
- Load `references/polyglot-mutation-configs.md` for engine-specific configuration blocks, Equivalent Mutant handling without linter bypasses, and CI incremental history caching.
