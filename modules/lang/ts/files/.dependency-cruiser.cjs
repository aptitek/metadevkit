// =============================================================================
// .dependency-cruiser.cjs — Purely Functional Dependency Graph Fortress (lang:ts)
// Composes module overlays from .guardrails/depcruise/*.cjs without mutation
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
const fs = require('node:fs');
const path = require('node:path');

const overlayDir = path.resolve(__dirname, '.guardrails/depcruise');
const overlays = fs.existsSync(overlayDir)
  ? fs
      .readdirSync(overlayDir)
      .sort()
      .filter((file) => file.endsWith('.cjs'))
      .map((file) => require(path.join(overlayDir, file)))
  : [];

const baseForbidden = [
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
];

/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    ...baseForbidden,
    ...overlays.flatMap((overlay) => (Array.isArray(overlay.forbidden) ? overlay.forbidden : [])),
  ],
  options: {
    doNotFollow: {
      path: [
        'node_modules',
        ...overlays.flatMap((overlay) => (Array.isArray(overlay.doNotFollowPaths) ? overlay.doNotFollowPaths : [])),
      ],
    },
    exclude: {
      path: [
        'dist',
        'build',
        'coverage',
        '.guardrails',
        '.cache',
        ...overlays.flatMap((overlay) => (Array.isArray(overlay.excludePaths) ? overlay.excludePaths : [])),
      ],
    },
    tsPreCompilationDeps: true,
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default', 'types'],
      mainFields: ['module', 'main', 'types', 'typings'],
    },
  },
};
