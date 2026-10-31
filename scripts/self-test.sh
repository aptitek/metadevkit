#!/usr/bin/env bash
# =============================================================================
# polyglot-guardrails — End-to-End Automated Test Suite Runner (`task self-test`)
# Executes the modular Python test suite in `tests/` via `uv run pytest`
# (or falls back to standard library `python3 -m unittest` in minimal sandboxes).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${REPO_ROOT}/pyproject.toml" ]] && command -v uv >/dev/null 2>&1 && uv run pytest --version >/dev/null 2>&1; then
  (cd "${REPO_ROOT}" && uv run pytest)
elif command -v pytest >/dev/null 2>&1; then
  (cd "${REPO_ROOT}" && pytest)
else
  (cd "${REPO_ROOT}" && python3 -m unittest discover -s tests -v)
fi
