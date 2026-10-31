#!/usr/bin/env bash
# =============================================================================
# validate-python.sh — Python Structural & Modularity Gate (lang:python)
# Enforces Geranium Quality Fortress:
#   1. File length <= 256 lines per .py file
#   2. uv-only dependency management (bans Pipfile, poetry.lock, setup.py)
#   3. Zero raw print() in src/
#   4. Zero vague variable assignments (data, res, temp, info) in src/
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

# 1. uv-only package management check
for legacy_file in "Pipfile" "Pipfile.lock" "poetry.lock" "setup.py"; do
  if [[ -f "${ROOT_DIR}/${legacy_file}" ]]; then
    echo "❌ [PYTHON GATE] Legacy package manager file '${legacy_file}' detected. Manage all dependencies exclusively with 'uv' (pyproject.toml + uv.lock)." >&2
    ERRORS=$((ERRORS + 1))
  fi
done

# 2. Scan Python files
while IFS= read -r -d '' py_file; do
  # Check 2a: Max 256 lines per .py file
  line_count="$(wc -l < "${py_file}")"
  if [[ "${line_count}" -gt 256 ]]; then
    echo "❌ [PYTHON GATE] ${py_file}: File has ${line_count} lines (maximum allowed is 256 lines). Split into smaller, single-responsibility modules." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # Checks 2b & 2c apply to production source code under src/
  if [[ "${py_file}" == *"/src/"* || "${py_file}" == "src/"* ]]; then
    # Check 2b: Zero raw print() in src/
    if grep -nE '(^|[^a-zA-Z0-9_])print\s*\(' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [PYTHON GATE] ${py_file}: Raw print() call in src/. Use logging.getLogger(__name__) instead." >&2
      ERRORS=$((ERRORS + 1))
    fi

    # Check 2c: Zero vague variable names (data, res, temp, info) in src/
    if grep -nE '^\s*(data|res|temp|info)\s*(:[^=]+)?=' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [PYTHON GATE] ${py_file}: Vague variable name ('data', 'res', 'temp', or 'info') assigned in src/. Use a descriptive domain identifier." >&2
      ERRORS=$((ERRORS + 1))
    fi

    # Check 2d: Zero explicit 'Any' type annotations in src/
    if grep -nE '(:\s*Any\b|->\s*Any\b)' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [PYTHON GATE] ${py_file}: Explicit 'Any' type annotation in src/ is forbidden. Use concrete types, TypeVar, Protocol, or object." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" -o -name ".git" -o -name ".mypy_cache" -o -name ".ruff_cache" -o -name ".pytest_cache" -o -name "mutants" -o -name "build" -o -name "dist" \) -prune \
  -o -type f -name "*.py" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [PYTHON GATE] Failed with ${ERRORS} architectural violation(s)." >&2
  exit 1
fi

echo "✅ [PYTHON GATE] Python modularity & uv architectural gates passed."
