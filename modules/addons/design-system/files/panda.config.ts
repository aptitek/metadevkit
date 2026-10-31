// =============================================================================
// panda.config.ts — Strict Material Design 3 & Panda CSS Configuration
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import { defineConfig } from "@pandacss/dev";

const jsxOverlayFile = new URL("./.guardrails/panda-jsx.json", import.meta.url);
const jsxOverlay = fs.existsSync(jsxOverlayFile)
  ? JSON.parse(fs.readFileSync(jsxOverlayFile, "utf-8"))
  : {};

export default defineConfig({
  presets: ["@pandacss/preset-base"],
  preflight: true,
  strictTokens: true,
  include: ["./src/**/*.{js,jsx,ts,tsx,astro}"],
  exclude: [],
  outdir: "styled-system",
  ...jsxOverlay,
});
