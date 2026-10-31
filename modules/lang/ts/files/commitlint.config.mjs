// =============================================================================
// commitlint.config.mjs — Strict Conventional Commits Configuration (lang:ts)
// Dynamically loads ARCHITECTURAL_SCOPES compiled from active modules in
// .guardrails/commit-scopes.json (union of module.json commit_scopes).
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const scopesFile = resolve(__dirname, ".guardrails/commit-scopes.json");

const DEFAULT_SCOPES = [
  "core",
  "ci",
  "lint",
  "test",
  "docs",
  "deps",
  "config",
  "security",
  "guardrails",
  "scripts",
];

export const ARCHITECTURAL_SCOPES = existsSync(scopesFile)
  ? JSON.parse(readFileSync(scopesFile, "utf8"))
  : DEFAULT_SCOPES;

export const ALLOWED_COMMIT_TYPES = [
  "feat",
  "fix",
  "docs",
  "style",
  "refactor",
  "perf",
  "test",
  "build",
  "ci",
  "chore",
  "revert",
];

export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [2, "always", ALLOWED_COMMIT_TYPES],
    "type-case": [2, "always", "lower-case"],
    "type-empty": [2, "never"],
    "scope-enum": [2, "always", ARCHITECTURAL_SCOPES],
    "scope-case": [2, "always", "lower-case"],
    "scope-empty": [2, "never"],
    "subject-empty": [2, "never"],
    "subject-min-length": [2, "always", 15],
    "subject-max-length": [2, "always", 100],
    "subject-full-stop": [2, "never", "."],
    "header-max-length": [2, "always", 100],
    "body-max-line-length": [2, "always", 120],
  },
};
