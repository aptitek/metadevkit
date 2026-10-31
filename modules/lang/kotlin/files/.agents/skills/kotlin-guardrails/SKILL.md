---
name: kotlin-guardrails
description: >-
  Kotlin 2.x quality guardrails for lang:kotlin modules (Detekt maxIssues: 0,
  detekt-formatting, per-module ForbiddenImport boundaries, Kotest JUnit 5, JaCoCo).
  Use when configuring, linting, formatting, or testing Kotlin JVM projects.
---

# Skill: Kotlin Quality Guardrails (`kotlin-guardrails`)

## 1. Universal Command Interface (`task`)
Always run Kotlin workflows through `task` (`task format`, `task lint`, `task test`, `task verify`). Never invoke `gradle`, `./gradlew`, or `detekt` directly.

## 2. Detekt Fortress (`detekt.yml`)
- `detekt.yml` is cryptographically locked in `.guardrails.lock` with `maxIssues: 0` and `warningsAsErrors: true`.
- **Module Boundary Overlays**:
  - Server-only modules can layer `.guardrails/kotlin/detekt-server-boundary.yml` (or `config/detekt/detekt-<module>.yml`) to ban `net.minecraft.client.*`, `com.mojang.blaze3d.*`, and client entrypoints via `ForbiddenImport`.
  - Client-only modules can layer `.guardrails/kotlin/detekt-client-boundary.yml` to ban `net.minecraft.server.dedicated.*` and server entrypoints.
- **Zero Linter Bypass**: `@Suppress(...)` and `@file:Suppress(...)` are forbidden by `.guardrails/ast/no-linter-bypass.yml`. Refactor complex methods into small, cohesive helpers instead of suppressing Detekt rules.
