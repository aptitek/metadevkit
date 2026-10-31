#!/usr/bin/env node
// =============================================================================
// lint-tdd-companions.mjs — Enforces 1:1 Unit Test Companion Files
// Every implementation file in src/, simulations/, and scripts/ must have a
// colocated .test.ts or .test.tsx companion. Storybook .stories.tsx files do
// NOT substitute for unit tests.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import path from "node:path";

const TARGET_DIRS = ["src", "simulations", "scripts"];
const EXEMPT_BASENAMES = new Set([
  "index.ts",
  "index.tsx",
  "types.ts",
  "main.tsx",
  "vite-env.d.ts",
  "env.d.ts",
  "routes.ts",
  "root.tsx",
]);
const EXEMPT_DIRS = new Set(["tokens", "i18n", "types", "styled-system"]);

function walk(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  return entries.flatMap((entry) => {
    if (EXEMPT_DIRS.has(entry.name)) return [];
    const fullPath = path.join(dirPath, entry.name);
    return entry.isDirectory() ? walk(fullPath) : [fullPath];
  });
}

function isSourceModule(filePath) {
  const base = path.basename(filePath);
  if (EXEMPT_BASENAMES.has(base)) return false;
  if (base.endsWith(".d.ts")) return false;
  if (
    base.endsWith(".test.ts") ||
    base.endsWith(".test.tsx") ||
    base.endsWith(".spec.ts") ||
    base.endsWith(".spec.tsx") ||
    base.endsWith(".stories.ts") ||
    base.endsWith(".stories.tsx")
  ) {
    return false;
  }
  return base.endsWith(".ts") || base.endsWith(".tsx");
}

function hasTestCompanion(filePath) {
  const ext = path.extname(filePath);
  const stem = filePath.slice(0, -ext.length);
  return (
    fs.existsSync(`${stem}.test.ts`) ||
    fs.existsSync(`${stem}.test.tsx`) ||
    fs.existsSync(`${stem}.spec.ts`) ||
    fs.existsSync(`${stem}.spec.tsx`)
  );
}

const allSourceFiles = TARGET_DIRS.flatMap((d) => walk(d)).filter(isSourceModule);
const missing = allSourceFiles.filter((filePath) => !hasTestCompanion(filePath));

if (missing.length > 0) {
  console.error("[addon:testing-fortress ERROR] Missing 1:1 TDD unit test companion (.test.ts / .test.tsx):");
  for (const m of missing) {
    console.error(`  - ${m}`);
  }
  process.exit(1);
}
console.log(`[addon:testing-fortress] Verified 1:1 TDD unit test companions (${allSourceFiles.length} modules).`);
