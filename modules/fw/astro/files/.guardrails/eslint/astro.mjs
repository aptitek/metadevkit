// =============================================================================
// .guardrails/eslint/astro.mjs — Astro Island Architecture & Accessibility Rules
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
export default [
  {
    name: "guardrails/fw:astro",
    files: ["**/*.astro"],
    rules: {
      "astro/no-conflict-set-directives": "error",
      "astro/no-unused-define-vars-in-style": "error",
      "astro/no-deprecated-astro-canonicalurl": "error",
      "astro/no-deprecated-astro-fetchcontent": "error",
      "astro/no-deprecated-astro-resolve": "error",
      "astro/valid-compile": "error",
      "jsx-a11y/alt-text": "error",
      "jsx-a11y/anchor-is-valid": "error"
    }
  }
];
