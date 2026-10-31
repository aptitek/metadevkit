// =============================================================================
// vitest.config.ts — Strict Unit Testing & 95% Per-File Coverage Gate (lang:ts)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: false,
    passWithNoTests: false,
    environment: "node",
    include: [
      "src/**/*.{test,spec}.{ts,tsx}",
      "simulations/**/*.{test,spec}.{ts,tsx}",
      "tests/unit/**/*.{test,spec}.{ts,tsx}",
    ],
    coverage: {
      provider: "v8",
      reporter: ["text", "json-summary", "html", "lcov"],
      include: ["src/**/*.{ts,tsx}", "simulations/**/*.{ts,tsx}"],
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
        "src/content.config.ts",
        "**/types.ts",
        "**/*.types.ts",
        "**/*.config.*",
      ],
    },
  },
});
