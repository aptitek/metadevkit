// =============================================================================
// pitest.gradle.kts — PITest Mutation Testing Configuration for Java 21 (lang:java)
// Plugin: id("info.solidsoft.pitest") version "1.19.0"
// Enforces >= 85% mutation & coverage thresholds and excludes Minecraft Mixins.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
// Apply in build.gradle.kts:
//   plugins { id("info.solidsoft.pitest") version "1.19.0" }
//   dependencies { pitest("org.pitest:pitest-junit5-plugin:1.2.1") }
//   pitest {
//       pitestVersion.set("1.30.0")
//       testPlugin.set("junit5")
//       jvmArgs.set(listOf("-XX:+EnableDynamicAgentLoading"))
//       mutationThreshold.set(85)
//       coverageThreshold.set(85)
//       excludedClasses.set(setOf("*.mixin.*", "*Mixin*"))
//       outputFormats.set(setOf("XML", "HTML"))
//       threads.set(Runtime.getRuntime().availableProcessors())
//   }
