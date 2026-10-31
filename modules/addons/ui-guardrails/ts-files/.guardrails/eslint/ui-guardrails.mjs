// =============================================================================
// .guardrails/eslint/ui-guardrails.mjs — WCAG 2.2 AA & W3C ARIA Fortress Configuration
// Maps Panda CSS layout primitives and Material Design 3 (@m3e/react) elements
// to native HTML semantics for strict jsx-a11y verification.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
export const a11yComponentMapping = {
  Box: "div",
  Flex: "div",
  Stack: "div",
  Grid: "div",
  HStack: "div",
  VStack: "div",
  Center: "div",
  Container: "div",
  M3eButton: "button",
  M3eIconButton: "button",
  M3eFab: "button",
  M3eExtendedFab: "button",
  M3eSegmentedButton: "button",
  M3eCheckbox: "input",
  M3eSwitch: "input",
  M3eRadio: "input",
  M3eTextField: "input",
  M3eSelect: "select",
  M3eDialog: "dialog",
  M3eLink: "a",
  Image: "img",
  Thumbnail: "img",
  Avatar: "img",
};

export const STRICT_A11Y_RULES = {
  "jsx-a11y/aria-props": "error",
  "jsx-a11y/aria-proptypes": "error",
  "jsx-a11y/aria-role": "error",
  "jsx-a11y/role-has-required-aria-props": "error",
  "jsx-a11y/role-supports-aria-props": "error",
  "jsx-a11y/aria-unsupported-elements": "error",
  "jsx-a11y/aria-activedescendant-has-tabindex": "error",
  "jsx-a11y/no-aria-hidden-on-focusable": "error",
  "jsx-a11y/alt-text": "error",
  "jsx-a11y/img-redundant-alt": "error",
  "jsx-a11y/control-has-associated-label": [
    "error",
    {
      ignoreElements: ["audio", "canvas", "embed", "input", "textarea", "tr", "video"],
      ignoreRoles: [
        "grid",
        "listbox",
        "menu",
        "menubar",
        "radiogroup",
        "row",
        "tablist",
        "toolbar",
        "tree",
        "treegrid",
      ],
      includeRoles: [
        "button",
        "link",
        "checkbox",
        "menuitem",
        "menuitemcheckbox",
        "menuitemradio",
        "option",
        "radio",
        "switch",
        "tab",
      ],
    },
  ],
  "jsx-a11y/anchor-has-content": "error",
  "jsx-a11y/anchor-is-valid": "error",
  "jsx-a11y/heading-has-content": "error",
  "jsx-a11y/html-has-lang": "error",
  "jsx-a11y/no-redundant-roles": "error",
  "jsx-a11y/no-interactive-element-to-noninteractive-role": "error",
  "jsx-a11y/no-noninteractive-element-to-interactive-role": "error",
  "jsx-a11y/interactive-supports-focus": "error",
  "jsx-a11y/tabindex-no-positive": "error",
  "jsx-a11y/click-events-have-key-events": "error",
  "jsx-a11y/no-static-element-interactions": "error",
  "jsx-a11y/no-noninteractive-element-interactions": "error",
  "jsx-a11y/mouse-events-have-key-events": "error",
  "jsx-a11y/label-has-associated-control": "error",
  "jsx-a11y/autocomplete-valid": "error",
};

export default [
  {
    name: "guardrails/fw:react/a11y",
    files: ["src/**/*.{jsx,tsx}", "simulations/**/*.{jsx,tsx}"],
    settings: {
      "jsx-a11y": {
        components: a11yComponentMapping,
      },
    },
    rules: STRICT_A11Y_RULES,
  },
];
