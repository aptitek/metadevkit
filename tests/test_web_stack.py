"""Tests for Web stack (lang:ts, fw:react, and 7 cross-cutting addons)."""

from __future__ import annotations

import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace


def _write_compliant_web_fixtures(proj: Path) -> None:
    """Create compliant Button atom, 1:1 test, CSF3 story, and wrangler.toml."""
    atoms_dir = proj / "src" / "components" / "atoms"
    atoms_dir.mkdir(parents=True, exist_ok=True)
    (atoms_dir / "Button.tsx").write_text(
        "export function Button(): null {\n  return null;\n}\n",
        encoding="utf-8",
    )
    (atoms_dir / "Button.test.tsx").write_text(
        'import { Button } from "./Button";\n\nit("returns null", () => {\n  expect(Button()).toBe(null);\n});\n',
        encoding="utf-8",
    )
    (atoms_dir / "Button.stories.tsx").write_text(
        'import { Button } from "./Button";\n\n'
        'export default {\n  title: "Atoms/Button",\n  component: Button,\n};\n\n'
        "export const Primary = {\n  args: {},\n};\n",
        encoding="utf-8",
    )
    (proj / "wrangler.toml").write_text(
        'name = "sample-react-cloudflare-app"\ncompatibility_date = "2026-01-01"\n',
        encoding="utf-8",
    )


def _seed_eslint_plugin_stubs(proj: Path) -> None:
    """Create minimal ESM plugin stubs in node_modules so node can import eslint.config.mjs."""
    nm = proj / "node_modules"
    stubs = {
        "typescript-eslint": "export default { parser: { parse() {} }, plugin: { rules: {} } };\n",
        "eslint-plugin-react": "export default { rules: {} };\n",
        "eslint-plugin-react-hooks": "export default { rules: {} };\n",
        "eslint-plugin-i18next": "export default { rules: {} };\n",
        "eslint-plugin-jsx-a11y": "export default { rules: {} };\n",
    }
    for pkg, code in stubs.items():
        pkg_dir = nm / pkg
        pkg_dir.mkdir(parents=True, exist_ok=True)
        (pkg_dir / "package.json").write_text(
            f'{{"name": "{pkg}", "type": "module", "main": "index.js"}}\n',
            encoding="utf-8",
        )
        (pkg_dir / "index.js").write_text(code, encoding="utf-8")


class WebStackTests(unittest.TestCase):
    """Verify Web modules, dynamic feature:add, AST anti-bypass, and full verify."""

    def test_pure_ts_does_not_include_react_or_astro_rules(self) -> None:
        """Verify pure lang:ts omits .size-limit.json, React Atomic rules, simulations, and app/routes."""
        with RepoTestWorkspace() as ws:
            pure_ts = ws.project_dir("pure-ts")
            ws.init_project(pure_ts, "core,lang:ts,addon:testing-fortress")
            self.assertFalse((pure_ts / ".size-limit.json").exists())
            depcruise_text = (pure_ts / ".dependency-cruiser.cjs").read_text(encoding="utf-8")
            self.assertNotIn("src/components/atoms", depcruise_text)
            self.assertNotIn("simulations/", depcruise_text)

            vitest_text = (pure_ts / "vitest.config.ts").read_text(encoding="utf-8")
            self.assertNotIn("simulations/", vitest_text)
            self.assertNotIn("src/content.config.ts", vitest_text)

            stryker_text = (pure_ts / "stryker.config.mjs").read_text(encoding="utf-8")
            self.assertNotIn("simulations/", stryker_text)

            knip_text = (pure_ts / "knip.json").read_text(encoding="utf-8")
            self.assertNotIn("app/root.tsx", knip_text)
            self.assertNotIn("app/routes", knip_text)

    def test_web_stack_feature_add_and_verify(self) -> None:
        """Add all 7 Web addons, test AST bypass rejection, and pass task verify."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("web-app")
            ws.init_project(proj, "core,lang:ts,fw:react")
            self.assertTrue((proj / ".size-limit.json").is_file())
            self.assertTrue((proj / ".guardrails" / "depcruise" / "react.cjs").is_file())
            for addon in (
                "cloudflare",
                "design-system",
                "testing-fortress",
                "storybook",
                "content-md",
                "drizzle-d1",
                "lib-exports",
            ):
                ws.run_cmd(["task", "feature:add", "--", addon], cwd=proj)

            active = ws.read_manifest_modules(proj)
            self.assertIn("addon:ui-guardrails", active)
            self.assertEqual(len(active), 11)
            self.assertTrue((proj / ".guardrails" / "paths.json").is_file())
            self.assertTrue((proj / ".storybook" / "main.ts").is_file())
            self.assertTrue((proj / ".storybook" / "preview.ts").is_file())

            atoms_dir = proj / "src" / "components" / "atoms"
            atoms_dir.mkdir(parents=True, exist_ok=True)
            (atoms_dir / "Button.tsx").write_text("// @ts-ignore\nexport function Button(): null { return null; }\n")
            self.assertNotEqual(ws.run_cmd(["task", "verify"], cwd=proj, check=False).returncode, 0)

            _write_compliant_web_fixtures(proj)
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_eslint_flat_config_module_colocation(self) -> None:
        """Verify each ESLint fragment registers its own plugins/parser and composes cleanly."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("eslint-colocation")
            ws.init_project(
                proj,
                "core,lang:ts,fw:react,addon:design-system,addon:storybook,addon:testing-fortress",
            )
            eslint_root_text = (proj / "eslint.config.mjs").read_text(encoding="utf-8")
            self.assertNotIn("eslint-plugin-react", eslint_root_text)
            self.assertNotIn("eslint-plugin-astro", eslint_root_text)

            _seed_eslint_plugin_stubs(proj)
            check_js = (
                "import cfg from './eslint.config.mjs';"
                "const named = cfg.filter((c) => c.name);"
                "const names = named.map((c) => c.name);"
                "if (new Set(names).size !== names.length) process.exit(2);"
                "const byName = Object.fromEntries(named.map((c) => [c.name, c]));"
                "if (!byName['guardrails/lang:ts/base']?.languageOptions?.parser) process.exit(3);"
                "if (!byName['guardrails/lang:ts/base']?.plugins?.['@typescript-eslint']) process.exit(4);"
                "if (!byName['guardrails/fw:react/core']?.plugins?.['react-hooks']) process.exit(5);"
                "if (!byName['guardrails/fw:react/a11y']?.plugins?.['jsx-a11y']) process.exit(6);"
            )
            ws.run_cmd(["node", "--input-type=module", "-e", check_js], cwd=proj)


if __name__ == "__main__":
    unittest.main()
