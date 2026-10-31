#!/usr/bin/env node
// =============================================================================
// lint-markdown-structure.mjs — Enforces Markdown Structural Integrity
// Bans raw HTML tags in .md files, enforces balanced fenced code blocks (```),
// and validates depth-matched fenced div colons (:::, ::::).
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import fs from "node:fs";
import path from "node:path";

const TARGET_DIRS = ["content", "courses", "src/content", "docs"];

function walk(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs.readdirSync(dirPath, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dirPath, entry.name);
    return entry.isDirectory() ? walk(full) : full.endsWith(".md") ? [full] : [];
  });
}

function validateMarkdownFile(filePath) {
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
  const errors = [];
  let inCodeBlock = false;
  const divStack = [];

  lines.forEach((line, idx) => {
    const lineNum = idx + 1;
    const trimmed = line.trim();
    if (trimmed.startsWith("```")) {
      inCodeBlock = !inCodeBlock;
      return;
    }
    if (inCodeBlock) return;

    if (/<[a-zA-Z][^>]*>/.test(trimmed) && !trimmed.startsWith("<http")) {
      errors.push(`${filePath}:${lineNum} Raw HTML tags are forbidden in pure Markdown files.`);
    }

    const fenceMatch = /^(:{3,})(.*)$/.exec(trimmed);
    if (fenceMatch) {
      const colons = fenceMatch[1].length;
      const label = fenceMatch[2].trim();
      if (label.length > 0) {
        divStack.push({ colons, lineNum });
      } else if (divStack.length === 0 || divStack[divStack.length - 1].colons !== colons) {
        errors.push(`${filePath}:${lineNum} Unbalanced fenced div closing '${fenceMatch[1]}'.`);
      } else {
        divStack.pop();
      }
    }
  });

  if (inCodeBlock) {
    errors.push(`${filePath}: Unclosed fenced code block (\`\`\`).`);
  }
  for (const unclosed of divStack) {
    errors.push(`${filePath}:${unclosed.lineNum} Unclosed fenced div (${":".repeat(unclosed.colons)}).`);
  }
  return errors;
}

const files = TARGET_DIRS.flatMap((d) => walk(d));
const allErrors = files.flatMap(validateMarkdownFile);
if (allErrors.length > 0) {
  console.error("[addon:content-md ERROR] Markdown structural violations:");
  for (const err of allErrors) console.error(`  - ${err}`);
  process.exit(1);
}
console.log(`[addon:content-md] Verified Markdown structural purity (${files.length} files).`);
