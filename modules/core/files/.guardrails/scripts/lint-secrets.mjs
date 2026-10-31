#!/usr/bin/env node
// =============================================================================
// .guardrails/scripts/lint-secrets.mjs — Secret Scanner Quality Gate
// Prevents hardcoded API keys, credentials, private keys, and tokens.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";

const IGNORED_PATH_SEGMENTS = [
  "node_modules/",
  ".git/",
  "dist/",
  "build/",
  "styled-system/",
  "storybook-static/",
  ".astro/",
  ".react-router/",
  ".agents/",
  ".guardrails/",
  "coverage/",
  "test-results/",
  "playwright-report/",
  ".wireit/",
  ".wrangler/",
  "pnpm-lock.yaml",
  ".guardrails.lock",
  "worker-configuration.d.ts",
];

const SCANNED_EXTENSIONS =
  /\.(ts|tsx|js|jsx|mjs|cjs|json|jsonc|yml|yaml|toml|md|mdx|sql|css|env|sh)$/;

export const SECRET_RULES = [
  {
    id: "private-key",
    description: "Cryptographic Private Key block",
    pattern: /-----BEGIN (?:RSA |DSA |EC |OPENSSH |PGP )?PRIVATE KEY-----/,
  },
  {
    id: "aws-access-key-id",
    description: "AWS Access Key ID",
    pattern: /\b(?:AKIA|ASIA)[0-9A-Z]{16}\b/,
  },
  {
    id: "github-token",
    description: "GitHub Personal/App Access Token",
    pattern:
      /\b(?:(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,255}|github_pat_[A-Za-z0-9_]{22,255})\b/,
  },
  {
    id: "gitlab-token",
    description: "GitLab Personal Access Token",
    pattern: /\bglpat-[A-Za-z0-9\-_]{20,}\b/,
  },
  {
    id: "slack-token",
    description: "Slack API Token or Webhook",
    pattern:
      /(?:\bxox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*\b|https:\/\/hooks\.slack\.com\/services\/T[A-Z0-9]+\/B[A-Z0-9]+\/[A-Za-z0-9]+)/,
  },
  {
    id: "stripe-live-key",
    description: "Stripe Live Secret/Restricted Key",
    pattern: /\b(?:sk|rk)_live_[0-9a-zA-Z]{24,}\b/,
  },
  {
    id: "google-api-key",
    description: "Google Cloud / Firebase API Key",
    pattern: /\bAIza[0-9A-Za-z\-_]{35}\b/,
  },
  {
    id: "npm-access-token",
    description: "NPM Automation/Publish Access Token",
    pattern: /\bnpm_[A-Za-z0-9]{36}\b/,
  },
  {
    id: "sonarqube-token",
    description: "SonarQube Token",
    pattern: /\bsqp_[a-zA-Z0-9]{40}\b/,
  },
  {
    id: "database-credentials-uri",
    description: "Database Connection URI with embedded credentials",
    pattern:
      /\b(?:postgres|postgresql|mysql|mongodb(?:\+srv)?|redis):\/\/[^/\s:@]+:[^/\s@]+@[^/\s]+/,
  },
];

function shouldIgnoreFile(filePath) {
  const normalized = filePath.replace(/\\/g, "/");
  if (IGNORED_PATH_SEGMENTS.some((seg) => normalized.includes(seg))) {
    return true;
  }
  const base = normalized.split("/").pop() ?? "";
  if (base.startsWith(".env")) {
    return base === ".env.example" || base === ".env.template";
  }
  return !SCANNED_EXTENSIONS.test(normalized);
}

export function scanContentForSecrets(content, filePath = "inline") {
  const findings = [];
  const lines = content.split(/\r?\n/);
  for (let idx = 0; idx < lines.length; idx++) {
    const line = lines[idx];
    if (!line || line.includes("secret-scanner-ignore")) continue;
    for (const rule of SECRET_RULES) {
      if (rule.pattern.test(line)) {
        findings.push({
          file: filePath,
          line: idx + 1,
          ruleId: rule.id,
          description: rule.description,
        });
      }
    }
  }
  return findings;
}

function collectFilesRecursively(rootDir, currentDir, collected = []) {
  if (!existsSync(currentDir)) return collected;
  for (const entry of readdirSync(currentDir, { withFileTypes: true })) {
    const fullPath = join(currentDir, entry.name);
    const relPath = relative(rootDir, fullPath);
    if (IGNORED_PATH_SEGMENTS.some((seg) => `${relPath}/`.startsWith(seg) || relPath.includes(`/${seg}`))) {
      continue;
    }
    if (entry.isDirectory()) {
      collectFilesRecursively(rootDir, fullPath, collected);
    } else if (entry.isFile() && !shouldIgnoreFile(relPath)) {
      collected.push(fullPath);
    }
  }
  return collected;
}

const rootDir = process.cwd();
const files = collectFilesRecursively(rootDir, rootDir);
const findings = [];

for (const file of files) {
  const relPath = relative(rootDir, file);
  const content = readFileSync(file, "utf8");
  findings.push(...scanContentForSecrets(content, relPath));
}

if (findings.length > 0) {
  for (const f of findings) {
    console.error(
      `❌ [Secret Scanner] ${f.file}:${f.line} — Detected ${f.description} (${f.ruleId})`
    );
  }
  process.exit(1);
}
console.log(`✅ [Secret Scanner] Verified ${files.length} file(s), zero secrets exposed.`);
