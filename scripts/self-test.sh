#!/usr/bin/env bash
# =============================================================================
# polyglot-guardrails — End-to-End Automated Test Suite Runner (`task self-test`)
# Executes the modular Python test suite in `tests/` with parallel workers and
# content-addressable caching (.cache/unittest/ & .cache/pytest/).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${REPO_ROOT}/tests/run_parallel.py" ]] && command -v python3 >/dev/null 2>&1; then
  (cd "${REPO_ROOT}" && python3 ./tests/run_parallel.py)
elif [[ -f "${REPO_ROOT}/pyproject.toml" ]] && command -v uv >/dev/null 2>&1 && uv run pytest --version >/dev/null 2>&1; then
  (cd "${REPO_ROOT}" && uv run pytest -o cache_dir=.cache/pytest)
else
  (cd "${REPO_ROOT}" && python3 -m unittest discover -s tests -v)
fi
