---
name: gradle-expert
description: >-
  Expert Gradle build automation skill focusing on modern Gradle with Kotlin DSL
  (build.gradle.kts), multi-project enterprise configurations, Minecraft Loom
  (Quilt Loom / Fabric Loom), build cache optimization, task configuration avoidance,
  Detekt static analysis, Kotest / JUnit 5, and JaCoCo coverage.
---

# Gradle Expert & Build Automation (`gradle-expert`)

## 1. Universal Command Rule
In `polyglot-guardrails` repositories, always execute builds, linters, and tests through `task` (`task setup`, `task lint`, `task test`, `task verify`). This skill guides how you author and maintain `build.gradle.kts`, `settings.gradle.kts`, and `gradle.properties`.

## 2. Modern Gradle Kotlin DSL (`build.gradle.kts`) Conventions
1. **Declarative Plugins & Java 21 Toolchain**:
   ```kotlin
   plugins {
       java
       kotlin("jvm") version "2.1.10" apply false
       id("io.gitlab.arturbosch.detekt") version "1.23.8"
       jacoco
   }

   java {
       toolchain {
           languageVersion.set(JavaLanguageVersion.of(21))
       }
       withSourcesJar()
   }
   ```
2. **Task Configuration Avoidance**:
   - Never use eager `tasks.create(...)` or `tasks.getByName(...)`.
   - Always use `tasks.register(...)` and `tasks.withType<T>().configureEach { ... }`:
     ```kotlin
     tasks.withType<JavaCompile>().configureEach {
         options.encoding = "UTF-8"
         options.release.set(21)
     }
     ```
3. **Detekt & Multi-Module Boundary Configs (`config/detekt/` or `detekt.yml`)**:
   ```kotlin
   detekt {
       buildUponDefaultConfig = true
       allRules = true
       val baseConfig = rootProject.file("detekt.yml")
       val moduleConfig = rootProject.file("config/detekt/detekt-${project.name}.yml")
       if (moduleConfig.exists()) {
           config.setFrom(baseConfig, moduleConfig)
       } else {
           config.setFrom(baseConfig)
       }
       parallel = true
   }
   ```
4. **JUnit Platform, Kotest & JaCoCo (`**/mixin/**` Exclusion)**:
   ```kotlin
   tasks.withType<Test>().configureEach {
       useJUnitPlatform()
       finalizedBy(tasks.named("jacocoTestReport"))
   }

   tasks.withType<JacocoReport>().configureEach {
       reports {
           xml.required.set(true)
           html.required.set(true)
       }
       classDirectories.setFrom(
           files(classDirectories.files.map {
               fileTree(it) {
                   exclude("**/mixin/**")
               }
           })
       )
   }
   ```
5. **Minecraft Loom GameTest Server Harness**:
   ```kotlin
   loom {
       runs {
           create("gameTestServer") {
               server()
               name("Game Test Server")
               vmArg("-Dfabric.gameTests=true")
               vmArg("-Dfabric.gameTests.reportPath=build/reports/gametest-results.xml")
               runDir("build/gametest")
           }
       }
   }
   ```
