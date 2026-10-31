// =============================================================================
// eslint.config.mjs — Dynamic ESLint Flat Config Composer
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// Dynamically loads and composes .guardrails/eslint/*.mjs based on manifest.json
// =============================================================================
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const manifestPath = resolve(__dirname, ".guardrails/manifest.json");

const MODULE_TO_ESLINT_CONFIG = {
  "lang:ts": ".guardrails/eslint/ts.mjs",
  "fw:react": ".guardrails/eslint/react.mjs",
  "fw:react-router": ".guardrails/eslint/react-router.mjs",
  "fw:astro": ".guardrails/eslint/astro.mjs",
  "addon:design-system": ".guardrails/eslint/design-system.mjs",
  "addon:testing-fortress": ".guardrails/eslint/testing-fortress.mjs",
  "addon:storybook": ".guardrails/eslint/storybook.mjs",
};

const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const activeModules = Array.isArray(manifest.modules) ? manifest.modules : [];

const composedConfig = [
  {
    ignores: [
      "**/node_modules/**",
      "**/dist/**",
      "**/build/**",
      "**/coverage/**",
      "**/.guardrails/**",
      "**/.wrangler/**",
    ],
  },
];

for (const modId of activeModules) {
  const relConfigPath = MODULE_TO_ESLINT_CONFIG[modId];
  if (!relConfigPath) continue;

  const absConfigPath = resolve(__dirname, relConfigPath);
  if (existsSync(absConfigPath)) {
    const imported = await import(pathToFileURL(absConfigPath).href);
    const rulesArray = imported.default ?? imported.rules ?? [];
    composedConfig.push(...(Array.isArray(rulesArray) ? rulesArray : [rulesArray]));
  }
}

export default composedConfig;
