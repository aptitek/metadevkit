### `lang:kotlin` — Kotlin 2.x (K2) Quality Fortress
- **Locked Configs**: `detekt.yml`, `.guardrails/kotlin/pitest-kotlin.gradle.kts`.
- **Quality Gates**: Detekt `maxIssues: 0` & `warningsAsErrors: true` (`CyclomaticComplexMethod <= 8`, `CognitiveComplexMethod <= 8`, `LongMethod <= 40`, `LargeClass <= 250`), zero wildcard imports, zero `!!` non-null assertions in `src/main/`, zero `GlobalScope`, zero `println` in `src/main/`, Kotest + JaCoCo `>= 85%` coverage, and PITest + Arcmutate Kotlin `>= 85%` mutation threshold.
