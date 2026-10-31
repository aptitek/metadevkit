// =============================================================================
// vitest.config.ts — Strict Unit Testing & 95% Per-File Coverage Gate (lang:ts)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import { defineConfig } from "vitest/config";

const contentPathsFile = new URL("./.guardrails/content-md/paths.json", import.meta.url);
const contentPaths = fs.existsSync(contentPathsFile)
  ? JSON.parse(fs.readFileSync(contentPathsFile, "utf-8"))
  : {};

export default defineConfig({
  test: {
    globals: false,
    passWithNoTests: false,
    environment: "node",
    include: [
      "src/**/*.{test,spec}.{ts,tsx}",
      "tests/unit/**/*.{test,spec}.{ts,tsx}",
      ...(contentPaths.testInclude ?? []),
    ],
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary", "html", "lcov"],
      include: ["src/**/*.{ts,tsx}", ...(contentPaths.coverageInclude ?? [])],
      thresholds: {
        lines: 95,
        branches: 90,
        functions: 95,
        statements: 95,
        perFile: true,
      },
      exclude: [
        "node_modules/**",
        "dist/**",
        "build/**",
        ".guardrails/**",
        "**/*.d.ts",
        "**/*.stories.{ts,tsx}",
        "src/types/**",
        "**/types.ts",
        "**/*.types.ts",
        "**/*.config.*",
        ...(contentPaths.coverageExclude ?? []),
      ],
    },
  },
});
