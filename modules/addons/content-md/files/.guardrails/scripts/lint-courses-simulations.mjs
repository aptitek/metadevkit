#!/usr/bin/env node
// =============================================================================
// lint-courses-simulations.mjs — Validates Course Frontmatter & Simulations
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import path from "node:path";

const COURSES_DIR = "courses";
if (!fs.existsSync(COURSES_DIR)) {
  process.exit(0);
}

const REQUIRED_FRONTMATTER_KEYS = ["title", "description", "slug"];
const errors = [];

function walkCourses(dirPath) {
  return fs.readdirSync(dirPath, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dirPath, entry.name);
    return entry.isDirectory()
      ? walkCourses(full)
      : full.endsWith(".md") || full.endsWith(".mdx")
        ? [full]
        : [];
  });
}

for (const file of walkCourses(COURSES_DIR)) {
  const content = fs.readFileSync(file, "utf8");
  if (!content.startsWith("---")) {
    errors.push(`${file}: Missing YAML frontmatter block (---).`);
    continue;
  }
  const endIdx = content.indexOf("---", 3);
  if (endIdx === -1) {
    errors.push(`${file}: Unclosed YAML frontmatter block.`);
    continue;
  }
  const frontmatter = content.slice(3, endIdx);
  for (const key of REQUIRED_FRONTMATTER_KEYS) {
    if (!new RegExp(`^${key}:`, "m").test(frontmatter)) {
      errors.push(`${file}: Missing required frontmatter field '${key}'.`);
    }
  }
}

if (errors.length > 0) {
  console.error("[addon:content-md ERROR] Course validation failed:");
  for (const err of errors) console.error(`  - ${err}`);
  process.exit(1);
}
