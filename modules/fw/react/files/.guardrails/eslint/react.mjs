// =============================================================================
// .guardrails/eslint/react.mjs — Lock 2 (Strict i18n) & Lock 4 (True Atomic Purity)
// Enforces:
//   - Total ban on hardcoded strings in .tsx (JSXText, literals, templates,
//     concatenations, local prose vars, default props, fallbacks, a11y attrs,
//     and module-scope capitalized literals)
//   - Total ban on intrinsic HTML tags (<div>, <span>, <button>, etc.),
//     <panda.div>, panda('div'), inline style={}, document.createElement,
//     Tailwind classes, styled.tag, and thin wrapper components
//   - Ban on useEffect/useLayoutEffect in UI & routes, and ban on all hooks in atoms/
//   - Strict downward Atomic Design hierarchy (tokens -> theme -> i18n -> atoms ->
//     molecules -> organisms/simulations -> templates -> pages)
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import a11yConfig from "./ui-guardrails.mjs";

export const atomicPurityAndI18nSyntaxRules = [
  {
    selector:
      "JSXOpeningElement > JSXIdentifier[name=/^[a-z]/][name!=/^(html|head|meta)$/][name!=/^(md|m3e)-/]",
    message:
      'Direct usage of intrinsic HTML element "<{{name}}>" is strictly forbidden. Use Panda CSS atomic layout components (<Box>, <Flex>, <Stack>, etc. from "styled-system/jsx") or Material Design 3 (@m3e/react / <md-*>/<m3e-*>) components.',
  },
  {
    selector:
      "JSXOpeningElement > JSXMemberExpression[property.name=/^(div|span|p|button|a|img|input|html|head|meta|link|script|style|title|form|textarea|select|option|label|dialog|svg|canvas|iframe|table|tr|td|th|ul|ol|li)$/]",
    message:
      "Direct usage of generic <panda.*> HTML wrappers (<panda.div>, <panda.span>, <panda.button>, etc.) is strictly forbidden. Use dedicated Panda CSS layout primitives (<Box>, <Flex>, <Grid>, <Stack>, <HStack>, <VStack>, <Center>) or Material Design 3 components.",
  },
  {
    selector: "JSXOpeningElement > JSXMemberExpression[object.name!='panda']",
    message:
      "Aliased or non-panda JSX member expressions (<{{object.name}}.{{property.name}}>) are forbidden. Use canonical <panda.main>, <panda.header>, <panda.section>, <panda.h1> or Panda layout components.",
  },
  {
    selector:
      "CallExpression[callee.object.name='document'][callee.property.name='createElement']",
    message:
      "Direct DOM manipulation via document.createElement is prohibited. Use Panda CSS layout components or MD3 elements.",
  },
  {
    selector: "JSXAttribute[name.name='style']",
    message:
      "Inline `style` attributes are prohibited altogether. Raw styles must be placed in clean CSS files, tokens, or Panda CSS recipes.",
  },
  {
    selector:
      "JSXAttribute[name.name='className'] > Literal[value=/(?:^|\\s)(?:!size-|flex-col|items-center|justify-between|p-\\d|m-\\d|text-[a-z0-9]|bg-[a-z0-9])/]",
    message:
      "Tailwind utility syntax is forbidden in className. Use Panda CSS atomic components or MD3 component tokens.",
  },
  {
    selector: "MemberExpression[object.name='styled'][property.name=/^[a-z]/]",
    message:
      "Creating styled elements via styled.tag is prohibited. Use Panda CSS atomic components or MD3 primitives.",
  },
  {
    selector: "CallExpression[callee.name='styled'][arguments.0.type='Literal']",
    message:
      'Creating styled elements via styled("tag") is prohibited. Use Panda CSS atomic layout components or MD3 primitives.',
  },
  {
    selector:
      "VariableDeclarator[id.name=/^(Div|Span|ButtonWrapper|CustomButton|BoxWrapper|TextWrapper|HeadingWrapper)$/]",
    message:
      'Creating thin wrapper components named "{{id.name}}" is prohibited. Consume Panda CSS atomic layout or MD3 primitives directly.',
  },
  {
    selector: "CallExpression[callee.name='panda']",
    message:
      'Recreating HTML primitives via `panda("tag", ...)` factory calls is forbidden. Use dedicated Panda layout primitives (<Box>, <Flex>, <Grid>, <Stack>, <Container>) with `cva()`/`sva()` recipes or Material Design 3 (@m3e/react) components.',
  },
  {
    selector:
      "ImportSpecifier[imported.name=/^(useEffect|useLayoutEffect)$/], CallExpression[callee.name=/^(useEffect|useLayoutEffect)$/]",
    message:
      "Imperative side-effect hooks (`useEffect` / `useLayoutEffect`) are forbidden in UI components and routes. Derive state purely during render or use React Router loaders/actions.",
  },
  // Lock 2: Strict i18n Separation of Concerns
  {
    selector: ":matches(JSXElement, JSXFragment) > JSXText[value=/[a-zA-Z0-9]/]",
    message:
      "Raw text literal detected in JSX. Separation of Concerns violation: all user-facing content must originate from i18n resources.",
  },
  {
    selector:
      ":matches(JSXElement, JSXFragment) > JSXExpressionContainer > Literal[value=/[a-zA-Z0-9]/]",
    message:
      "Hardcoded string literal in JSX is prohibited. Content must be imported from i18n resources.",
  },
  {
    selector:
      ":matches(JSXElement, JSXFragment) > JSXExpressionContainer > TemplateLiteral",
    message:
      "Hardcoded template literal in JSX is prohibited. Content must be imported from i18n resources.",
  },
  {
    selector:
      ":matches(JSXElement, JSXFragment) > JSXExpressionContainer :matches(BinaryExpression, LogicalExpression, ArrayExpression, CallExpression[callee.name='String']) > Literal[value=/[a-zA-Z\u00C0-\u024F]/]",
    message:
      "Hardcoded string literal inside JSX expression (concatenation, array, or String() call) is prohibited. All user-facing content must originate from i18n resources.",
  },
  {
    selector:
      ":matches(FunctionDeclaration, FunctionExpression, ArrowFunctionExpression) VariableDeclarator Literal[value=/[a-zA-Z\u00C0-\u024F]{2,}\\s+[a-zA-Z\u00C0-\u024F]{2,}/]",
    message:
      "Hardcoded prose string assigned to a variable inside a function is prohibited. All user-facing content must originate from i18n resources.",
  },
  {
    selector:
      ":matches(FunctionDeclaration, FunctionExpression, ArrowFunctionExpression) VariableDeclarator[id.name=/^(label|text|title|heading|subtitle|message|description|caption|content|copy|placeholder|buttonText|cta|errorText|emptyText|helperText)$/] > Literal[value=/[a-zA-Z\u00C0-\u024F]/]",
    message:
      "Hardcoded UI string assigned to a local variable inside a function is prohibited. All user-facing content must originate from i18n resources.",
  },
  {
    selector:
      ":matches(FunctionDeclaration, FunctionExpression, ArrowFunctionExpression) VariableDeclarator TemplateLiteral[expressions.length=0]",
    message:
      "Static template literal assigned to a variable inside a function is prohibited. All user-facing content must originate from i18n resources.",
  },
  {
    selector:
      "Property[key.name='content'][value.type='Literal'][value.value!=''][value.value!='none']",
    message:
      "Presentation layers must not declare textual content in CSS/styles.",
  },
  {
    selector:
      "AssignmentPattern[left.name=/^(label|title|ariaLabel|placeholder|alt|helperText|description|pdfLabel)$/] > Literal[value=/[a-zA-Z\u00C0-\u024F]/]",
    message:
      "Hardcoded localized string detected in component default prop value. Content must originate from i18n resources.",
  },
  {
    selector:
      "VariableDeclarator[id.name=/^(label|title|ariaLabel|placeholder|alt|helperText|description|pdfLabel)$/] LogicalExpression[operator=/(?:\\|\\||\\?\\?)/] > Literal[value=/[a-zA-Z\u00C0-\u024F]/]",
    message:
      "Hardcoded localized string detected in fallback expression. Content must originate from i18n resources.",
  },
  {
    selector:
      "JSXAttribute[name.name=/^(alt|aria-label|aria-placeholder|aria-roledescription|aria-valuetext|title)$/] > :matches(Literal, JSXExpressionContainer > Literal)[value=/[a-zA-Z\u00C0-\u024F]/]",
    message:
      'Hardcoded localized string detected in attribute "{{name.name}}". All user-facing alt text and accessibility labels must originate from i18n content.',
  },
  {
    selector:
      ":matches(VariableDeclarator, Property, AssignmentPattern, ReturnStatement, ArrayExpression) > Literal[value=/^[A-Z\u00C0-\u00DE][a-z\u00DF-\u00FF]{2,}/]",
    message:
      "Hardcoded capitalized UI string literal in .tsx module is prohibited (even outside JSX/functions). All user-facing strings must originate from `src/i18n/strings.ts` or MDX content.",
  },
];

export default [
  {
    name: "guardrails/fw:react/core",
    files: ["src/**/*.{jsx,tsx}", "simulations/**/*.{jsx,tsx}"],
    ignores: ["**/*.stories.{jsx,tsx}", "**/*.test.{jsx,tsx}", "**/*.spec.{jsx,tsx}"],
    rules: {
      "max-lines": ["error", { max: 150, skipBlankLines: true, skipComments: true }],
      "max-lines-per-function": ["error", { max: 28, skipBlankLines: true, skipComments: true }],
      "complexity": ["error", 3],
      "max-depth": ["error", 1],
      "react/prop-types": "off",
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "error",
      "react/no-array-index-key": "error",
      "react/no-danger": "error",
      "react/jsx-no-useless-fragment": "error",
      "react/self-closing-comp": "error",
      "i18next/no-literal-string": ["error", { mode: "jsx-text-only" }],
      "no-restricted-syntax": ["error", ...atomicPurityAndI18nSyntaxRules],
    },
  },
  {
    name: "guardrails/fw:react/atoms-stateless-purity",
    files: ["src/components/atoms/**/*.{ts,tsx}"],
    ignores: ["**/*.stories.{ts,tsx}", "**/*.test.{ts,tsx}"],
    rules: {
      "no-restricted-syntax": [
        "error",
        ...atomicPurityAndI18nSyntaxRules,
        {
          selector:
            "ImportSpecifier[imported.name=/^use[A-Z]/], CallExpression[callee.name=/^use[A-Z]/]",
          message:
            "Atoms must be 100% stateless pure functions. React hooks (`useState`, `useReducer`, `useContext`, `useEffect`, etc.) are forbidden in `src/components/atoms/`.",
        },
      ],
    },
  },
  ...a11yConfig,
];
