"""Tests for cross-language homogeneity: mutation testing, a11y, i18n, typecheck, coverage, and Lock 6."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace


def _seed_real_python_project(proj: Path) -> Path:
    """Create pyproject.toml, src/calc/ops.py, and initial partial-branch test_ops.py."""
    (proj / "pyproject.toml").write_text(
        '[project]\nname = "real-py-e2e"\nversion = "0.1.0"\nrequires-python = ">=3.12"\n'
        'dependencies = []\n\n[dependency-groups]\ndev = [\n'
        '  "pytest>=8.3.0",\n  "pytest-cov>=6.0.0",\n  "ruff>=0.11.0",\n'
        '  "mypy>=1.15.0",\n  "mutmut>=3.2.0",\n]\n\n'
        '[tool.pytest.ini_options]\npythonpath = ["src"]\ntestpaths = ["tests"]\n'
        '\n[tool.mypy]\npython_version = "3.12"\nstrict = true\nmypath = "src"\n'
    )
    src_dir = proj / "src" / "calc"
    src_dir.mkdir(parents=True, exist_ok=True)
    (src_dir / "__init__.py").write_text('"""Calculation package."""\n')
    (src_dir / "ops.py").write_text(
        '"""Pure arithmetic clamping operations."""\n\n\n'
        "def clamp_positive(val: int) -> int:\n"
        '    """Clamp negative values to zero."""\n'
        "    if val < 0:\n"
        "        return 0\n"
        "    return val\n"
    )
    tests_dir = proj / "tests"
    tests_dir.mkdir(parents=True, exist_ok=True)
    test_file = tests_dir / "test_ops.py"
    test_file.write_text(
        '"""Unit tests for calc.ops."""\n\n'
        "from calc.ops import clamp_positive\n\n\n"
        "def test_clamp_positive_only_one_branch() -> None:\n"
        '    """Cover only the positive branch initially."""\n'
        "    assert clamp_positive(5) == 5\n"
    )
    return test_file


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
                self.assertEqual((proj / "playwright.config.ts").is_file(), "lang:ts" in modules_csv)
                self.assertEqual((proj / "stryker.config.mjs").is_file(), "lang:ts" in modules_csv)
                for gate in ("typecheck", "a11y", "i18n", "coverage", "mutate", "verify"):
                    ws.run_cmd(["task", gate], cwd=proj)

    def test_i18n_locale_parity_and_minecraft_screen_narrator(self) -> None:
        """Verify validate-i18n-and-a11y.sh catches locale key drift and Screen literals when fw:minecraft active."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("i18n-app")
            ws.init_project(proj, "core,lang:python,fw:flet")

            locales_dir = proj / "locales"
            locales_dir.mkdir(parents=True, exist_ok=True)
            (locales_dir / "en.json").write_text(json.dumps({"app": {"title": "Studio", "save": "Save"}}))
            (locales_dir / "fr.json").write_text(json.dumps({"app": {"title": "Studio"}}))
            drift_proc = ws.run_cmd(["task", "i18n"], cwd=proj, check=False)
            self.assertIn("Locale key mismatch", drift_proc.stderr + drift_proc.stdout)

            (locales_dir / "fr.json").write_text(json.dumps({"app": {"title": "Studio", "save": "Enregistrer"}}))
            ws.run_cmd(["task", "i18n"], cwd=proj)

            bad_screen = proj / "src" / "main" / "kotlin" / "ConfigScreen.kt"
            bad_screen.parent.mkdir(parents=True, exist_ok=True)
            bad_screen.write_text('class ConfigScreen { val t = Component.' + 'literal("Hardcoded") }\n')
            self.assertEqual(ws.run_cmd(["task", "i18n"], cwd=proj, check=False).returncode, 0)
            ws.run_cmd(["task", "feature:add", "--", "minecraft"], cwd=proj)
            self.assertNotEqual(ws.run_cmd(["task", "i18n"], cwd=proj, check=False).returncode, 0)

    def test_a11y_flet_iconbutton_tooltip_gate(self) -> None:
        """Verify Flet IconButton without tooltip is rejected by task a11y."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("a11y-app")
            ws.init_project(proj, "core,lang:python,fw:flet")
            ui_dir = proj / "src" / "studio" / "ui" / "atoms"
            ui_dir.mkdir(parents=True, exist_ok=True)
            bad_btn = ui_dir / "icon_btn.py"
            bad_btn.write_text("def render_icon(ft: object) -> object:\n    return ft.IconButton(icon='add')\n")
            a11y_proc = ws.run_cmd(["task", "a11y"], cwd=proj, check=False)
            self.assertNotEqual(a11y_proc.returncode, 0)
            self.assertIn("tooltip=", a11y_proc.stderr + a11y_proc.stdout)

            bad_btn.write_text(
                "def render_icon(ft: object) -> object:\n    return ft.IconButton(icon='add', tooltip='Add item')\n"
            )
            ws.run_cmd(["task", "a11y"], cwd=proj)

    def test_testing_fortress_blocks_skipped_and_tautological_tests_across_languages(self) -> None:
        """Verify Lock 6 blocks skipped and tautological tests in Python, Kotlin, and PHP."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("fortress-polyglot")
            ws.init_project(proj, "core,lang:python,addon:testing-fortress")
            for rel_path, bad_code in (
                ("tests/test_bad.py", "def test_tautology() -> None:\n    assert " + "True\n"),
                ("src/test/kotlin/SampleTest.kt", "@" + "Disabled\nclass SampleTest\n"),
                ("tests/SampleTest.php", "<?php\ndeclare(strict_types=1);\nit('skips')->" + "skip();\n"),
            ):
                target = proj / rel_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(bad_code)
                self.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
                target.unlink()
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_php_strict_types_and_python_no_any_gates(self) -> None:
        """Verify PHP declare(strict_types=1) gate and Python zero-Any in src/ gate."""
        with RepoTestWorkspace() as ws:
            php_proj = ws.project_dir("php-strict")
            ws.init_project(php_proj, "core,lang:php")
            php_src = php_proj / "src"
            php_src.mkdir(parents=True, exist_ok=True)
            php_file = php_src / "Service.php"
            php_file.write_text("<?php\nnamespace App;\nfinal class Service {}\n")
            self.assertNotEqual(ws.run_cmd(["task", "typecheck"], cwd=php_proj, check=False).returncode, 0)

            php_file.write_text("<?php\ndeclare(strict_types=1);\nnamespace App;\nfinal class Service {}\n")
            ws.run_cmd(["task", "verify"], cwd=php_proj)

            py_proj = ws.project_dir("py-no-any")
            ws.init_project(py_proj, "core,lang:python")
            ruff_text = (py_proj / "ruff.toml").read_text(encoding="utf-8")
            self.assertIn(".guardrails/python/ruff.base.toml", ruff_text)
            self.assertNotIn('"DJ"', ruff_text)
            py_src = py_proj / "src"
            py_src.mkdir(parents=True, exist_ok=True)
            (py_src / "handler.py").write_text("def handle(payload: " + "Any) -> None:\n    return None\n")
            self.assertNotEqual(ws.run_cmd(["task", "typecheck"], cwd=py_proj, check=False).returncode, 0)

    def test_fail_closed_when_project_file_or_binary_missing(self) -> None:
        """Verify task test, coverage, mutate, and verify fail closed when GUARDRAILS_FIXTURE_MODE=0."""
        with RepoTestWorkspace(fixture_mode=False) as ws:
            for name, mod in (
                ("fc-ts", "core,lang:ts"),
                ("fc-py", "core,lang:python"),
                ("fc-java", "core,lang:java"),
                ("fc-kt", "core,lang:kotlin"),
                ("fc-php", "core,lang:php"),
            ):
                proj = ws.project_dir(name)
                ws.init_project(proj, mod)
                for gate in ("test", "coverage", "mutate", "verify"):
                    proc = ws.run_cmd(["task", gate], cwd=proj, check=False)
                    self.assertNotEqual(proc.returncode, 0, f"Expected fail-closed for {gate} in {name}")

    def test_real_python_uv_pytest_and_coverage_execution(self) -> None:
        """Run real uv + ruff + mypy + pytest + pytest-cov + mutmut via task verify with fixture_mode=False."""
        with RepoTestWorkspace(fixture_mode=False) as ws:
            proj = ws.project_dir("real-py-e2e")
            ws.init_project(proj, "core,lang:python")
            test_file = _seed_real_python_project(proj)

            self.assertEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
            self.assertEqual(ws.run_cmd(["task", "typecheck"], cwd=proj, check=False).returncode, 0)
            self.assertEqual(ws.run_cmd(["task", "test"], cwd=proj, check=False).returncode, 0)
            self.assertNotEqual(ws.run_cmd(["task", "coverage"], cwd=proj, check=False).returncode, 0)

            test_file.write_text(
                '"""Unit tests for calc.ops."""\n\n'
                "from calc.ops import clamp_positive\n\n\n"
                "def test_clamp_positive_all_branches_and_boundaries() -> None:\n"
                '    """Cover positive, zero, and negative branches."""\n'
                "    assert clamp_positive(5) == 5\n"
                "    assert clamp_positive(0) == 0\n"
                "    assert clamp_positive(-3) == 0\n"
            )
            self.assertEqual(ws.run_cmd(["task", "coverage"], cwd=proj, check=False).returncode, 0)
            verify_ok = ws.run_cmd(["task", "verify"], cwd=proj, check=False)
            self.assertEqual(verify_ok.returncode, 0, verify_ok.stderr + verify_ok.stdout)


if __name__ == "__main__":
    unittest.main()
