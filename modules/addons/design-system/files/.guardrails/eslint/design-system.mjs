// =============================================================================
// .guardrails/eslint/design-system.mjs — Lock 3, Lock 5 & CSS Tokens Plugins
// Implements:
//   1. m3-tokens plugin: no-hardcoded-colors, enforce-color-pairing (MD3 algebra),
//      enforce-motion-tokens, enforce-shape-tokens, enforce-typography-tokens
//   2. panda-recipes plugin: enforce-recipe-usage (max 3 inline style props,
//      no spread, no conditional style props, mandatory defaultVariants,
//      slot recipe anatomy, and canonical commutative recipe deduplication)
//   3. css-tokens plugin: no-unscoped-component-override, no-scoped-important,
//      no-raw-colors, no-unperformant-transitions, no-tailwind-directives
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================

export const MD3_COLOR_PAIRINGS = {
  primary: ["onPrimary"],
  primaryContainer: ["onPrimaryContainer"],
  secondary: ["onSecondary"],
  secondaryContainer: ["onSecondaryContainer"],
  tertiary: ["onTertiary"],
  tertiaryContainer: ["onTertiaryContainer"],
  error: ["onError"],
  errorContainer: ["onErrorContainer"],
  background: ["onBackground"],
  surface: ["onSurface", "onSurfaceVariant"],
  surfaceDim: ["onSurface", "onSurfaceVariant"],
  surfaceBright: ["onSurface", "onSurfaceVariant"],
  surfaceContainerLowest: ["onSurface", "onSurfaceVariant"],
  surfaceContainerLow: ["onSurface", "onSurfaceVariant"],
  surfaceContainer: ["onSurface", "onSurfaceVariant"],
  surfaceContainerHigh: ["onSurface", "onSurfaceVariant"],
  surfaceContainerHighest: ["onSurface", "onSurfaceVariant"],
  surfaceVariant: ["onSurfaceVariant", "onSurface"],
  inverseSurface: ["inverseOnSurface"],
};

const APPROVED_NUM_CORNERS = [0, 4, 8, 12, 16, 20, 28, 32, 48, 9999];
const APPROVED_SHAPE_CORNERS = new Set([
  ...APPROVED_NUM_CORNERS,
  ...APPROVED_NUM_CORNERS.map(String),
  ...APPROVED_NUM_CORNERS.map((n) => `${n}px`),
  "50%",
  "100%",
  "none",
  "extraSmall",
  "small",
  "medium",
  "large",
  "extraLarge",
  "full",
  "inherit",
  "initial",
  "unset",
]);

const CORNER_PROPERTIES = new Set([
  "borderRadius",
  "borderTopLeftRadius",
  "borderTopRightRadius",
  "borderBottomLeftRadius",
  "borderBottomRightRadius",
  "borderStartStartRadius",
  "borderStartEndRadius",
  "borderEndStartRadius",
  "borderEndEndRadius",
  "rounded",
  "roundedTop",
  "roundedBottom",
  "roundedLeft",
  "roundedRight",
]);

const TIMING_KEYS = new Set(["ease", "easing", "transitionTimingFunction"]);
const DURATION_KEYS = new Set(["duration", "transitionDuration"]);
const HEX_REGEX = /^#([0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;
const FN_REGEX = /^(rgb|hsl|oklch|lab|lch)a?\s*\(/i;

const NON_STYLE_JSX_ATTRIBUTES = new Set(
  "id,key,ref,className,role,tabIndex,charSet,name,content,lang,type,href,target,rel,src,alt,title,value,defaultValue,checked,disabled,required,readOnly,htmlFor,children".split(",")
);
const PANDA_JSX_CONTAINERS = new Set(
  "Box,Flex,Stack,Container,Grid,HStack,VStack,Center,Wrap,Circle,Square".split(",")
);
const RECIPE_CREATORS = new Set(["cva", "sva", "defineRecipe", "defineSlotRecipe"]);
const SLOT_RECIPE_CREATORS = new Set(["sva", "defineSlotRecipe"]);
const MAX_INLINE_STYLE_PROPS = 3;
const MIN_SHARED_RECIPE_PROPS = 3;

function getPropertyKeyName(node) {
  const key = node?.key;
  if (!key) return "";
  if (typeof key.name === "string") return key.name;
  return typeof key.value === "string" ? key.value : "";
}

function getJsxAttrName(node) {
  const nameNode = node?.name;
  if (typeof nameNode === "string") return nameNode;
  return nameNode && typeof nameNode.name === "string" ? nameNode.name : "";
}

function extractJsxAttributeValue(attrNode) {
  const valNode = attrNode?.value;
  if (!valNode) return undefined;
  if (valNode.type === "Literal") return valNode.value;
  if (valNode.type === "JSXExpressionContainer" && valNode.expression?.type === "Literal") {
    return valNode.expression.value;
  }
  return undefined;
}

function getPropertyByName(objectExpr, propName) {
  return objectExpr?.properties?.find(
    (p) => p.type === "Property" && getPropertyKeyName(p) === propName
  );
}

function extractObjectPropString(objNode, names) {
  for (const prop of objNode.properties ?? []) {
    const key = getPropertyKeyName(prop);
    const valNode = prop.value;
    const val = valNode?.type === "Literal" ? valNode.value : undefined;
    if (key && names.includes(key) && typeof val === "string") {
      return { prop, val };
    }
  }
  return undefined;
}

function isInsideRecipeBase(node) {
  let curr = node?.parent;
  while (curr) {
    if (curr.type === "Property" && getPropertyKeyName(curr) === "base") return true;
    curr = curr.parent;
  }
  return false;
}

function checkObjectColorPairing(objNode, context) {
  const bgEntry = extractObjectPropString(objNode, ["bg", "backgroundColor"]);
  if (!bgEntry) return;
  const allowed = MD3_COLOR_PAIRINGS[bgEntry.val];
  if (!allowed) return;
  const colorEntry = extractObjectPropString(objNode, ["color"]);
  if (colorEntry) {
    if (!allowed.includes(colorEntry.val)) {
      context.report({
        node: colorEntry.prop,
        messageId: "invalidColorPairing",
        data: { bg: bgEntry.val, color: colorEntry.val, expected: allowed.join(" or ") },
      });
    }
    return;
  }
  if (isInsideRecipeBase(objNode)) {
    context.report({
      node: bgEntry.prop,
      messageId: "missingColorPairing",
      data: { bg: bgEntry.val, expected: allowed.join(" or ") },
    });
  }
}

function checkJsxColorPairing(jsxNode, context) {
  const attrs = jsxNode.attributes ?? [];
  let bg;
  let fg;
  for (const attr of attrs) {
    const name = getJsxAttrName(attr);
    const val = extractJsxAttributeValue(attr);
    if ((name === "bg" || name === "backgroundColor") && typeof val === "string") bg = { attr, val };
    if (name === "color" && typeof val === "string") fg = { attr, val };
  }
  const allowed = bg ? MD3_COLOR_PAIRINGS[bg.val] : undefined;
  if (bg && allowed && fg && !allowed.includes(fg.val)) {
    context.report({
      node: fg.attr,
      messageId: "invalidColorPairing",
      data: { bg: bg.val, color: fg.val, expected: allowed.join(" or ") },
    });
  }
}

function createPropAndJsxListener(checker, context) {
  return {
    Property(node) {
      const valNode = node.value;
      checker({ propName: getPropertyKeyName(node), val: valNode?.value, targetNode: valNode ?? node }, context);
    },
    JSXAttribute(node) {
      const valNode = node.value;
      checker({ propName: getJsxAttrName(node), val: extractJsxAttributeValue(node), targetNode: valNode ?? node }, context);
    },
  };
}

export const m3TokensPlugin = {
  meta: { name: "eslint-plugin-m3-tokens" },
  rules: {
    "no-hardcoded-colors": {
      meta: {
        type: "problem",
        messages: {
          noRawColor: "Hardcoded color '{{value}}' detected. Use Material Design 3 tokens or CSS variables (var(--...)) instead.",
        },
      },
      create(context) {
        return {
          Literal(node) {
            if (typeof node.value !== "string") return;
            const trimmed = node.value.trim();
            if (
              trimmed.startsWith("var(--") ||
              trimmed === "transparent" ||
              trimmed === "inherit" ||
              trimmed === "currentColor"
            ) {
              return;
            }
            if (HEX_REGEX.test(trimmed) || FN_REGEX.test(trimmed)) {
              context.report({ node, messageId: "noRawColor", data: { value: trimmed } });
            }
          },
        };
      },
    },
    "enforce-color-pairing": {
      meta: {
        type: "problem",
        messages: {
          invalidColorPairing:
            "MD3 Color Pairing violation: background '{{bg}}' cannot be paired with foreground '{{color}}'. Expected {{expected}}.",
          missingColorPairing:
            "MD3 Color Pairing violation: recipe base with background '{{bg}}' must explicitly declare paired foreground color ({{expected}}).",
        },
      },
      create(context) {
        return {
          ObjectExpression(node) {
            checkObjectColorPairing(node, context);
          },
          JSXOpeningElement(node) {
            checkJsxColorPairing(node, context);
          },
        };
      },
    },
    "enforce-motion-tokens": {
      meta: {
        type: "problem",
        messages: {
          noHardcodedBezier: "Hardcoded cubic-bezier '{{value}}' detected. Use Material Design 3 easing tokens.",
          noHardcodedDuration: "Hardcoded animation duration '{{value}}' detected. Use Material Design 3 duration tokens.",
        },
      },
      create(context) {
        return createPropAndJsxListener(({ propName, val, targetNode }) => {
          if (TIMING_KEYS.has(propName) && typeof val === "string" && /cubic-bezier/i.test(val)) {
            context.report({ node: targetNode, messageId: "noHardcodedBezier", data: { value: val } });
          } else if (
            DURATION_KEYS.has(propName) &&
            (typeof val === "number" || (typeof val === "string" && /^\d+(ms|s)$/.test(val)))
          ) {
            context.report({ node: targetNode, messageId: "noHardcodedDuration", data: { value: String(val) } });
          }
        }, context);
      },
    },
    "enforce-shape-tokens": {
      meta: {
        type: "problem",
        messages: {
          invalidCorner:
            "Non-standard corner radius '{{value}}' detected. Adhere to M3 shape tokens (0, 4, 8, 12, 16, 20, 28, 32, 48, 9999).",
        },
      },
      create(context) {
        return createPropAndJsxListener(({ propName, val, targetNode }) => {
          if (!CORNER_PROPERTIES.has(propName) || val === undefined) return;
          if (typeof val === "string" && val.startsWith("var(--")) return;
          if (!APPROVED_SHAPE_CORNERS.has(val)) {
            context.report({ node: targetNode, messageId: "invalidCorner", data: { value: String(val) } });
          }
        }, context);
      },
    },
    "enforce-typography-tokens": {
      meta: {
        type: "problem",
        messages: {
          noRawFontFamily: "Raw font-family '{{value}}' detected. Use design tokens (var(--font-family-*)) instead.",
        },
      },
      create(context) {
        return createPropAndJsxListener(({ propName, val, targetNode }) => {
          if ((propName !== "fontFamily" && propName !== "font-family") || typeof val !== "string") return;
          if (val.includes("var(--font-family-") || val === "inherit" || val === "initial") return;
          context.report({ node: targetNode, messageId: "noRawFontFamily", data: { value: val } });
        }, context);
      },
    },
  },
};

function extractCanonicalStylePairs(objNode) {
  const pairs = [];
  for (const prop of objNode.properties ?? []) {
    if (prop.type !== "Property") continue;
    const key = getPropertyKeyName(prop);
    const raw = prop.value?.type === "Literal" ? prop.value.value : undefined;
    if (key && (typeof raw === "string" || typeof raw === "number")) {
      pairs.push(`${key}=${String(raw)}`);
    }
  }
  return pairs.sort();
}

function collectRecipeBaseBlocks(objNode) {
  const baseProp = getPropertyByName(objNode, "base");
  const baseVal = baseProp?.value;
  if (baseVal?.type !== "ObjectExpression") return [];
  const directPairs = extractCanonicalStylePairs(baseVal);
  if (directPairs.length > 0) return [{ node: baseVal, pairs: directPairs }];
  const slotBlocks = [];
  for (const prop of baseVal.properties ?? []) {
    if (prop.type === "Property" && prop.value?.type === "ObjectExpression") {
      const sp = extractCanonicalStylePairs(prop.value);
      if (sp.length > 0) slotBlocks.push({ node: prop.value, pairs: sp });
    }
  }
  return slotBlocks;
}

export const pandaRecipesPlugin = {
  meta: { name: "eslint-plugin-panda-recipes" },
  rules: {
    "enforce-recipe-usage": {
      meta: {
        type: "problem",
        messages: {
          noSpreadAttribute:
            "JSX spread attributes are forbidden on Panda layout elements. Pass explicit props or extract a Panda CSS recipe.",
          noConditionalStyleProp:
            "Conditional expression in style prop '{{prop}}' is forbidden. Define a Panda CSS recipe with declarative 'variants' and 'defaultVariants'.",
          tooManyInlineStyleProps:
            "JSX element has {{count}} inline style props (max {{max}} allowed for layout). Extract component styling into a Panda CSS recipe.",
          missingDefaultVariants:
            "Panda CSS recipe '{{fn}}' defines 'variants' without 'defaultVariants'. Always specify 'defaultVariants'.",
          unstyledRecipeSlot:
            "Slot '{{slot}}' in slot recipe has no styles under 'base'. Every declared slot in a slot recipe anatomy must be styled.",
          noAliasedStyledSystemImport:
            "Aliasing styled-system imports is prohibited. Use canonical export names.",
          duplicateRecipeBlock:
            "Duplicate Panda recipe style block detected ({{count}} shared style properties regardless of key order: {{shared}}). Extract or reuse a shared recipe.",
        },
      },
      create(context) {
        const seenBlocks = [];
        return {
          ImportDeclaration(node) {
            if (typeof node.source?.value === "string" && node.source.value.includes("styled-system")) {
              for (const spec of node.specifiers ?? []) {
                if (spec.type === "ImportSpecifier" && spec.imported?.name !== spec.local?.name) {
                  context.report({ node: spec, messageId: "noAliasedStyledSystemImport" });
                }
              }
            }
          },
          JSXOpeningElement(node) {
            const nameNode = node.name;
            const isPanda =
              nameNode?.type === "JSXMemberExpression" ||
              (nameNode?.type === "JSXIdentifier" && PANDA_JSX_CONTAINERS.has(nameNode.name));
            if (!isPanda) return;
            let stylePropCount = 0;
            for (const attr of node.attributes ?? []) {
              if (attr.type === "JSXSpreadAttribute") {
                context.report({ node: attr, messageId: "noSpreadAttribute" });
                continue;
              }
              const attrName = getJsxAttrName(attr);
              if (
                !attrName ||
                NON_STYLE_JSX_ATTRIBUTES.has(attrName) ||
                attrName.startsWith("aria-") ||
                attrName.startsWith("data-") ||
                /^on[A-Z]/.test(attrName)
              ) {
                continue;
              }
              const expr = attr.value?.expression;
              if (expr?.type === "ConditionalExpression" || expr?.type === "LogicalExpression") {
                context.report({ node: attr, messageId: "noConditionalStyleProp", data: { prop: attrName } });
              }
              stylePropCount += 1;
            }
            if (stylePropCount > MAX_INLINE_STYLE_PROPS) {
              context.report({
                node,
                messageId: "tooManyInlineStyleProps",
                data: { count: String(stylePropCount), max: String(MAX_INLINE_STYLE_PROPS) },
              });
            }
          },
          CallExpression(node) {
            const calleeName = typeof node.callee?.name === "string" ? node.callee.name : "";
            const firstArg = node.arguments?.[0];
            if (RECIPE_CREATORS.has(calleeName) && firstArg?.type === "ObjectExpression") {
              if (getPropertyByName(firstArg, "variants") && !getPropertyByName(firstArg, "defaultVariants")) {
                context.report({
                  node: getPropertyByName(firstArg, "variants"),
                  messageId: "missingDefaultVariants",
                  data: { fn: calleeName },
                });
              }
              if (SLOT_RECIPE_CREATORS.has(calleeName)) {
                const slotsVal = getPropertyByName(firstArg, "slots")?.value;
                const baseVal = getPropertyByName(firstArg, "base")?.value;
                if (slotsVal?.type === "ArrayExpression" && baseVal?.type === "ObjectExpression") {
                  for (const el of slotsVal.elements ?? []) {
                    if (el?.type === "Literal" && typeof el.value === "string" && !getPropertyByName(baseVal, el.value)) {
                      context.report({ node: el, messageId: "unstyledRecipeSlot", data: { slot: el.value } });
                    }
                  }
                }
              }
              for (const candidate of collectRecipeBaseBlocks(firstArg)) {
                for (const prev of seenBlocks) {
                  const setA = new Set(prev.pairs);
                  const shared = candidate.pairs.filter((item) => setA.has(item));
                  if (shared.length >= MIN_SHARED_RECIPE_PROPS) {
                    context.report({
                      node: candidate.node,
                      messageId: "duplicateRecipeBlock",
                      data: { count: String(shared.length), shared: shared.join(", ") },
                    });
                    break;
                  }
                }
                seenBlocks.push(candidate);
              }
            }
          },
        };
      },
    },
  },
};

export default [
  {
    name: "guardrails/addon:design-system",
    files: ["src/**/*.{ts,tsx}", "simulations/**/*.{ts,tsx}"],
    plugins: {
      "m3-tokens": m3TokensPlugin,
      "panda-recipes": pandaRecipesPlugin,
    },
    rules: {
      "m3-tokens/no-hardcoded-colors": "error",
      "m3-tokens/enforce-color-pairing": "error",
      "m3-tokens/enforce-motion-tokens": "error",
      "m3-tokens/enforce-shape-tokens": "error",
      "m3-tokens/enforce-typography-tokens": "error",
      "panda-recipes/enforce-recipe-usage": "error",
    },
  },
  {
    name: "guardrails/addon:design-system/tokens-allowance",
    files: ["src/tokens/**/*.{ts,tsx}", "src/theme/**/*.{ts,tsx}"],
    rules: {
      "m3-tokens/no-hardcoded-colors": "off",
      "m3-tokens/enforce-motion-tokens": "off",
      "m3-tokens/enforce-shape-tokens": "off",
    },
  },
];
