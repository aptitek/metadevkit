### `lang:java` — Java 21 Static & Mutation Fortress
- **Locked Configs**: `.guardrails/java/checkstyle.xml`, `.guardrails/java/pmd-ruleset.xml`, `.guardrails/java/pitest.gradle.kts`.
- **Quality Gates**: Spotless formatting, Checkstyle & PMD (`CyclomaticComplexity <= 10`, `MethodLength <= 40`, `ClassLines <= 250`), zero wildcard imports, zero `System.out`/`printStackTrace()` in `src/main/`, JaCoCo `>= 85%` coverage, and PITest 1.30.0 `>= 85%` mutation threshold.
