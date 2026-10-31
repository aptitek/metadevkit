---
name: minecraft-testing
description: >-
  Write automated unit, property, and in-game tests for Minecraft 1.21+ mods.
  Covers Kotest / JUnit 5 pure unit tests, Mojang GameTest Server harness
  (runGameTestServer), FabricGameTest, and JaCoCo coverage with Mixin exclusions.
---

# Minecraft Mod Testing (`minecraft-testing`)

## 1. Two-Tier Testing Strategy
1. **Tier 1 — Fast Pure JVM Unit Tests (`task test`)**:
   - Isolate domain logic, codecs, math, rule evaluation, cooldowns, and state machines from `MinecraftServer`/`Level` singletons.
   - Test with **Kotest** (`FunSpec`, `DescribeSpec`, `kotest-property`) or **JUnit 5** (`useJUnitPlatform()`).
   - Configure **JaCoCo** to exclude `**/mixin/**` bytecode injection classes (`exclude("**/mixin/**")`).
2. **Tier 2 — Headless Mojang GameTest Server (`task minecraft:gametest`)**:
   - Configure Loom's `gameTestServer` run configuration with `-Dfabric.gameTests=true` and `-Dfabric.gameTests.reportPath=build/reports/gametest-results.xml`.
   - Use `@GameTest(template = EMPTY_STRUCTURE)` and `GameTestHelper` assertions (`helper.assertBlockPresent(...)`, `helper.assertEntityPresent(...)`, `helper.succeed()`).
   - Commit `.nbt` structure templates under `src/main/resources/data/<modid>/structures/`.
