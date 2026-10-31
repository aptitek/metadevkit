"""Tests for lang:shell and addon:devkit self-governance ('Who Guards the Guardians')."""

from __future__ import annotations

import unittest

from tests.helpers import REPO_ROOT, RepoTestWorkspace


class DevkitSelfGovernanceTests(unittest.TestCase):
    """Verify that metadevkit passes its own shell, python, and devkit gates."""

    def test_repository_passes_shell_python_and_devkit_validators(self) -> None:
        """Run validate-shell.sh, validate-python.sh, and validate-devkit.sh on REPO_ROOT."""
        with RepoTestWorkspace() as ws:
            shell_script = REPO_ROOT / "modules/lang/shell/files/.guardrails/scripts/validate-shell.sh"
            py_script = REPO_ROOT / "modules/lang/python/files/.guardrails/scripts/validate-python.sh"
            devkit_script = REPO_ROOT / "modules/addons/devkit/files/.guardrails/scripts/validate-devkit.sh"

            ws.run_cmd(["bash", str(shell_script), str(REPO_ROOT)], cwd=REPO_ROOT)
            ws.run_cmd(["bash", str(py_script), str(REPO_ROOT)], cwd=REPO_ROOT)
            ws.run_cmd(["bash", str(devkit_script), str(REPO_ROOT)], cwd=REPO_ROOT)

    def test_shell_gate_blocks_missing_strict_mode_and_eval(self) -> None:
        """Verify lang:shell rejects scripts lacking set -euo pipefail or using eval."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("shell-app")
            ws.init_project(proj, "core,lang:shell,addon:devkit")
            bad_script = proj / "bad.sh"
            bad_script.write_text("#!/usr/bin/env bash\necho 'missing strict mode'\n", encoding="utf-8")

            proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("set -euo pipefail", proc.stderr + proc.stdout)

            bad_script.write_text("#!/usr/bin/env bash\nset -euo pipefail\neval echo hello\n", encoding="utf-8")
            proc_eval = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(proc_eval.returncode, 0)

            bad_script.unlink()
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_devkit_gate_blocks_oversized_skill_file(self) -> None:
        """Verify addon:devkit rejects SKILL.md files exceeding the 100-line token cap."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("devkit-app")
            ws.init_project(proj, "core,addon:devkit")
            custom_skill_dir = proj / "custom_skills" / "bloated-skill"
            custom_skill_dir.mkdir(parents=True, exist_ok=True)
            lines = ["---", "name: bloated-skill", "description: test", "---"] + [f"line {i}" for i in range(105)]
            (custom_skill_dir / "SKILL.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

            proc = ws.run_cmd(["task", "lint"], cwd=proj, check=False)
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("exceeds 100-line Progressive Disclosure cap", proc.stderr + proc.stdout)


if __name__ == "__main__":
    unittest.main()
