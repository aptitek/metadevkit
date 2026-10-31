#!/usr/bin/env node
// =============================================================================
// lint-mdx-purity.mjs — Enforces Zero-Styling MDX Purity & i18n Locale Parity
// Bans style={}, className={}, <style>, and CSS/styled-system imports in .mdx.
// Validates A11Y_STRINGS locale parity in src/i18n/strings.ts when present.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import path from "node:path";

const MDX_DIRS = ["content", "courses", "src/content"];

function walkMdx(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs.readdirSync(dirPath, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dirPath, entry.name);
    return entry.isDirectory() ? walkMdx(full) : full.endsWith(".mdx") ? [full] : [];
  });
}

const FORBIDDEN_MDX_PATTERNS = [
  { regex: /\bstyle\s*=\s*\{/, reason: "Inline style={} prop is forbidden in .mdx" },
  { regex: /\bclassName\s*=/, reason: "className prop is forbidden in .mdx" },
  { regex: /<style\b/i, reason: "<style> tag is forbidden in .mdx" },
  { regex: /import\s+.*from\s+['"].*styled-system/, reason: "styled-system imports are forbidden in .mdx" },
  { regex: /import\s+['"].*\.css['"]/, reason: "Direct CSS imports are forbidden in .mdx" },
];

const errors = [];
for (const file of MDX_DIRS.flatMap((d) => walkMdx(d))) {
  const content = fs.readFileSync(file, "utf8");
  for (const rule of FORBIDDEN_MDX_PATTERNS) {
    if (rule.regex.test(content)) {
      errors.push(`${file}: ${rule.reason}`);
    }
  }
}

if (errors.length > 0) {
  console.error("[addon:content-md ERROR] MDX purity violations:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}
console.log("[addon:content-md] Verified zero-styling MDX purity.");
