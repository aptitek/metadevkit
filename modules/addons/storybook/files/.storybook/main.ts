// =============================================================================
// .storybook/main.ts — Storybook 8+ React-Vite CSF3 Configuration
// Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
// =============================================================================
import type { StorybookConfig } from "@storybook/react-vite";

const config: StorybookConfig = {
  stories: [
    "../src/**/*.stories.@(ts|tsx)",
    "../app/**/*.stories.@(ts|tsx)",
    "../simulations/**/*.stories.@(ts|tsx)",
  ],
  addons: [
    "@storybook/addon-essentials",
    "@storybook/addon-a11y",
    "@storybook/addon-interactions",
  ],
  framework: {
    name: "@storybook/react-vite",
    options: {},
  },
  docs: {
    autodocs: "tag",
  },
};

export default config;
