// =============================================================================
// panda.config.ts — Strict Material Design 3 & Panda CSS Configuration
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import { defineConfig } from "@pandacss/dev";

const manifestPath = new URL("./.guardrails/manifest.json", import.meta.url);
const activeModules: string[] = fs.existsSync(manifestPath)
  ? (JSON.parse(fs.readFileSync(manifestPath, "utf-8")).modules ?? [])
  : [];
const hasReact = activeModules.includes("fw:react");

export default defineConfig({
  presets: ["@pandacss/preset-base"],
  preflight: true,
  strictTokens: true,
  include: ["./src/**/*.{js,jsx,ts,tsx,astro}"],
  exclude: [],
  outdir: "styled-system",
  ...(hasReact ? { jsxFramework: "react", jsxFactory: "panda" } : {}),
});
