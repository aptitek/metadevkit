"""Tests for cross-language homogeneity: mutation testing, a11y, i18n, typecheck, coverage, and Lock 6."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace


class PolyglotHomogeneityTests(unittest.TestCase):
    """Verify homogenous quality gates across TS, Python, Java, Kotlin, and PHP."""

    def test_cross_language_mutate_typecheck_coverage_a11y_i18n_tasks(self) -> None:
        """Verify mutate, typecheck, coverage, a11y, and i18n tasks across all 5 languages."""
        stacks = [
            ("ts-fortress", "core,lang:ts,addon:testing-fortress", "stryker.config.mjs"),
            ("py-fortress", "core,lang:python,addon:testing-fortress", ".guardrails/python/mutmut.toml"),
            ("java-fortress", "core,lang:java,addon:testing-fortress", ".guardrails/java/pitest.gradle.kts"),
            ("kt-fortress", "core,lang:kotlin,addon:testing-fortress", ".guardrails/kotlin/pitest-kotlin.gradle.kts"),
            ("php-fortress", "core,lang:php,addon:testing-fortress", "infection.json5"),
        ]
        with RepoTestWorkspace() as ws:
            for name, modules_csv, expected_cfg in stacks:
                proj = ws.project_dir(name)
                ws.init_project(proj, modules_csv)
                self.assertTrue((proj / expected_cfg).is_file(), f"Missing {expected_cfg} in {name}")
                for gate in ("typecheck", "a11y", "i18n", "coverage", "mutate", "verify"):
                    ws.run_cmd(["task", gate], cwd=proj)

    def test_i18n_and_a11y_gate_blocks_violations_across_web_python_and_minecraft(self) -> None:
        """Verify validate-i18n-and-a11y.sh catches locale drift, Screen literals, and missing tooltips."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("i18n-a11y-app")
            ws.init_project(proj, "core,lang:python,fw:flet")

            locales_dir = proj / "locales"
            locales_dir.mkdir(parents=True, exist_ok=True)
            (locales_dir / "en.json").write_text(
                json.dumps({"app": {"title": "Studio", "save": "Save"}}),
                encoding="utf-8",
            )
            (locales_dir / "fr.json").write_text(
                json.dumps({"app": {"title": "Studio"}}),
                encoding="utf-8",
            )
            drift_proc = ws.run_cmd(["task", "i18n"], cwd=proj, check=False)
            self.assertNotEqual(drift_proc.returncode, 0)
            self.assertIn("Locale key mismatch", drift_proc.stderr + drift_proc.stdout)

            (locales_dir / "fr.json").write_text(
                json.dumps({"app": {"title": "Studio", "save": "Enregistrer"}}),
                encoding="utf-8",
            )
            ws.run_cmd(["task", "i18n"], cwd=proj)

            ui_dir = proj / "src" / "studio" / "ui" / "atoms"
            ui_dir.mkdir(parents=True, exist_ok=True)
            bad_btn = ui_dir / "icon_btn.py"
            bad_btn.write_text(
                "def render_icon(ft: object) -> object:\n    return ft.IconButton(icon='add')\n",
                encoding="utf-8",
            )
            a11y_proc = ws.run_cmd(["task", "a11y"], cwd=proj, check=False)
            self.assertNotEqual(a11y_proc.returncode, 0)
            self.assertIn("tooltip=", a11y_proc.stderr + a11y_proc.stdout)

            bad_btn.write_text(
                "def render_icon(ft: object) -> object:\n    return ft.IconButton(icon='add', tooltip='Add item')\n",
                encoding="utf-8",
            )
            ws.run_cmd(["task", "a11y"], cwd=proj)

            screen_dir = proj / "src" / "main" / "kotlin" / "com" / "stellar" / "client" / "gui"
            screen_dir.mkdir(parents=True, exist_ok=True)
            bad_screen = screen_dir / "ConfigScreen.kt"
            lit_call = "Component." + 'literal("Hardcoded Title")'
            bad_screen.write_text(
                f"package com.stellar.client.gui\nclass ConfigScreen {{\n    val title = {lit_call}\n}}\n",
                encoding="utf-8",
            )
            mc_proc = ws.run_cmd(["task", "i18n"], cwd=proj, check=False)
            self.assertNotEqual(mc_proc.returncode, 0)
            bad_screen.unlink()

    def test_testing_fortress_blocks_skipped_and_tautological_tests_across_languages(self) -> None:
        """Verify Lock 6 blocks skipped and tautological tests in Python, Kotlin, and PHP."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("fortress-polyglot")
            ws.init_project(proj, "core,lang:python,addon:testing-fortress")

            py_tests = proj / "tests"
            py_tests.mkdir(parents=True, exist_ok=True)
            bad_py_test = py_tests / "test_bad.py"
            taut_stmt = "assert " + "True"
            bad_py_test.write_text(f"def test_tautology() -> None:\n    {taut_stmt}\n", encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
            bad_py_test.unlink()

            kt_tests = proj / "src" / "test" / "kotlin"
            kt_tests.mkdir(parents=True, exist_ok=True)
            bad_kt_test = kt_tests / "SampleTest.kt"
            disabled_ann = "@" + "Disabled"
            bad_kt_test.write_text(f"{disabled_ann}\nclass SampleTest\n", encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
            bad_kt_test.unlink()

            bad_php_test = py_tests / "SampleTest.php"
            skip_chain = "->" + "skip()"
            bad_php_test.write_text(f"<?php\ndeclare(strict_types=1);\nit('skips'){skip_chain};\n", encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
            bad_php_test.unlink()

            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_php_strict_types_and_python_no_any_gates(self) -> None:
        """Verify PHP declare(strict_types=1) gate and Python zero-Any in src/ gate."""
        with RepoTestWorkspace() as ws:
            php_proj = ws.project_dir("php-strict")
            ws.init_project(php_proj, "core,lang:php")
            php_src = php_proj / "src"
            php_src.mkdir(parents=True, exist_ok=True)
            php_file = php_src / "Service.php"
            php_file.write_text("<?php\nnamespace App;\nfinal class Service {}\n", encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "typecheck"], cwd=php_proj, check=False).returncode, 0)

            php_file.write_text(
                "<?php\ndeclare(strict_types=1);\nnamespace App;\nfinal class Service {}\n",
                encoding="utf-8",
            )
            ws.run_cmd(["task", "verify"], cwd=php_proj)

            py_proj = ws.project_dir("py-no-any")
            ws.init_project(py_proj, "core,lang:python")
            py_src = py_proj / "src"
            py_src.mkdir(parents=True, exist_ok=True)
            bad_py = py_src / "handler.py"
            any_sig = "def handle(payload: " + "Any) -> None:\n    return None\n"
            bad_py.write_text(any_sig, encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "typecheck"], cwd=py_proj, check=False).returncode, 0)


if __name__ == "__main__":
    unittest.main()
