"""Shared test workspace and subprocess helpers for polyglot-guardrails tests."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from types import TracebackType

REPO_ROOT = Path(__file__).resolve().parent.parent


class RepoTestWorkspace:
    """Isolated temporary workspace with `task` binary wired into PATH."""

    def __init__(self, fixture_mode: bool = True) -> None:
        self._tmp_dir = Path(tempfile.mkdtemp(prefix="guardrails-test-"))
        self.bin_dir = self._tmp_dir / ".bin"
        self.bin_dir.mkdir(parents=True, exist_ok=True)
        self._env = dict(os.environ)
        self._setup_task_binary(fixture_mode=fixture_mode)

    def _setup_task_binary(self, fixture_mode: bool) -> None:
        task_bin = shutil.which("task") or shutil.which("go-task")
        if not task_bin:
            raise RuntimeError("Neither 'task' nor 'go-task' found in PATH.")
        symlink_path = self.bin_dir / "task"
        if not symlink_path.exists():
            symlink_path.symlink_to(Path(task_bin))
        self._env["PATH"] = f"{self.bin_dir}:{self._env.get('PATH', '')}"
        self._env.pop("UV_PROJECT_ENVIRONMENT", None)
        if not shutil.which("uv", path=self._env["PATH"]):
            tmp_root = Path(tempfile.gettempdir())
            mise_shims = tmp_root / "mise-data" / "shims"
            self._env["MISE_DATA_DIR"] = str(tmp_root / "mise-data")
            self._env["PATH"] = f"{mise_shims}:{self._env['PATH']}"
            self._env.setdefault("UV_CACHE_DIR", str(tmp_root / "uv-cache"))
        if self._env.get("UV_CACHE_DIR") == ".cache/uv":
            self._env["UV_CACHE_DIR"] = str((REPO_ROOT / ".cache" / "uv").resolve())
        self._env.update(
            {
                "UV_PYTHON": sys.executable,
                "UV_LINK_MODE": "copy",
                "PYTHONDONTWRITEBYTECODE": "1",
                "GUARDRAILS_SKIP_SELFTEST": "1",
                "GUARDRAILS_FIXTURE_MODE": "1" if fixture_mode else "0",
            }
        )

    @property
    def root(self) -> Path:
        """Return the root path of the temporary workspace."""
        return self._tmp_dir

    def project_dir(self, name: str) -> Path:
        """Create and return a subdirectory inside the temporary workspace."""
        target = self._tmp_dir / name
        target.mkdir(parents=True, exist_ok=True)
        return target

    def run_cmd(
        self,
        args: list[str],
        cwd: Path | None = None,
        check: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        """Execute a command inside the isolated workspace environment."""
        return subprocess.run(
            args,
            cwd=str(cwd or self._tmp_dir),
            env=self._env,
            text=True,
            capture_output=True,
            check=check,
        )

    def init_project(self, target: Path, modules_csv: str) -> subprocess.CompletedProcess[str]:
        """Initialize a target project with the specified comma-separated modules."""
        cli_script = REPO_ROOT / "modules" / "core" / "files" / ".guardrails" / "scripts" / "guardrails-cli.sh"
        return self.run_cmd(
            [
                "bash",
                str(cli_script),
                "init",
                "--target",
                str(target),
                "--source",
                str(REPO_ROOT),
                "--modules",
                modules_csv,
            ]
        )

    def read_manifest_modules(self, target: Path) -> list[str]:
        """Return the list of active modules from .guardrails/manifest.json."""
        manifest_path = target / ".guardrails" / "manifest.json"
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
        return list(payload["modules"])

    def cleanup(self) -> None:
        """Remove the temporary workspace directory."""
        shutil.rmtree(self._tmp_dir, ignore_errors=True)

    def __enter__(self) -> RepoTestWorkspace:
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> None:
        self.cleanup()
