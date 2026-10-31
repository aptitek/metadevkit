// =============================================================================
// .guardrails/eslint/ts.mjs — Haskell-Grade Functional Purity & TS Strictness
// Enforces Lock 1:
//   - Zero unsafe type coercions (`as T` except `as const`, `<T>x`, `x!`, `x is T`)
//   - Pure functional immutability (`const` only, zero reassignment, zero loops,
//     zero mutating array methods, zero `else`, zero `throw`/`try..catch` in pure src)
//   - Strict complexity (<= 3 in src, <= 8 in scripts/tests) & function length (<= 28)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
export const restrictedImportsRule = [
  "error",
  {
    paths: [
      { name: "@mui/material", message: "MUI is deprecated. Use @m3e/react and Panda CSS." },
      { name: "@mui/system", message: "MUI is deprecated. Use @m3e/react and Panda CSS." },
      { name: "@mui/icons-material", message: "MUI is deprecated. Use @m3e/icons." },
      { name: "@emotion/react", message: "Emotion is prohibited. Use Panda CSS." },
      { name: "@emotion/styled", message: "Emotion is prohibited. Use Panda CSS." },
      { name: "@tailwindcss/vite", message: "Tailwind CSS is disallowed. Use MD3 tokens and Panda CSS." },
      { name: "tailwindcss", message: "Tailwind CSS is disallowed. Use MD3 tokens and Panda CSS." },
      {
        name: "styled-system/patterns",
        message: "Importing pattern functions from styled-system/patterns is prohibited. Use Panda JSX layout primitives from 'styled-system/jsx' or cva()/sva() recipes.",
      },
    ],
    patterns: [
      { group: ["@mui/*"], message: "MUI is deprecated. Migrate to @m3e/react and Panda CSS." },
      { group: ["@emotion/*"], message: "Emotion is prohibited. Migrate to Panda CSS." },
      {
        group: ["*/styled-system/patterns", "*/styled-system/patterns/*"],
        message: "Importing pattern functions from styled-system/patterns is prohibited.",
      },
    ],
  },
];

export const pureFunctionalSyntaxRules = [
  {
    selector: "ExportAllDeclaration",
    message: "Legacy wildcard barrel exports (export * from '...') are strictly prohibited. Export symbols explicitly.",
  },
  {
    selector: "TSAsExpression[typeAnnotation.typeName.name!='const'], TSTypeAssertion",
    message: "Unsafe type assertion (`as T` / `<T>x`) is forbidden in src/ (unsafeCoerce). Use `as const` or a validated schema/smart constructor instead.",
  },
  {
    selector: "TSNonNullExpression",
    message: "Non-null assertion (`x!`) is forbidden in src/. Handle null and undefined explicitly.",
  },
  {
    selector: "TSTypePredicate",
    message: "Manual type predicate (`x is T`) is forbidden in src/ to prevent unsound type narrowing. Use discriminated unions or total conversion functions.",
  },
  {
    selector: "VariableDeclaration[kind=/^(let|var)$/]",
    message: "Mutable variable binding (`let`/`var`) is forbidden in src/ (functional/no-let). Use immutable `const` bindings for referential transparency.",
  },
  {
    selector: "AssignmentExpression",
    message: "Imperative variable or property reassignment is forbidden in src/ (functional/immutable-data). Return new immutable values instead.",
  },
  {
    selector: ":matches(ForStatement, ForInStatement, ForOfStatement, WhileStatement, DoWhileStatement)",
    message: "Imperative loop (`for`/`while`) is forbidden in src/. Use declarative functional transformations (`.map()`, `.filter()`, `.reduce()`).",
  },
  {
    selector: "CallExpression > MemberExpression[property.name=/^(push|pop|shift|unshift|splice|sort|reverse|fill|copyWithin)$/]",
    message: "Mutating collection method (`.push()`, `.pop()`, `.splice()`, `.sort()`, etc.) is forbidden in src/. Use immutable alternatives (`.toSorted()`, `.toSpliced()`, `.toReversed()`, `.concat()`).",
  },
  {
    selector: "IfStatement[alternate!=null]",
    message: "Imperative `else` / `else if` branch is forbidden in src/. Use early returns or declarative expressions.",
  },
  {
    selector: ":matches(ThrowStatement, TryStatement)",
    message: "Partial functions (`throw` / `try..catch`) are forbidden in pure domain/UI modules. Return an explicit `Result<T, E>` discriminated union instead.",
  },
];

export default [
  {
    name: "guardrails/lang:ts/base",
    files: ["**/*.{ts,tsx,mts,cts}"],
    rules: {
      "no-console": ["error", { allow: ["warn", "error"] }],
      "no-debugger": "error",
      "no-eval": "error",
      "no-implied-eval": "error",
      "no-var": "error",
      "prefer-const": "error",
      "eqeqeq": ["error", "always"],
      "complexity": ["error", 8],
      "max-lines": ["error", { max: 256, skipBlankLines: true, skipComments: true }],
      "max-lines-per-function": ["error", { max: 64, skipBlankLines: true, skipComments: true }],
      "max-depth": ["error", 3],
      "max-params": ["error", 3],
      "max-nested-callbacks": ["error", 3],
      "no-restricted-imports": restrictedImportsRule,
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports" },
      ],
      "@typescript-eslint/ban-ts-comment": [
        "error",
        {
          "ts-expect-error": true,
          "ts-ignore": true,
          "ts-nocheck": true,
          "ts-check": false,
        },
      ],
    },
  },
  {
    name: "guardrails/lang:ts/src-purity",
    files: ["src/**/*.{ts,tsx}", "simulations/**/*.{ts,tsx}"],
    ignores: ["**/*.stories.{ts,tsx}", "**/*.test.{ts,tsx}", "**/*.spec.{ts,tsx}", "src/worker.ts"],
    rules: {
      "complexity": ["error", 3],
      "max-depth": ["error", 1],
      "max-lines": ["error", { max: 150, skipBlankLines: true, skipComments: true }],
      "max-lines-per-function": ["error", { max: 28, skipBlankLines: true, skipComments: true }],
      "max-params": ["error", 3],
      "no-else-return": ["error", { allowElseIf: false }],
      "no-restricted-syntax": ["error", ...pureFunctionalSyntaxRules],
    },
  },
  {
    name: "guardrails/lang:ts/tokens-allowance",
    files: ["src/tokens/**/*.{ts,tsx}", "src/theme/**/*.{ts,tsx}"],
    rules: {
      "max-lines": ["error", { max: 256, skipBlankLines: true, skipComments: true }],
    },
  },
  {
    name: "guardrails/lang:ts/scripts-strict-ts",
    files: ["scripts/**/*.{js,jsx,mjs,cjs}"],
    rules: {
      "no-restricted-syntax": [
        "error",
        {
          selector: "Program",
          message: "Untyped JavaScript files (.js, .mjs, .cjs) are strictly forbidden in scripts/. Write all guardian scripts in strict TypeScript (.ts).",
        },
      ],
    },
  },
];
