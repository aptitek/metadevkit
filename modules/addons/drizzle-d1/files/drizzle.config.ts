// =============================================================================
// drizzle.config.ts — Drizzle Kit Configuration for Cloudflare D1 (SQLite)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
export default {
  schema: "./src/db/schema.ts",
  out: "./drizzle/migrations",
  dialect: "sqlite",
  strict: true,
  verbose: true,
};
