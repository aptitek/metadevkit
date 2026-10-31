// =============================================================================
// panda.config.ts — Strict Material Design 3 & Panda CSS Configuration
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import { defineConfig } from "@pandacss/dev";

export default defineConfig({
  presets: ["@pandacss/preset-base"],
  preflight: true,
  strictTokens: true,
  include: ["./src/**/*.{js,jsx,ts,tsx,astro}", "./simulations/**/*.{ts,tsx}"],
  exclude: [],
  outdir: "styled-system",
  jsxFramework: "react",
  jsxFactory: "panda",
});
