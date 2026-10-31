#!/usr/bin/env bash
# =============================================================================
# validate-jupyter.sh — Jupyter Notebook Quality & Reproducibility Gate (fw:jupyter)
# Modes:
#   validate-jupyter.sh --strip <dir> : Strip outputs & execution_count from all .ipynb files
#   validate-jupyter.sh <dir>         : Verify all .ipynb files pass quality gates:
#     1. Valid JSON with nbformat >= 4
#     2. Clean Output Gate: all code cells have outputs == [] and execution_count == null
#     3. Reproducibility Gate: zero !pip install / %pip install / %conda install in cells
#     4. Cell Modularity Gate: code cells <= 30 lines (extract larger logic to src/)
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

MODE="check"
if [[ "${1:-}" == "--strip" ]]; then
  MODE="strip"
  shift
fi

ROOT_DIR="${1:-.}"
ERRORS=0

while IFS= read -r -d '' nb_file; do
  # 1. Verify valid JSON
  if ! jq empty "${nb_file}" >/dev/null 2>&1; then
    echo "❌ [JUPYTER GATE] ${nb_file}: Invalid JSON in notebook file." >&2
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if [[ "${MODE}" == "strip" ]]; then
    tmp_file="$(mktemp)"
    jq '(.cells[] | select(.cell_type == "code")) |= (.outputs = [] | .execution_count = null)' "${nb_file}" > "${tmp_file}"
    mv "${tmp_file}" "${nb_file}"
    continue
  fi

  # 2. Check nbformat >= 4
  nbformat_ver="$(jq -r '.nbformat // 0' "${nb_file}")"
  if [[ "${nbformat_ver}" -lt 4 ]]; then
    echo "❌ [JUPYTER GATE] ${nb_file}: nbformat (${nbformat_ver}) must be >= 4." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 3. Clean Output Gate (outputs must be empty and execution_count must be null)
  dirty_cells="$(jq '[.cells[] | select(.cell_type == "code") | select((.outputs | length > 0) or (.execution_count != null))] | length' "${nb_file}")"
  if [[ "${dirty_cells}" -gt 0 ]]; then
    echo "❌ [JUPYTER CLEAN OUTPUT GATE] ${nb_file}: ${dirty_cells} code cell(s) contain unstripped outputs or execution_count. Run 'task format' to strip notebook outputs before committing." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 4. Reproducibility Gate (no !pip / %pip / !conda / %conda / !poetry inside code cells)
  if jq -r '.cells[] | select(.cell_type == "code") | (.source | if type == "array" then join("") else . end)' "${nb_file}" | grep -nE '^\s*[!%](pip|conda|poetry)\s+(install|add)\b' >/dev/null 2>&1; then
    echo "❌ [JUPYTER REPRODUCIBILITY GATE] ${nb_file}: In-cell package installation (!pip/%pip/%conda) is forbidden. Manage all notebook dependencies declaratively via 'uv add' in pyproject.toml." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 5. Cell Modularity Gate (max 30 lines per code cell)
  oversized_cells="$(jq '[.cells[] | select(.cell_type == "code") | (.source | if type == "array" then length else (split("\n") | length) end) | select(. > 30)] | length' "${nb_file}")"
  if [[ "${oversized_cells}" -gt 0 ]]; then
    echo "❌ [JUPYTER MODULARITY GATE] ${nb_file}: ${oversized_cells} code cell(s) exceed 30 lines. Extract reusable logic into typed Python modules under src/ and import them." >&2
    ERRORS=$((ERRORS + 1))
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".venv" -o -name "venv" -o -name ".ipynb_checkpoints" -o -name ".git" -o -name "node_modules" \) -prune \
  -o -type f -name "*.ipynb" -print0)

if [[ "${MODE}" == "strip" ]]; then
  echo "✅ [JUPYTER FORMAT] Stripped outputs and execution counts from all .ipynb notebooks."
  exit 0
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [JUPYTER GATE] Failed with ${ERRORS} Jupyter notebook quality violation(s)." >&2
  exit 1
fi

echo "✅ [JUPYTER GATE] Jupyter notebook reproducibility, clean-output & cell modularity checks passed."
