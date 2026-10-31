#!/usr/bin/env node
// =============================================================================
// lint-exports.mjs — Enforces Library Barrel & Package Exports Contract
// Validates explicit named re-exports in src/index.ts (zero wildcard export *),
// mandatory './index.css' import when src/index.css exists, and ESM exports map
// in package.json when building a shared component/token library.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";

if (!fs.existsSync("src/index.ts")) {
  process.exit(0);
}

const errors = [];
const indexContent = fs.readFileSync("src/index.ts", "utf8");

if (/export\s+\*\s+from/.test(indexContent)) {
  errors.push("src/index.ts: Wildcard 'export * from' is forbidden. Use explicit named exports.");
}

if (fs.existsSync("src/index.css") && !indexContent.includes("./index.css")) {
  errors.push("src/index.ts: Must import './index.css' at the top of the barrel file.");
}

if (fs.existsSync("package.json")) {
  const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
  if (pkg.exports && typeof pkg.exports === "object" && !pkg.exports["."]) {
    errors.push("package.json: 'exports' map must define a root '.' entry.");
  }
}

if (errors.length > 0) {
  console.error("[addon:lib-exports ERROR] Library barrel export violations:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}
console.log("[addon:lib-exports] Verified explicit barrel exports in src/index.ts.");
