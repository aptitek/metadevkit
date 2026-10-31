"""Tests for Python (uv) + Flet MD3 + NiceGUI + LangChain + Jupyter (fw:jupyter) stack."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace


def _write_dirty_notebook(nb_path: Path) -> None:
    """Create a Jupyter notebook containing unstripped cell outputs."""
    nb_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "cells": [
            {
                "cell_type": "code",
                "execution_count": 3,
                "metadata": {},
                "outputs": [{"name": "stdout", "output_type": "stream", "text": ["secret\n"]}],
                "source": ["sample_rate = 48000\n"],
            }
        ],
        "metadata": {},
        "nbformat": 4,
        "nbformat_minor": 5,
    }
    nb_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def _assert_flet_nicegui_langchain_violations_blocked(
    test_case: unittest.TestCase,
    ws: RepoTestWorkspace,
    proj: Path,
) -> None:
    """Verify Flet hex colors, NiceGUI time.sleep, and legacy LLMChain are blocked."""
    atoms_dir = proj / "src" / "geranium" / "ui" / "atoms"
    atoms_dir.mkdir(parents=True, exist_ok=True)
    bad_atom = atoms_dir / "bad_button.py"
    bad_atom.write_text('def make_btn() -> dict[str, str]:\n    return dict(color="#FF0055")\n')
    test_case.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
    bad_atom.unlink()

    pages_dir = proj / "src" / "geranium" / "ui" / "pages"
    pages_dir.mkdir(parents=True, exist_ok=True)
    bad_page = pages_dir / "bad_page.py"
    bad_page.write_text("import time\ndef on_click() -> None:\n    time.sleep(1)\n")
    test_case.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
    bad_page.unlink()

    agents_dir = proj / "src" / "geranium" / "agents"
    agents_dir.mkdir(parents=True, exist_ok=True)
    bad_chain = agents_dir / "bad_chain.py"
    bad_chain.write_text("def build(p: object, m: object) -> object:\n    return LLMChain(prompt=p, llm=m)\n")
    test_case.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)
    bad_chain.unlink()


class PythonAiJupyterStackTests(unittest.TestCase):
    """Verify Flet MD3, NiceGUI async, LangChain LCEL, and Jupyter Clean Output gates."""

    def test_python_flet_nicegui_langchain_and_jupyter_gates(self) -> None:
        """Test violation detection across all 5 Python modules and pass full task verify."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("geranium-studio")
            ws.init_project(proj, "core,lang:python,fw:flet,fw:langchain")
            ws.run_cmd(["task", "feature:add", "--", "nicegui"], cwd=proj)
            ws.run_cmd(["task", "feature:add", "--", "jupyter"], cwd=proj)

            _assert_flet_nicegui_langchain_violations_blocked(self, ws, proj)

            nb_file = proj / "notebooks" / "experiment.ipynb"
            _write_dirty_notebook(nb_file)
            self.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)

            ws.run_cmd(["task", "format"], cwd=proj)
            atoms_dir = proj / "src" / "geranium" / "ui" / "atoms"
            (atoms_dir / "primary_button.py").write_text(
                '"""Compliant Flet atom."""\n\ndef format_label(title: str) -> str:\n    return title.strip()\n'
            )
            ws.run_cmd(["task", "verify"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
