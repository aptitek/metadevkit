// =============================================================================
// stryker.config.mjs — StrykerJS Mutation Testing Configuration
// Outputs unified mutation-testing-elements JSON schema (reports/mutation/mutation.json)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";

const contentPathsFile = new URL("./.guardrails/content-md/paths.json", import.meta.url);
const contentPaths = fs.existsSync(contentPathsFile)
  ? JSON.parse(fs.readFileSync(contentPathsFile, "utf-8"))
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
    ...(contentPaths.mutate ?? []),
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
