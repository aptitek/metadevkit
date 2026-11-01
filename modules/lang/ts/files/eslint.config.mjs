// =============================================================================
// eslint.config.mjs — Purely Functional ESLint Flat Config Composer
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// Dynamically composes .guardrails/eslint/<module>.mjs in topological DAG order
// =============================================================================
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const manifestPath = resolve(__dirname, ".guardrails/manifest.json");
const eslintDir = resolve(__dirname, ".guardrails/eslint");

const manifest = existsSync(manifestPath)
  ? JSON.parse(readFileSync(manifestPath, "utf8"))
  : { modules: [] };
const activeModules = Array.isArray(manifest.modules) ? manifest.modules : [];

const baseIgnores = {
  ignores: [
    "**/node_modules/**",
    "**/dist/**",
    "**/build/**",
    "**/coverage/**",
    "**/.guardrails/**",
    "**/.wrangler/**",
  ],
};

const fragmentFiles = activeModules
  .map((modId) => `${String(modId).replace(/^[^:]+:/, "")}.mjs`)
  .filter((file) => existsSync(resolve(eslintDir, file)));

const loadedRules = await Promise.all(
  fragmentFiles.map(async (file) => {
    const imported = await import(pathToFileURL(resolve(eslintDir, file)).href);
    const rules = imported.default ?? imported.rules ?? [];
    return Array.isArray(rules) ? rules : [rules];
  }),
);

const seenNames = new Set();
const deduplicatedRules = loadedRules.flat().filter((cfg) => {
  if (!cfg?.name) return true;
  if (seenNames.has(cfg.name)) return false;
  seenNames.add(cfg.name);
  return true;
});

export default [baseIgnores, ...deduplicatedRules];
