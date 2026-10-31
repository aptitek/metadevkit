---
name: java-guardrails
description: >-
  Java 21 quality guardrails for lang:java modules (Gradle, Spotless, Checkstyle, PMD, JUnit 5, JaCoCo).
  Use when writing, formatting, linting, or testing Java code.
---

# Skill: Java 21 Quality Guardrails (`java-guardrails`)

## Rules & Workflow
1. **Command Interface**: Always run Java checks via `task` (`task format`, `task lint`, `task test`, `task verify`). Never invoke `gradle` or `./gradlew` directly.
2. **Static Analysis & Formatting**:
   - Formatting is enforced via `spotlessApply` / `spotlessCheck` and `.guardrails/java/checkstyle.xml` (max line length `120`, max method length `40`, max parameters `5`, no star imports).
   - Static analysis is enforced via `.guardrails/java/pmd-ruleset.xml` and `.guardrails/ast/java.yml` (cyclomatic complexity `<= 10`, cognitive complexity `<= 10`, no `System.out`/`System.err`, no `printStackTrace()`, no raw `Optional.get()`).
3. **Zero Bypass**: `@SuppressWarnings` and `NOPMD` annotations/comments are strictly forbidden by `.guardrails/ast/no-linter-bypass.yml`.
4. **Testing**: JUnit 5 (`useJUnitPlatform()`) and `jacocoTestReport` enforce unit test coverage (`exclude("**/mixin/**")` for Minecraft mods).
