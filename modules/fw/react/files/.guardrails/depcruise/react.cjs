// =============================================================================
// .guardrails/depcruise/react.cjs — React Atomic Design & i18n Layer Boundaries (fw:react)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
module.exports = {
  forbidden: [
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
  ],
};
