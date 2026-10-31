"""Parallel & content-hash cached unittest runner for fast pre-commit and CI execution."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE_FILE = REPO_ROOT / ".cache" / "unittest" / "results.json"


def _compute_repo_fingerprint() -> str:
    """Compute a fast SHA-256 digest of all root configs, modules/, scripts/, and tests/helpers.py."""
    hasher = hashlib.sha256()
    tracked_roots = [
        REPO_ROOT / "Taskfile.yml",
        REPO_ROOT / "mise.toml",
        REPO_ROOT / "ruff.toml",
        REPO_ROOT / "pyproject.toml",
        REPO_ROOT / "copier.yml",
        REPO_ROOT / "AGENTS.md",
        REPO_ROOT / "README.md",
        REPO_ROOT / ".gitignore",
        REPO_ROOT / ".gitattributes",
        REPO_ROOT / ".guardrails.lock",
        REPO_ROOT / ".guardrails",
        REPO_ROOT / ".agents",
        REPO_ROOT / "modules",
        REPO_ROOT / "scripts",
        REPO_ROOT / "tests" / "helpers.py",
    ]
    for root in tracked_roots:
        if root.is_file():
            hasher.update(str(root.relative_to(REPO_ROOT)).encode("utf-8"))
            hasher.update(root.read_bytes())
        elif root.is_dir():
            for path in sorted(root.rglob("*")):
                if path.is_file():
                    hasher.update(str(path.relative_to(REPO_ROOT)).encode("utf-8"))
                    hasher.update(path.read_bytes())
    return hasher.hexdigest()


def _file_digest(path: Path, repo_fp: str) -> str:
    """Combine repository fingerprint with the specific test file's SHA-256."""
    hasher = hashlib.sha256(repo_fp.encode("utf-8"))
    hasher.update(path.read_bytes())
    return hasher.hexdigest()


def _run_single_test_file(test_file: Path) -> tuple[str, int, str]:
    """Execute a single unittest module in a subprocess and return (name, code, output)."""
    mod_name = f"tests.{test_file.stem}"
    proc = subprocess.run(
        [sys.executable, "-m", "unittest", mod_name, "-v"],
        cwd=str(REPO_ROOT),
        text=True,
        capture_output=True,
        check=False,
    )
    return (test_file.name, proc.returncode, proc.stdout + proc.stderr)


def _load_cache(use_cache: bool) -> dict[str, str]:
    """Load cached test digests from disk when caching is enabled."""
    if not use_cache or not CACHE_FILE.is_file():
        return {}
    try:
        loaded: dict[str, str] = json.loads(CACHE_FILE.read_text(encoding="utf-8"))
        return loaded
    except ValueError:
        return {}


def _execute_pending(
    pending: list[tuple[Path, str]],
    cache_data: dict[str, str],
) -> int:
    """Run uncached test files across worker processes and update cache_data."""
    if not pending:
        return 0
    failures = 0
    max_workers = min(len(pending), os.cpu_count() or 4)
    with ProcessPoolExecutor(max_workers=max_workers) as pool:
        future_map = {pool.submit(_run_single_test_file, tf): (tf, dg) for tf, dg in pending}
        for fut in as_completed(future_map):
            _, dg = future_map[fut]
            name, code, output = fut.result()
            if code == 0:
                cache_data[name] = dg
                sys.stdout.write(f"PASS {name}\n")
            else:
                failures += 1
                sys.stderr.write(f"FAIL {name}\n{output}\n")
    return failures


def main() -> int:
    """Run all test_*.py modules in parallel with content-addressable caching."""
    start = time.monotonic()
    test_files = sorted((REPO_ROOT / "tests").glob("test_*.py"))
    repo_fp = _compute_repo_fingerprint()
    use_cache = os.environ.get("GUARDRAILS_NO_CACHE", "0") != "1"
    cache_data = _load_cache(use_cache)

    pending = [
        (tf, _file_digest(tf, repo_fp))
        for tf in test_files
        if not (use_cache and cache_data.get(tf.name) == _file_digest(tf, repo_fp))
    ]
    cached_hits = len(test_files) - len(pending)
    failures = _execute_pending(pending, cache_data)

    if failures == 0 and use_cache:
        CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        CACHE_FILE.write_text(json.dumps(cache_data, indent=2, sort_keys=True), encoding="utf-8")

    elapsed = time.monotonic() - start
    sys.stdout.write(
        f"Ran {len(test_files)} test module(s) ({cached_hits} cached, {len(pending)} executed) in {elapsed:.2f}s\n"
    )
    return 1 if failures > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
