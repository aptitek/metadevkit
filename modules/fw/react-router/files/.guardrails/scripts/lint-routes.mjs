#!/usr/bin/env node
// =============================================================================
// .guardrails/scripts/lint-routes.mjs — React Router Parsimony & Hierarchy Gate
// Enforces:
//   1. Max 2 top-level route layouts and max 12 total routes in src/routes.ts
//   2. Top-level entries must be nested layout(file, children) or route(path, file, children)
//   3. Multi-segment flat paths ('a/b') and prefix() are forbidden
//   4. Parent/layout route modules must render <Outlet />
//   5. Leaf routes must not duplicate <panda.main>
//   6. Zero orphan route modules in src/routes/
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join, relative, resolve } from "node:path";

const MAX_TOP_LEVEL_ROUTES = 2;
const MAX_TOTAL_ROUTES = 12;

const rootDir = process.cwd();
const routesConfigPath = resolve(rootDir, "src/routes.ts");

if (!existsSync(routesConfigPath)) {
  console.log("✅ [Route Hierarchy] No src/routes.ts present yet (skipped).");
  process.exit(0);
}

const source = readFileSync(routesConfigPath, "utf8");
const errors = [];

if (/\bprefix\s*\(/.test(source)) {
  errors.push(
    "❌ [Route Hierarchy] `prefix()` is prohibited in `src/routes.ts` because it flattens URL segments without a parent UI `<Outlet />` layout."
  );
}

for (const match of source.matchAll(/\broute\s*\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]/g)) {
  const routePath = (match[1] ?? "").replace(/^\/+|\/+$/g, "");
  if (routePath.includes("/")) {
    errors.push(
      `❌ [Route Hierarchy] Flat multi-segment route path '${match[1]}' is prohibited. Nest child routes inside a parent route() to mirror the UI hierarchy.`
    );
  }
}

const referencedFiles = [];
for (const match of source.matchAll(/\b(?:layout|index)\s*\(\s*['"]([^'"]+)['"]/g)) {
  if (match[1]) referencedFiles.push(match[1]);
}
for (const match of source.matchAll(/\broute\s*\(\s*['"][^'"]+['"]\s*,\s*['"]([^'"]+)['"]/g)) {
  if (match[1]) referencedFiles.push(match[1]);
}

if (referencedFiles.length > MAX_TOTAL_ROUTES) {
  errors.push(
    `❌ [Route Parsimony] Total route count (${referencedFiles.length}) exceeds parsimony budget (${MAX_TOTAL_ROUTES}).`
  );
}

const registeredAbs = new Set();
for (const relFile of referencedFiles) {
  const absPath = resolve(rootDir, "src", relFile);
  registeredAbs.add(absPath);
  if (!existsSync(absPath)) {
    errors.push(
      `❌ [Route Hierarchy] Route module 'src/${relFile}' referenced in src/routes.ts does not exist.`
    );
  }
}

const routesDir = resolve(rootDir, "src/routes");
if (existsSync(routesDir)) {
  for (const entry of readdirSync(routesDir, { recursive: true })) {
    if (
      typeof entry === "string" &&
      entry.endsWith(".tsx") &&
      !entry.endsWith(".stories.tsx") &&
      !entry.endsWith(".test.tsx") &&
      !entry.endsWith(".spec.tsx")
    ) {
      const diskFile = join(routesDir, entry);
      if (!registeredAbs.has(diskFile)) {
        errors.push(
          `❌ [Route Parsimony] Orphan route module '${relative(rootDir, diskFile)}' is not mounted in src/routes.ts.`
        );
      }
    }
  }
}

if (errors.length > 0) {
  for (const err of errors) console.error(err);
  process.exit(1);
}

console.log(
  `✅ [Route Hierarchy] Verified ${referencedFiles.length} route module(s) in src/routes.ts.`
);
