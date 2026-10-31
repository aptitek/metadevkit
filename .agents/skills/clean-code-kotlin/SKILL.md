---
name: clean-code-kotlin
description: >-
  Expert Kotlin 2.x (K2) craftsmanship skill focusing on writing clean, idiomatic,
  high-performance, and maintainable Kotlin code for the JVM and Minecraft mods.
  Enforces value classes, sealed hierarchies, zero-allocation hot-path practices
  in tick loops, Java-Kotlin interop for Mixins (@JvmStatic, @JvmField, @JvmName),
  Kotest testing, and strict Detekt static analysis compliance (maxIssues: 0).
---

# Clean Code Kotlin & Craftsmanship (`clean-code-kotlin`)

## 1. Core Architectural & Idiomatic Principles
- **Expression-Oriented Design**: Prefer `when`, `if`, and `runCatching` as expressions returning values.
- **Immutability by Default (`VarCouldBeVal`)**:
  - Prefer `val` over `var` universally.
  - Expose read-only collection interfaces (`List`, `Map`, `Set`) backed by private mutable state when needed.
- **Detekt Complexity Thresholds (`detekt.yml`)**:
  - `maxIssues: 0`, `warningsAsErrors: true`
  - `ComplexCondition: 3`, `CyclomaticComplexMethod: 10`, `CognitiveComplexMethod: 10`
  - `LargeClass: 250`, `LongMethod: 40`, `LongParameterList: 5`, `NestedBlockDepth: 3`
  - `MaxLineLength: 120`, `ReturnCount: 3`, `ThrowsCount: 2`
- **Zero Non-Null Assertions (`!!`) & Zero Wildcard Imports**:
  - Never use `!!` in `src/main/` (forbidden by `.guardrails/ast/kotlin.yml` and Detekt `UnsafeCallOnNullableType`). Use `?: return`, `requireNotNull()`, or `checkNotNull()`.
  - Never use wildcard imports (`import ...*`).

## 2. Modern Kotlin 2.x (K2) Idioms
1. **Value Classes for Zero-Allocation Type Safety**:
   ```kotlin
   @JvmInline
   value class MessageId(val value: Long)

   @JvmInline
   value class RuleKey(val raw: String)
   ```
2. **Sealed Hierarchies & Exhaustive `when` (`ElseCaseInsteadOfExhaustiveWhen`)**:
   ```kotlin
   sealed interface TranslationStatus {
       data object Idle : TranslationStatus
       data class InProgress(val progress: Float) : TranslationStatus
       data class Completed(val result: String, val latencyMs: Long) : TranslationStatus
       data class Failed(val reason: String) : TranslationStatus
   }
   ```
   Never add an `else` branch to a `when` over a `sealed interface`.
3. **Structured Coroutines (`coroutines` ruleset)**:
   - Never use `GlobalScope` (`GlobalCoroutineUsage`).
   - Always inject `CoroutineDispatcher` (`InjectDispatcher`).
   - Never call `Thread.sleep` inside `suspend fun` (`SleepInsteadOfDelay`).

## 3. Zero-Allocation Hot-Path Practices (Minecraft 20 TPS Tick & 60+ FPS Render Loops)
- Avoid `.filter { }.map { }` chains inside per-tick or per-frame callbacks (they allocate intermediate `ArrayList` and `Iterator` instances).
- Prefer primitive arrays (`IntArray`, `FloatArray`, `LongArray`) over boxed `Array<Int>` or `List<Int>` (`ArrayPrimitive`).
- Avoid capturing local variables in lambdas invoked every tick.

## 4. Java Interop & Spongeian Mixins
- Use `@JvmStatic` on companion/object methods referenced by Java entrypoints or Mixins.
- Use `@JvmField` on constants and hot fields to eliminate getter/setter overhead.
- Use `@JvmName("cleanBytecodeName")` on `internal` functions called from Java Mixins to prevent `$module_name` name mangling.

## 5. Testing with Kotest
Use `FunSpec` or `DescribeSpec` with Kotest fluent matchers (`shouldBe`, `shouldNotBe`, `shouldContain`, `shouldThrow<T>`), and run via `task test` / `task verify`.
