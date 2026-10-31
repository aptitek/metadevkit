#!/usr/bin/env node
// =============================================================================
// lint-storybook-coverage.mjs — Enforces 100% CSF3 .stories.tsx Coverage
// Every React component (.tsx) in src/components/ and simulations/ must have a
// colocated .stories.tsx companion using CSF3 object notation.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import path from "node:path";

const COMPONENT_DIRS = ["src/components", "simulations"];
const EXEMPT_FILES = new Set(["index.tsx", "error-boundary.tsx", "main.tsx", "root.tsx"]);

function walk(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs.readdirSync(dirPath, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dirPath, entry.name);
    return entry.isDirectory() ? walk(full) : [full];
  });
}

function isComponentFile(filePath) {
  const base = path.basename(filePath);
  if (EXEMPT_FILES.has(base)) return false;
  if (
    base.endsWith(".stories.tsx") ||
    base.endsWith(".test.tsx") ||
    base.endsWith(".spec.tsx")
  ) {
    return false;
  }
  return base.endsWith(".tsx");
}

const components = COMPONENT_DIRS.flatMap((d) => walk(d)).filter(isComponentFile);
const errors = [];

for (const comp of components) {
  const storyPath = comp.replace(/\.tsx$/, ".stories.tsx");
  if (!fs.existsSync(storyPath)) {
    errors.push(`Missing CSF3 story companion: ${storyPath} (for ${comp})`);
    continue;
  }
  const content = fs.readFileSync(storyPath, "utf8");
  if (!content.includes("export default")) {
    errors.push(`${storyPath}: Missing CSF3 default Meta export`);
  }
  if (content.includes("storiesOf(") || content.includes(".bind(")) {
    errors.push(`${storyPath}: Forbidden legacy CSF1/CSF2 syntax detected`);
  }
}

if (errors.length > 0) {
  console.error("[addon:storybook ERROR] Storybook CSF3 coverage check failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}
console.log(`[addon:storybook] Verified 100% CSF3 Storybook coverage (${components.length} components).`);
