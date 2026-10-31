"""Tests for lang:shell and addon:devkit self-governance ('Who Guards the Guardians')."""

from __future__ import annotations

import unittest
from pathlib import Path

from tests.helpers import REPO_ROOT, RepoTestWorkspace


def _assert_dynamic_agents_and_taskfile(test_case: unittest.TestCase, proj: Path) -> None:
    """Verify AGENTS.md and Taskfile.yml only contain active shell+docker fragments."""
    agents_text = (proj / "AGENTS.md").read_text(encoding="utf-8")
    test_case.assertIn("`lang:shell`", agents_text)
    test_case.assertIn("`addon:docker`", agents_text)
    for inactive_term in ("Minecraft", "Symfony", "Lock 2 (`fw:react`", "commitlint.config.mjs"):
        test_case.assertNotIn(inactive_term, agents_text)

    taskfile_text = (proj / "Taskfile.yml").read_text(encoding="utf-8")
    test_case.assertIn("Taskfile.shell.yml", taskfile_text)
    test_case.assertIn("Taskfile.docker.yml", taskfile_text)
    for inactive_tf in ("Taskfile.ts.yml", "Taskfile.python.yml", "Taskfile.minecraft.yml"):
        test_case.assertNotIn(inactive_tf, taskfile_text)


class DevkitSelfGovernanceTests(unittest.TestCase):
    """Verify that metadevkit passes its own shell, python, and devkit gates."""

    def test_repository_passes_shell_python_and_devkit_validators(self) -> None:
        """Run validate-shell.sh, validate-python.sh, validate-devkit.sh, lint, and typecheck on REPO_ROOT."""
        with RepoTestWorkspace(fixture_mode=False) as ws:
            shell_script = REPO_ROOT / "modules/lang/shell/files/.guardrails/scripts/validate-shell.sh"
            py_script = REPO_ROOT / "modules/lang/python/files/.guardrails/scripts/validate-python.sh"
            devkit_script = REPO_ROOT / "modules/addons/devkit/files/.guardrails/scripts/validate-devkit.sh"

            ws.run_cmd(["bash", str(shell_script), str(REPO_ROOT)], cwd=REPO_ROOT)
            ws.run_cmd(["bash", str(py_script), str(REPO_ROOT)], cwd=REPO_ROOT)
            ws.run_cmd(["bash", str(devkit_script), str(REPO_ROOT)], cwd=REPO_ROOT)
            ws.run_cmd(["task", "lint"], cwd=REPO_ROOT)
            ws.run_cmd(["task", "typecheck"], cwd=REPO_ROOT)

            self.assertEqual(
                ws.read_manifest_modules(REPO_ROOT),
                ["core", "lang:python", "lang:shell", "addon:devkit"],
            )
            self.assertFalse((REPO_ROOT / "rules").exists())
            self.assertFalse((REPO_ROOT / "playwright.config.ts").exists())
            self.assertFalse((REPO_ROOT / "stryker.config.mjs").exists())

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

    def test_lightweight_shell_docker_stack_and_composable_gitignore(self) -> None:
        """Verify shell+docker projects have zero Node/Python in mise.toml and compose .gitignore."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("mini-shell-docker")
            ws.init_project(proj, "core,lang:shell,addon:docker")

            mise_text = (proj / "mise.toml").read_text(encoding="utf-8")
            for forbidden_runtime in ("node", "python", "npm:", "pipx:"):
                self.assertNotIn(forbidden_runtime, mise_text)

            for js_cfg in ("commitlint.config.mjs", ".secretlintrc.json", ".jscpd.json", "playwright.config.ts"):
                self.assertFalse((proj / js_cfg).exists())

            gitignore_text = (proj / ".gitignore").read_text(encoding="utf-8")
            self.assertIn("# --- Module: core ---", gitignore_text)
            self.assertIn("# --- Module: lang:shell ---", gitignore_text)
            self.assertIn("# --- Module: addon:docker ---", gitignore_text)
            _assert_dynamic_agents_and_taskfile(self, proj)

            (proj / ".gitignore.local").write_text("custom-build-dir/\n", encoding="utf-8")
            ws.run_cmd(["task", "guard:sync"], cwd=proj)
            self.assertIn("custom-build-dir/", (proj / ".gitignore").read_text(encoding="utf-8"))

            dockerfile = proj / "Dockerfile"
            dockerfile.write_text("FROM alpine:latest\n", encoding="utf-8")
            self.assertNotEqual(ws.run_cmd(["task", "lint"], cwd=proj, check=False).returncode, 0)

            dockerfile.write_text("FROM alpine:3.21\nUSER appuser\n", encoding="utf-8")
            ws.run_cmd(["task", "verify"], cwd=proj)

    def test_standalone_taskfile_and_bootstrap_script(self) -> None:
        """Verify downloading only Taskfile.yml or running scripts/bootstrap.sh initializes a project."""
        with RepoTestWorkspace() as ws:
            standalone = ws.project_dir("standalone-tf")
            (standalone / "Taskfile.yml").write_text(
                (REPO_ROOT / "Taskfile.yml").read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            ws.run_cmd(
                ["task", "init", "MODULES=core,lang:shell", f"REPO_URL={REPO_ROOT}"],
                cwd=standalone,
            )
            self.assertEqual(ws.read_manifest_modules(standalone), ["core", "lang:shell"])
            self.assertTrue((standalone / ".gitattributes").is_file())
            ws.run_cmd(
                ["task", "init", "MODULES=core,lang:shell,addon:docker", f"REPO_URL={REPO_ROOT}"],
                cwd=standalone,
            )
            self.assertEqual(ws.read_manifest_modules(standalone), ["core", "lang:shell", "addon:docker"])
            ws.run_cmd(["task", "verify"], cwd=standalone)

            boot_dir = ws.project_dir("boot-script-app")
            (boot_dir / "Taskfile.yml").write_text(
                (REPO_ROOT / "Taskfile.yml").read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            boot_sh = REPO_ROOT / "scripts" / "bootstrap.sh"
            ws.run_cmd(
                ["bash", "-c", f'REPO_URL="{REPO_ROOT}" bash -s -- "shell,docker" < "{boot_sh}"'],
                cwd=boot_dir,
            )
            self.assertEqual(ws.read_manifest_modules(boot_dir), ["core", "lang:shell", "addon:docker"])
            ws.run_cmd(["task", "guard:check"], cwd=boot_dir)


if __name__ == "__main__":
    unittest.main()
