// =============================================================================
// .dependency-cruiser.cjs — Strict Architectural & Dependency Graph Fortress
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
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
          '(^|/)(?:vitest|astro|playwright|panda|eslint|commitlint|stryker|drizzle)[.]config[.](?:js|cjs|mjs|ts|cts|mts|json)$',
          '^src/(?:content[.]config[.]ts|tokens/.*[.]ts|.*[.]stories[.]tsx)$',
          '^simulations/(?:.*[.]stories[.]tsx)$',
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
        pathNot: ['^astro:', '[+]types/'],
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
        path: '^(src|simulations)',
        pathNot: '[.](?:spec|test|stories)[.](?:js|mjs|cjs|jsx|ts|mts|cts|tsx)$',
      },
      to: {
        dependencyTypes: ['npm-dev'],
        dependencyTypesNot: ['type-only'],
        pathNot: ['node_modules/@types/'],
      },
    },
    {
      name: 'tokens-independence',
      severity: 'error',
      comment: 'Design tokens must not depend on UI, simulations, or i18n layers.',
      from: { path: '^src/tokens/' },
      to: { path: '^(?:src/(?!tokens/)|simulations/)' },
    },
    {
      name: 'i18n-independence',
      severity: 'error',
      comment: 'i18n layer must only depend on tokens or i18n.',
      from: { path: '^src/i18n/' },
      to: { path: '^(?:src/(?!tokens/|i18n/)|simulations/)' },
    },
    {
      name: 'atomic-atoms-hierarchy',
      severity: 'error',
      comment: 'Atoms must not import from molecules, organisms, templates, pages, or simulations.',
      from: { path: '^src/components/atoms/' },
      to: { path: '^(?:src/components/(?:molecules|organisms|templates|pages)/|simulations/)' },
    },
    {
      name: 'atomic-molecules-hierarchy',
      severity: 'error',
      comment: 'Molecules must not import from organisms, templates, pages, or simulations.',
      from: { path: '^src/components/molecules/' },
      to: { path: '^(?:src/components/(?:organisms|templates|pages)/|simulations/)' },
    },
    {
      name: 'atomic-organisms-hierarchy',
      severity: 'error',
      comment: 'Organisms must not import from templates or pages.',
      from: { path: '^src/components/organisms/' },
      to: { path: '^src/components/(?:templates|pages)/' },
    },
    {
      name: 'atomic-templates-hierarchy',
      severity: 'error',
      comment: 'Templates must not import from pages or i18n (pure spatial slots only).',
      from: { path: '^src/components/templates/' },
      to: { path: '^src/(?:components/pages/|i18n/)' },
    },
    {
      name: 'scripts-independence',
      severity: 'error',
      comment: 'Guardian scripts and ESLint plugins must not import runtime application code from src/, simulations/, or tests/.',
      from: { path: '^scripts/' },
      to: { path: '^(?:src/(?!types/)|simulations/|tests/)' },
    },
  ],
  options: {
    doNotFollow: { path: ['node_modules', 'styled-system'] },
    exclude: { path: ['styled-system', '.astro', 'dist', 'build', 'coverage', '.guardrails'] },
    tsPreCompilationDeps: true,
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default', 'types'],
      mainFields: ['module', 'main', 'types', 'typings'],
    },
  },
};
