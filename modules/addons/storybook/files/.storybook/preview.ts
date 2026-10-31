// =============================================================================
// .storybook/preview.ts — Storybook Global Preview & WCAG 2.2 AA Parameters
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import type { Preview } from "@storybook/react";

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
    a11y: {
      test: "error",
    },
  },
};

export default preview;
