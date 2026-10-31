// =============================================================================
// .guardrails/eslint/testing-fortress.mjs — Lock 6: Test Assertion Purity
// Enforces meaningful assertions in every test, bans test skips/focus/todos,
// weak assertions (toBeTruthy/toBeDefined/toMatchSnapshot), and vi.mock/jest.mock.
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================

const FORBIDDEN_TEST_MODIFIERS = new Set(["skip", "only", "todo"]);
const WEAK_MATCHERS = new Set([
  "toBeTruthy",
  "toBeFalsy",
  "toBeDefined",
  "toMatchSnapshot",
  "toMatchInlineSnapshot",
]);

function checkTestNodeForExpects(node) {
  if (!node || typeof node !== "object") return false;
  if (
    node.type === "CallExpression" &&
    ((node.callee?.type === "Identifier" &&
      (node.callee.name === "expect" ||
        node.callee.name === "expectTypeOf" ||
        node.callee.name.startsWith("assert") ||
        node.callee.name.startsWith("expect"))) ||
      (node.callee?.type === "MemberExpression" &&
        node.callee.object?.type === "Identifier" &&
        (node.callee.object.name === "expect" || node.callee.object.name === "assert")))
  ) {
    return true;
  }
  for (const key of Object.keys(node)) {
    if (key === "parent" || key === "range" || key === "loc") continue;
    const child = node[key];
    if (Array.isArray(child)) {
      if (child.some((c) => checkTestNodeForExpects(c))) return true;
    } else if (checkTestNodeForExpects(child)) {
      return true;
    }
  }
  return false;
}

const testingFortressPlugin = {
  rules: {
    "test-assertion-purity": {
      meta: {
        type: "problem",
        docs: {
          description:
            "Lock 6: Forbid hollow tests, skipped/focused tests, weak matchers, and module mocking (vi.mock/jest.mock)",
        },
        schema: [],
      },
      create(context) {
        return {
          CallExpression(node) {
            const callee = node.callee;

            if (
              callee.type === "MemberExpression" &&
              callee.object.type === "Identifier" &&
              ["it", "test", "describe"].includes(callee.object.name) &&
              callee.property.type === "Identifier" &&
              FORBIDDEN_TEST_MODIFIERS.has(callee.property.name)
            ) {
              context.report({
                node,
                message: `[Lock 6: Test Assertion Purity] '${callee.object.name}.${callee.property.name}' is strictly forbidden. Every test must execute and pass.`,
              });
            }

            if (
              callee.type === "MemberExpression" &&
              callee.object.type === "Identifier" &&
              ["vi", "jest"].includes(callee.object.name) &&
              callee.property.type === "Identifier" &&
              ["mock", "spyOn", "doMock"].includes(callee.property.name)
            ) {
              context.report({
                node,
                message: `[Lock 6: Dependency Injection Only] '${callee.object.name}.${callee.property.name}()' is forbidden. Pass dependencies explicitly as function parameters or props instead of mocking modules.`,
              });
            }

            if (
              callee.type === "MemberExpression" &&
              callee.property.type === "Identifier" &&
              WEAK_MATCHERS.has(callee.property.name)
            ) {
              context.report({
                node: callee.property,
                message: `[Lock 6: Test Assertion Purity] Weak matcher '.${callee.property.name}()' is forbidden. Assert exact semantic values with '.toBe()', '.toEqual()', or '.toStrictEqual()'.`,
              });
            }

            const isTestBlock =
              callee.type === "Identifier" &&
              (callee.name === "it" || callee.name === "test");
            if (isTestBlock && node.arguments.length >= 2) {
              const testFn = node.arguments[1];
              if (
                (testFn.type === "ArrowFunctionExpression" ||
                  testFn.type === "FunctionExpression") &&
                !checkTestNodeForExpects(testFn.body)
              ) {
                context.report({
                  node,
                  message:
                    "[Lock 6: Test Assertion Purity] Hollow test detected: test callback contains no 'expect(...)' or 'assert*(...)' calls.",
                });
              }
            }
          },
        };
      },
    },
  },
};

export function createTestingFortressConfig() {
  return [
    {
      name: "guardrails/addon:testing-fortress",
      files: ["**/*.test.{ts,tsx}", "**/*.spec.{ts,tsx}"],
      plugins: {
        "testing-fortress": testingFortressPlugin,
      },
      rules: {
        "testing-fortress/test-assertion-purity": "error",
        "max-lines-per-function": ["error", { max: 60, skipBlankLines: true, skipComments: true }],
        "max-lines": ["error", { max: 300, skipBlankLines: true, skipComments: true }],
      },
    },
  ];
}

export default createTestingFortressConfig();

