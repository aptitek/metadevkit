// =============================================================================
// .dependency-cruiser.cjs — Strict Architectural & Dependency Graph Fortress (lang:ts)
// Dynamically merges module-specific overlays from .guardrails/depcruise/*.cjs
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
const fs = require('node:fs');
const path = require('node:path');

/** @type {import('dependency-cruiser').IConfiguration} */
const baseConfig = {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      comment: 'Circular dependencies are forbidden.',
      from: {},
      to: { circular: true },
    },
    {
      name: 'no-orphans',
      severity: 'error',
      comment: 'Orphan modules are forbidden.',
      from: {
        orphan: true,
        pathNot: [
          '(^|/)[.][^/]+[.](?:js|cjs|mjs|ts|cts|mts|json)$',
          '[.]d[.]ts$',
          '(^|/)tsconfig.*[.]json$',
          '(^|/)(?:vitest|playwright|eslint|commitlint|stryker|drizzle)[.]config[.](?:js|cjs|mjs|ts|cts|mts|json)$',
          '^tests/',
          '^scripts/',
          '^[.]guardrails/',
        ],
      },
      to: {},
    },
    {
      name: 'no-deprecated-core',
      severity: 'error',
      from: {},
      to: {
        dependencyTypes: ['core'],
        path: [
          '^v8/tools/',
          '^node-inspect/',
          '^async_hooks$',
          '^punycode$',
          '^domain$',
          '^constants$',
          '^sys$',
          '^_linklist$',
          '^_stream_wrap$',
        ],
      },
    },
    {
      name: 'not-to-deprecated',
      severity: 'error',
      from: {},
      to: { dependencyTypes: ['deprecated'] },
    },
    {
      name: 'no-non-package-json',
      severity: 'error',
      from: {},
      to: { dependencyTypes: ['npm-no-pkg', 'npm-unknown'] },
    },
    {
      name: 'not-to-unresolvable',
      severity: 'error',
      from: {},
      to: {
        couldNotResolve: true,
        pathNot: ['[+]types/'],
      },
    },
    {
      name: 'no-duplicate-dep-types',
      severity: 'error',
      from: {},
      to: {
        moreThanOneDependencyType: true,
        dependencyTypesNot: ['type-only'],
      },
    },
    {
      name: 'not-to-spec',
      severity: 'error',
      from: {},
      to: {
        path: '[.](?:spec|test)[.](?:js|mjs|cjs|jsx|ts|mts|cts|tsx)$',
      },
    },
    {
      name: 'not-to-dev-dep',
      severity: 'error',
      from: {
        path: '^src',
        pathNot: '[.](?:spec|test)[.](?:js|mjs|cjs|jsx|ts|mts|cts|tsx)$',
      },
      to: {
        dependencyTypes: ['npm-dev'],
        dependencyTypesNot: ['type-only'],
        pathNot: ['node_modules/@types/'],
      },
    },
    {
      name: 'scripts-independence',
      severity: 'error',
      comment: 'Guardian scripts must not import runtime application code from src/ or tests/.',
      from: { path: '^scripts/' },
      to: { path: '^(?:src/(?!types/)|tests/)' },
    },
  ],
  options: {
    doNotFollow: { path: ['node_modules'] },
    exclude: { path: ['dist', 'build', 'coverage', '.guardrails', '.cache'] },
    tsPreCompilationDeps: true,
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default', 'types'],
      mainFields: ['module', 'main', 'types', 'typings'],
    },
  },
};

const overlayDir = path.resolve(__dirname, '.guardrails/depcruise');
if (fs.existsSync(overlayDir)) {
  for (const file of fs.readdirSync(overlayDir).sort()) {
    if (!file.endsWith('.cjs')) continue;
    const overlay = require(path.join(overlayDir, file));
    if (Array.isArray(overlay.forbidden)) {
      baseConfig.forbidden.push(...overlay.forbidden);
    }
    if (Array.isArray(overlay.doNotFollowPaths)) {
      baseConfig.options.doNotFollow.path.push(...overlay.doNotFollowPaths);
    }
    if (Array.isArray(overlay.excludePaths)) {
      baseConfig.options.exclude.path.push(...overlay.excludePaths);
    }
  }
}

module.exports = baseConfig;
