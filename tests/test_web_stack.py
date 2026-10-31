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
        'import { Button } from "./Button";\n\nexport default {\n  title: "Atoms/Button",\n  component: Button,\n};\n\nexport const Primary = {\n  args: {},\n};\n',
        encoding="utf-8",
    )
    (proj / "wrangler.toml").write_text(
        'name = "sample-react-cloudflare-app"\ncompatibility_date = "2026-01-01"\n',
        encoding="utf-8",
    )


class WebStackTests(unittest.TestCase):
    """Verify Web modules, dynamic feature:add, AST anti-bypass, and full verify."""

    def test_web_stack_feature_add_and_verify(self) -> None:
        """Add all 7 Web addons, test AST bypass rejection, and pass task verify."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("web-app")
            ws.init_project(proj, "core,lang:ts,fw:react")
            addons = [
                "cloudflare",
                "design-system",
                "testing-fortress",
                "storybook",
                "content-md",
                "drizzle-d1",
                "lib-exports",
            ]
            for addon in addons:
                ws.run_cmd(["task", "feature:add", "--", addon], cwd=proj)

            active = ws.read_manifest_modules(proj)
            self.assertEqual(len(active), 10)

            atoms_dir = proj / "src" / "components" / "atoms"
            atoms_dir.mkdir(parents=True, exist_ok=True)
            bypass_tag = "// @ts-" + "ignore"
            (atoms_dir / "Button.tsx").write_text(
                f"{bypass_tag}\nexport function Button(): null {{\n  return null;\n}}\n",
                encoding="utf-8",
            )
            bypass_proc = ws.run_cmd(["task", "verify"], cwd=proj, check=False)
            self.assertNotEqual(bypass_proc.returncode, 0)

            _write_compliant_web_fixtures(proj)
            ws.run_cmd(["task", "verify"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
