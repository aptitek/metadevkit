// =============================================================================
// .guardrails/eslint/react-router.mjs — React Router v7/v8 Route & Loader Rules
// Inherits lang:ts > fw:react
// Enforces route parsimony, forbids direct imports of atoms/molecules in routes,
// and enforces server/client boundary isolation.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
export default [
  {
    name: "guardrails/fw:react-router",
    files: ["**/routes/**/*.{ts,tsx}", "**/app/routes.{ts,tsx}", "src/routes.ts"],
    rules: {
      "no-restricted-globals": [
        "error",
        {
          name: "localStorage",
          message:
            "Do not access browser localStorage directly in route modules outside clientLoader/clientAction.",
        },
      ],
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["**/server/*.client*", "*.server"],
              message:
                "Respect strict server/client boundary conventions in React Router routes.",
            },
            {
              group: ["**/components/atoms/*", "**/components/molecules/*"],
              message:
                "Routes must orchestrate templates and organisms only. Importing atoms or molecules directly inside src/routes/** is forbidden.",
            },
          ],
        },
      ],
    },
  },
];
