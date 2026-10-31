#!/usr/bin/env bash
# =============================================================================
# validate-nicegui.sh — NiceGUI Event-Loop & Atomic UI Architecture Gate (fw:nicegui)
# Enforces:
#   1. Zero blocking time.sleep() in src/ (use await asyncio.sleep or run.io_bound)
#   2. Zero synchronous requests.get/post/put/delete in src/ (use httpx.AsyncClient or run.io_bound)
#   3. ui.run() restricted to main.py / app.py entrypoint
#   4. Atomic UI hierarchy boundaries in ui/ (atoms -> molecules -> organisms -> pages/views)
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

while IFS= read -r -d '' py_file; do
  base_name="$(basename "${py_file}")"

  # 1. Blocking time.sleep check in src/
  if [[ "${py_file}" == *"/src/"* || "${py_file}" == "src/"* ]]; then
    if grep -nE '(^|[^a-zA-Z0-9_])time\.sleep\s*\(' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [NICEGUI ASYNC GATE] ${py_file}: Blocking time.sleep() detected in src/. Use 'await asyncio.sleep(...)' or 'await run.io_bound(...)' to avoid freezing the NiceGUI event loop." >&2
      ERRORS=$((ERRORS + 1))
    fi

    # 2. Blocking requests.* check in src/
    if grep -nE '(^|[^a-zA-Z0-9_])requests\.(get|post|put|delete|patch|request)\s*\(' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [NICEGUI ASYNC GATE] ${py_file}: Synchronous requests.* call detected in src/. Use 'httpx.AsyncClient' or 'await run.io_bound(...)'." >&2
      ERRORS=$((ERRORS + 1))
    fi

    # 3. ui.run() restricted to entrypoint
    if [[ "${base_name}" != "main.py" && "${base_name}" != "app.py" && "${base_name}" != "__main__.py" ]]; then
      if grep -nE '(^|[^a-zA-Z0-9_])ui\.run\s*\(' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
        echo "❌ [NICEGUI ARCHITECTURE GATE] ${py_file}: ui.run() called outside main.py/app.py entrypoint." >&2
        ERRORS=$((ERRORS + 1))
      fi
    fi
  fi

  # 4. Atomic UI hierarchy checks
  if [[ "${py_file}" == *"/ui/atoms/"* ]]; then
    if grep -nE '^\s*(from|import)\s+.*\b(molecules|organisms|templates|pages|views)\b' "${py_file}" >/dev/null 2>&1; then
      echo "❌ [NICEGUI ATOMIC GATE] ${py_file}: Atom cannot import from higher layers (molecules, organisms, templates, pages, or views)." >&2
      ERRORS=$((ERRORS + 1))
    fi
  elif [[ "${py_file}" == *"/ui/molecules/"* ]]; then
    if grep -nE '^\s*(from|import)\s+.*\b(organisms|templates|pages|views)\b' "${py_file}" >/dev/null 2>&1; then
      echo "❌ [NICEGUI ATOMIC GATE] ${py_file}: Molecule cannot import from higher layers (organisms, templates, pages, or views)." >&2
      ERRORS=$((ERRORS + 1))
    fi
  elif [[ "${py_file}" == *"/ui/organisms/"* ]]; then
    if grep -nE '^\s*(from|import)\s+.*\b(templates|pages|views)\b' "${py_file}" >/dev/null 2>&1; then
      echo "❌ [NICEGUI ATOMIC GATE] ${py_file}: Organism cannot import from higher layers (templates, pages, or views)." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" -o -name ".git" \) -prune \
  -o -type f -name "*.py" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [NICEGUI GATE] Failed with ${ERRORS} NiceGUI architectural violation(s)." >&2
  exit 1
fi

echo "✅ [NICEGUI GATE] NiceGUI async event-loop & Atomic UI checks passed."
