// =============================================================================
// .guardrails/eslint/storybook.mjs — Storybook CSF3 Guardrails
// Enforces CSF3 object story notation, bans legacy storiesOf(), Template.bind,
// and direct function exports in *.stories.tsx.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================

const storybookCsf3Plugin = {
  rules: {
    "strict-csf3-stories": {
      meta: {
        type: "problem",
        docs: {
          description: "Enforce CSF3 object notation and forbid legacy storiesOf/Template.bind/function stories",
        },
        schema: [],
      },
      create(context) {
        return {
          CallExpression(node) {
            if (node.callee.type === "Identifier" && node.callee.name === "storiesOf") {
              context.report({
                node,
                message: "[Storybook CSF3] Legacy 'storiesOf()' is forbidden. Use CSF3 default Meta export + StoryObj exports.",
              });
            }
            if (
              node.callee.type === "MemberExpression" &&
              node.callee.property.type === "Identifier" &&
              node.callee.property.name === "bind"
            ) {
              context.report({
                node,
                message: "[Storybook CSF3] CSF2 'Template.bind({})' is forbidden. Use CSF3 StoryObj object exports with 'args'.",
              });
            }
          },
          ExportNamedDeclaration(node) {
            if (node.declaration?.type === "FunctionDeclaration") {
              context.report({
                node: node.declaration,
                message: "[Storybook CSF3] Exporting function stories is forbidden. Export a CSF3 StoryObj constant ('export const Primary: Story = { args: ... }').",
              });
            }
            if (node.declaration?.type === "VariableDeclaration") {
              for (const decl of node.declaration.declarations) {
                if (
                  decl.init &&
                  (decl.init.type === "ArrowFunctionExpression" ||
                    decl.init.type === "FunctionExpression")
                ) {
                  context.report({
                    node: decl,
                    message: "[Storybook CSF3] Exporting arrow-function stories is forbidden. Export a CSF3 StoryObj object literal.",
                  });
                }
              }
            }
          },
        };
      },
    },
  },
};

export function createStorybookConfig() {
  return [
    {
      name: "guardrails/addon:storybook",
      files: ["**/*.stories.{ts,tsx}"],
      plugins: {
        "storybook-csf3": storybookCsf3Plugin,
      },
      rules: {
        "storybook-csf3/strict-csf3-stories": "error",
        "max-lines-per-function": ["error", { max: 60, skipBlankLines: true, skipComments: true }],
        "max-lines": ["error", { max: 300, skipBlankLines: true, skipComments: true }],
      },
    },
  ];
}

export default createStorybookConfig();

