#!/usr/bin/env node
// =============================================================================
// verify-tdd-staged.mjs — Enforces TDD Companion Presence on Staged Files
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import path from "node:path";

const stagedFiles = process.argv.slice(2);
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

const violations = [];
for (const file of stagedFiles) {
  if (!file.startsWith("src/") && !file.startsWith("simulations/") && !file.startsWith("scripts/")) {
    continue;
  }
  const base = path.basename(file);
  if (
    EXEMPT_BASENAMES.has(base) ||
    base.endsWith(".d.ts") ||
    base.includes(".test.") ||
    base.includes(".spec.") ||
    base.includes(".stories.")
  ) {
    continue;
  }
  if (!base.endsWith(".ts") && !base.endsWith(".tsx")) continue;
  const ext = path.extname(file);
  const stem = file.slice(0, -ext.length);
  if (!fs.existsSync(`${stem}.test.ts`) && !fs.existsSync(`${stem}.test.tsx`)) {
    violations.push(file);
  }
}

if (violations.length > 0) {
  console.error("[TDD Gate ERROR] Staged implementation files lack a .test.ts/.test.tsx companion:");
  for (const v of violations) console.error(`  - ${v}`);
  process.exit(1);
}
