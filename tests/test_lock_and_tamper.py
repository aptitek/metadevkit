"""Tests for SHA-256 config lock (.guardrails.lock), anti-tamper, and Taskfile.local.yml."""

from __future__ import annotations

import unittest

from tests.helpers import RepoTestWorkspace


class LockAndTamperTests(unittest.TestCase):
    """Verify SHA-256 configuration lock, tamper detection, and self-healing sync."""

    def test_lock_verification_and_illegal_tamper_detection(self) -> None:
        """Verify guard:check blocks manual edits to eslint.config.mjs and guard:sync heals."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("lock-app")
            ws.init_project(proj, "core,lang:ts,fw:react")
            ws.run_cmd(["task", "guard:check"], cwd=proj)

            eslint_cfg = proj / "eslint.config.mjs"
            eslint_cfg.write_text(
                eslint_cfg.read_text(encoding="utf-8") + "\n// manual tamper\n",
                encoding="utf-8",
            )
            tamper_proc = ws.run_cmd(["task", "guard:check"], cwd=proj, check=False)
            self.assertNotEqual(tamper_proc.returncode, 0)
            self.assertIn("eslint.config.mjs", tamper_proc.stderr + tamper_proc.stdout)

            ws.run_cmd(["task", "guard:sync"], cwd=proj)
            ws.run_cmd(["task", "guard:check"], cwd=proj)

    def test_taskfile_local_security_boundaries(self) -> None:
        """Verify Taskfile.local.yml cannot override guard:check or verify."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("local-override-app")
            ws.init_project(proj, "core,lang:ts")
            local_tf = proj / "Taskfile.local.yml"
            local_tf.write_text(
                "version: '3'\ntasks:\n  guard:check:\n    cmds:\n      - echo bypassed\n",
                encoding="utf-8",
            )
            bad_proc = ws.run_cmd(["task", "guard:check"], cwd=proj, check=False)
            self.assertNotEqual(bad_proc.returncode, 0)

            local_tf.write_text(
                "version: '3'\ntasks:\n  custom:hello:\n    cmds:\n      - echo ok\n",
                encoding="utf-8",
            )
            ws.run_cmd(["task", "guard:check"], cwd=proj)


if __name__ == "__main__":
    unittest.main()
