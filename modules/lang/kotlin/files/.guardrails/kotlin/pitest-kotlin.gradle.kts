// =============================================================================
// pitest-kotlin.gradle.kts — PITest + Arcmutate Kotlin Mutation Gate (lang:kotlin)
// Filters Kotlin coroutine/null-safety/when bytecode junk mutants via Arcmutate.
// Enforces >= 85% mutation & coverage thresholds and excludes Minecraft Mixins.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
// Apply in build.gradle.kts:
//   plugins { id("info.solidsoft.pitest") version "1.19.0" }
//   dependencies {
//       pitest("org.pitest:pitest-junit5-plugin:1.2.1")
//       pitest("com.arcmutate:pitest-kotlin-plugin:1.5.1")
//       testImplementation("io.kotest.extensions:kotest-extensions-pitest:1.3.0")
//   }
//   pitest {
//       pitestVersion.set("1.30.0")
//       testPlugin.set("junit5")
//       jvmArgs.set(listOf("-XX:+EnableDynamicAgentLoading"))
//       mutationThreshold.set(85)
//       coverageThreshold.set(85)
//       excludedClasses.set(setOf("*.mixin.*", "*Mixin*", "*\$DefaultImpls"))
//       outputFormats.set(setOf("XML", "HTML"))
//       threads.set(Runtime.getRuntime().availableProcessors())
//   }
