// =============================================================================
// .guardrails/depcruise/design-system.cjs — Design Tokens & Panda CSS Boundaries
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
module.exports = {
  forbidden: [
    {
      name: 'tokens-independence',
      severity: 'error',
      comment: 'Design tokens must not depend on UI, simulations, or i18n layers.',
      from: { path: '^src/tokens/' },
      to: { path: '^(?:src/(?!tokens/)|simulations/)' },
    },
  ],
  doNotFollowPaths: ['styled-system'],
  excludePaths: ['styled-system'],
};
