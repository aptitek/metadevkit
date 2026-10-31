# Polyglot Mutation Testing Reference (`StrykerJS`, `mutmut`, `PITest + Arcmutate`, `Infection`)

## 1. TypeScript (`stryker.config.mjs`)
- **Runner**: `@stryker-mutator/vitest-runner` with `coverageAnalysis: "perTest"`.
- **Checker**: `@stryker-mutator/typescript-checker` rejects invalid type mutants before running tests.
- **Thresholds**: `high: 98`, `low: 95`, `break: 95`.
- **Unified Schema**: Outputs `reports/mutation/mutation.json` (`mutation-testing-elements` schema).

## 2. Python (`.guardrails/python/mutmut.toml`)
- **Runner**: `uv run pytest -x -q --tb=no`.
- **Target**: `paths_to_mutate = ["src"]`, `tests_dir = ["tests"]`.
- **Thresholds**: `min_mutation_score = 90`, `max_survivors = 0`.
- **Incremental Triage**:
  - Inspect survivors via `task mutate` logs.
  - Refactor complex branches into smaller pure helper functions (`CCN <= 8`) with deterministic unit tests.

## 3. Java 21 & Kotlin 2.x (`.guardrails/java/pitest.gradle.kts` & `.guardrails/kotlin/pitest-kotlin.gradle.kts`)
- **Plugin**: `info.solidsoft.pitest` version `1.19.0` with `pitestVersion = "1.30.0"` and `junit5PluginVersion = "1.2.1"`.
- **Java 21 Agent Flag**: `jvmArgs.set(listOf("-XX:+EnableDynamicAgentLoading"))`.
- **Kotlin Bytecode Filtering**: `com.arcmutate:pitest-kotlin-plugin:1.5.1` + `io.kotest.extensions:kotest-extensions-pitest:1.2.0` eliminates synthetic `Intrinsics.checkNotNullParameter` and coroutine state-machine mutants.
- **Minecraft Exclusions**: `excludedClasses.set(listOf("*.mixin.*", "*Mixin*"))`.

## 4. PHP (`infection.json5`)
- **Static Analysis Integration**: `staticAnalysisTool: "phpstan"` uses `phpstan.neon.dist` (`level: max`) to kill invalid type mutants statically without spinning up PHPUnit/Pest processes.
- **Thresholds**: `minMsi: 85`, `minCoveredMsi: 90`.
- **Unified Schema**: Outputs `reports/mutation/mutation.json` via the `stryker` report adapter.
