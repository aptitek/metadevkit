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

            atoms_dir = proj / "src" / "components" / "atoms"
            atoms_dir.mkdir(parents=True, exist_ok=True)
            (atoms_dir / "Button.tsx").write_text("// @ts-ignore\nexport function Button(): null { return null; }\n")
            self.assertNotEqual(ws.run_cmd(["task", "verify"], cwd=proj, check=False).returncode, 0)

            _write_compliant_web_fixtures(proj)
            ws.run_cmd(["task", "verify"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
