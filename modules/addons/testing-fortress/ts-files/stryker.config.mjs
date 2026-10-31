// =============================================================================
// stryker.config.mjs — StrykerJS Mutation Testing Configuration
// Outputs unified mutation-testing-elements JSON schema (reports/mutation/mutation.json)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";

const pathsFile = new URL("./.guardrails/paths.json", import.meta.url);
const extraPaths = fs.existsSync(pathsFile)
  ? JSON.parse(fs.readFileSync(pathsFile, "utf-8"))
  : {};

export default {
  packageManager: "pnpm",
  reporters: ["clear-text", "progress", "html", "json"],
  jsonReporter: {
    fileName: "reports/mutation/mutation.json",
  },
  testRunner: "vitest",
  coverageAnalysis: "perTest",
  incremental: true,
  incrementalFile: "node_modules/.cache/stryker-incremental.json",
  mutate: [
    "src/**/*.ts",
    "src/**/*.tsx",
    ...(extraPaths.mutate ?? []),
    "!**/*.test.ts",
    "!**/*.test.tsx",
    "!**/*.spec.ts",
    "!**/*.spec.tsx",
    "!**/*.stories.tsx",
    "!**/types.ts",
    "!**/index.ts",
    "!src/main.tsx",
    "!src/tokens/**",
    "!src/i18n/**",
  ],
  thresholds: {
    high: 95,
    low: 90,
    break: 95,
  },
};
