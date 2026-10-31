#!/usr/bin/env node
// =============================================================================
// .guardrails/scripts/lint-error-boundaries.mjs — Strategic Error Boundary Gate
// Verifies that src/components/error-boundary.tsx (when present) exports
// ErrorBoundaryView, StrategicSectionBoundary, resolveErrorInfo, renders
// role="alert" and data-error-boundary, and never leaks unguarded error.stack.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const rootDir = process.cwd();
const boundaryPath = resolve(rootDir, "src/components/error-boundary.tsx");

if (!existsSync(boundaryPath)) {
  console.log("✅ [Error Boundaries] No src/components/error-boundary.tsx present (skipped).");
  process.exit(0);
}

const content = readFileSync(boundaryPath, "utf8");
const errors = [];

for (const fn of ["ErrorBoundaryView", "StrategicSectionBoundary", "resolveErrorInfo"]) {
  const exportRegex = new RegExp(`export\\s+(?:function|const)\\s+${fn}\\b`);
  if (!exportRegex.test(content)) {
    errors.push(`❌ [Error Boundaries] 'src/components/error-boundary.tsx' must export '${fn}'.`);
  }
}

if (!content.includes("data-error-boundary") || !content.includes('role="alert"')) {
  errors.push(
    "❌ [Error Boundaries] 'src/components/error-boundary.tsx' must render `role=\"alert\"` and `data-error-boundary` attributes."
  );
}

if (content.includes("error.stack") && !content.includes("import.meta.env.DEV") && !content.includes("isDev")) {
  errors.push(
    "❌ [Error Boundaries] 'src/components/error-boundary.tsx' must never render `error.stack` in production without guarding behind `import.meta.env.DEV`."
  );
}

const astroLayoutPath = resolve(rootDir, "src/layouts/CourseLayout.astro");
if (existsSync(astroLayoutPath)) {
  const layoutContent = readFileSync(astroLayoutPath, "utf8");
  if (!layoutContent.includes('data-boundary-scope="root"')) {
    errors.push(
      "❌ [Error Boundaries] 'src/layouts/CourseLayout.astro' must define `data-boundary-scope=\"root\"`."
    );
  }
}

const hydratorPath = resolve(rootDir, "src/components/organisms/simulation-hydrator.tsx");
if (existsSync(hydratorPath)) {
  const hydratorContent = readFileSync(hydratorPath, "utf8");
  if (!hydratorContent.includes('boundary="section:simulation"')) {
    errors.push(
      "❌ [Error Boundaries] 'src/components/organisms/simulation-hydrator.tsx' must specify `boundary=\"section:simulation\"`."
    );
  }
}

if (errors.length > 0) {
  for (const err of errors) console.error(err);
  process.exit(1);
}

console.log("✅ [Error Boundaries] Strategic error boundaries verified.");
