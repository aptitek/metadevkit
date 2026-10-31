#!/usr/bin/env node
// =============================================================================
// .guardrails/scripts/lint-deprecated-deps.mjs — Dependency Hygiene Gate
// Forbids deprecated direct/transitive dependencies and unpinned ("latest"/"*")
// version specifiers across package.json and pnpm-lock.yaml.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

export function findDeprecatedInLockfile(lockfileContent) {
  const lines = lockfileContent.split("\n");
  const deprecatedPackages = [];
  let currentPackage = "";

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i] ?? "";
    const pkgMatch = line.match(/^\s{2}'?([^':]+@[0-9][^':]*)'?:\s*$/);
    if (pkgMatch?.[1]) {
      currentPackage = pkgMatch[1];
      continue;
    }
    const depMatch = line.match(/^\s{4}deprecated:\s*(.+)$/);
    if (depMatch?.[1]) {
      deprecatedPackages.push({
        pkg: currentPackage || `line ${i + 1}`,
        reason: depMatch[1].replace(/^['"]|['"]$/g, ""),
        line: i + 1,
      });
    }
  }
  return deprecatedPackages;
}

export function checkUnpinnedInManifest(pkgJson) {
  const unpinned = [];
  for (const section of ["dependencies", "devDependencies"]) {
    for (const [dep, spec] of Object.entries(pkgJson[section] ?? {})) {
      const value = String(spec).trim();
      if (value === "latest" || value === "*" || value === "next") {
        unpinned.push({ pkg: dep, specifier: value, section });
      }
    }
  }
  return unpinned;
}

export function checkDirectDependencies(rootDir = process.cwd()) {
  const pkgPath = resolve(rootDir, "package.json");
  if (!existsSync(pkgPath)) return [];
  const pkgJson = JSON.parse(readFileSync(pkgPath, "utf8"));
  const allDeps = [
    ...Object.keys(pkgJson.dependencies ?? {}),
    ...Object.keys(pkgJson.devDependencies ?? {}),
  ];
  const deprecatedDirect = [];
  for (const dep of allDeps) {
    const depPkgPath = resolve(rootDir, "node_modules", dep, "package.json");
    if (!existsSync(depPkgPath)) continue;
    const depPkg = JSON.parse(readFileSync(depPkgPath, "utf8"));
    if (depPkg.deprecated) {
      deprecatedDirect.push({
        pkg: `${dep}@${depPkg.version ?? "unknown"}`,
        reason: String(depPkg.deprecated),
      });
    }
  }
  return deprecatedDirect;
}

const rootDir = process.cwd();
const pkgPath = resolve(rootDir, "package.json");

if (!existsSync(pkgPath)) {
  console.log("✅ [Deps Hygiene] No package.json present (skipped).");
  process.exit(0);
}

const pkgJson = JSON.parse(readFileSync(pkgPath, "utf8"));
const lockPath = resolve(rootDir, "pnpm-lock.yaml");
const lockContent = existsSync(lockPath) ? readFileSync(lockPath, "utf8") : "";

const unpinned = checkUnpinnedInManifest(pkgJson);
const directDep = checkDirectDependencies(rootDir);
const lockDep = findDeprecatedInLockfile(lockContent);
const total = unpinned.length + directDep.length + lockDep.length;

if (total > 0) {
  for (const item of unpinned) {
    console.error(
      `❌ [Unpinned Dependency] ${item.pkg} (${item.section}) uses forbidden specifier "${item.specifier}". Pin an explicit semver range.`
    );
  }
  for (const item of directDep) {
    console.error(`❌ [Deprecated Direct Dependency] ${item.pkg}: ${item.reason}`);
  }
  for (const item of lockDep) {
    console.error(
      `❌ [Deprecated Lockfile Package] ${item.pkg} (pnpm-lock.yaml:${item.line}): ${item.reason}`
    );
  }
  process.exit(1);
}

console.log("✅ [Deps Hygiene] Zero deprecated or unpinned dependencies verified.");
