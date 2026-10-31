---
name: clean-code-java
description: >-
  Expert Java 21 craftsmanship skill focusing on writing clean, idiomatic, high-performance,
  and maintainable Java code. Enforces Modern Java 21 features (records, sealed classes,
  pattern matching), Effective Java design patterns, SOLID principles, zero-allocation
  hot-path practices, concurrency safety, and fluent testing with JUnit 5, AssertJ, and ArchUnit.
---

# Clean Code Java & Software Craftsmanship (`clean-code-java`)

## 1. Core Architectural & Design Principles
- **Single Responsibility (SRP)**: Each class and method has one reason to change. Separate pure domain calculation from I/O, networking, and game-world state mutation.
- **Open / Closed (OCP)**: Prefer sealed hierarchies (`sealed interface` + `permits`) and exhaustive `switch` expressions over mutable branch chains.
- **Dependency Inversion (DIP)**: Depend on interfaces and immutable records; inject dependencies via constructors.
- **Complexity Limits (`.guardrails/java/pmd-ruleset.xml` & `checkstyle.xml`)**:
  - `CyclomaticComplexity <= 10`, `CognitiveComplexity <= 10`
  - `MethodLength <= 40` lines, `ClassLength <= 250` lines, `ParameterNumber <= 5`, `LineLength <= 120`
  - Zero wildcard imports (`import ...*;` is forbidden).

## 2. Modern Java 21 Idioms
1. **Records for Immutable Data Carriers**:
   ```java
   public record Vector3i(int x, int y, int z) {
       public Vector3i {
           // compact constructor for invariant checks
       }
       public Vector3i add(int dx, int dy, int dz) {
           return new Vector3i(x + dx, y + dy, z + dz);
       }
   }
   ```
2. **Sealed Interfaces & Exhaustive Pattern Matching**:
   ```java
   public sealed interface ActionStatus permits Pending, Executing, Succeeded, Failed {}

   public String formatStatus(ActionStatus status) {
       return switch (status) {
           case Pending p -> "Waiting in queue: " + p.position();
           case Executing e -> "Executing tick " + e.elapsedTicks();
           case Succeeded s -> "Completed in " + s.durationMs() + "ms";
           case Failed f -> "Failed: " + f.reason();
       };
   }
   ```
3. **Optionals & Null-Safety**:
   - Never return `null` from domain methods; return `Optional<T>`.
   - Never call `optional.get()` directly (forbidden by `.guardrails/ast/java.yml`); use `map()`, `flatMap()`, `orElse()`, `orElseGet()`, or `orElseThrow()`.
4. **Zero-Allocation Hot Paths**:
   - In 20 TPS tick loops or 60+ FPS render hooks, avoid allocating intermediate `Stream` pipelines or capturing lambdas; use indexed loops and primitive arrays.
5. **Structured Logging**:
   - Never call `System.out.println`, `System.err.println`, or `e.printStackTrace()` (forbidden by `.guardrails/ast/java.yml`). Always use SLF4J (`LoggerFactory.getLogger` or `LogUtils.getLogger()`).

## 3. Verification via `task`
Always verify using `task lint` and `task verify` (never run `./gradlew` directly).
