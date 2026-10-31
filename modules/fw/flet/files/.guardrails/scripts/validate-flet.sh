#!/usr/bin/env bash
# =============================================================================
# validate-flet.sh — Flet Material Design 3 & 5-Level Atomic Design Gate (fw:flet)
# Enforces:
#   1. Zero hardcoded hex (#RRGGBB) or raw named color strings in ui/ (use ft.Colors.*)
#   2. Zero deprecated ft.UserControl, ft.colors.*, or ft.icons.*
#   3. 5-Level Atomic Design unidirectional imports (atoms -> molecules -> organisms -> templates -> views)
#   4. Zero direct AI/TTS SDK imports inside ui/
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

while IFS= read -r -d '' py_file; do
  base_name="$(basename "${py_file}")"

  # 1. Modern Flet API check (no deprecated UserControl, ft.colors, ft.icons)
  if grep -nE '\b(ft\.UserControl|UserControl)\b' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
    echo "❌ [FLET API GATE] ${py_file}: Deprecated ft.UserControl detected. Subclass ft.Container, ft.Row, or ft.Column directly." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -nE '\bft\.(colors|icons)\.' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
    echo "❌ [FLET API GATE] ${py_file}: Deprecated lowercase ft.colors/ft.icons detected. Use PascalCase enums ft.Colors.* and ft.Icons.*." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 2. MD3 Token Purity (applies to all ui/ files except theme.py)
  if [[ "${base_name}" != "theme.py" ]]; then
    if grep -nE '(^|[^a-zA-Z0-9_])(color|bgcolor|icon_color|border_color)\s*=\s*["'\'']#[0-9a-fA-F]{3,8}["'\'']' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [FLET MD3 GATE] ${py_file}: Hardcoded hex color detected in UI control. Use Material Design 3 semantic tokens (e.g., ft.Colors.PRIMARY, ft.Colors.SURFACE, ft.Colors.ON_SURFACE_VARIANT) defined via theme.py." >&2
      ERRORS=$((ERRORS + 1))
    fi

    if grep -nEi '(^|[^a-zA-Z0-9_])(color|bgcolor|icon_color|border_color)\s*=\s*["'\''](pink|red|blue|green|white|black|grey|gray|yellow|purple|orange|cyan|teal)["'\'']' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [FLET MD3 GATE] ${py_file}: Raw named color string detected in UI control. Use Material Design 3 semantic tokens (ft.Colors.*)." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # 3. Direct AI/TTS SDK import check inside ui/
  if grep -nE '^\s*(from|import)\s+(langchain|langchain_google_genai|langgraph|google\.cloud\.texttospeech|mcp)(\.| |\b)' "${py_file}" >/dev/null 2>&1; then
    echo "❌ [FLET ARCHITECTURE GATE] ${py_file}: Direct AI/TTS/MCP SDK import inside ui/. UI components must delegate orchestration via callbacks/services." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 4. 5-Level Atomic Design Hierarchy Check
  if [[ "${py_file}" == *"/ui/atoms/"* ]]; then
    if grep -nE '^\s*(from|import)\s+.*\b(molecules|organisms|templates|views)\b' "${py_file}" >/dev/null 2>&1; then
      echo "❌ [FLET ATOMIC GATE] ${py_file}: Atom cannot import from higher Atomic layers (molecules, organisms, templates, or views)." >&2
      ERRORS=$((ERRORS + 1))
    fi
  elif [[ "${py_file}" == *"/ui/molecules/"* ]]; then
    if grep -nE '^\s*(from|import)\s+.*\b(organisms|templates|views)\b' "${py_file}" >/dev/null 2>&1; then
      echo "❌ [FLET ATOMIC GATE] ${py_file}: Molecule cannot import from higher Atomic layers (organisms, templates, or views)." >&2
      ERRORS=$((ERRORS + 1))
    fi
  elif [[ "${py_file}" == *"/ui/organisms/"* ]]; then
    if grep -nE '^\s*(from|import)\s+.*\b(templates|views)\b' "${py_file}" >/dev/null 2>&1; then
      echo "❌ [FLET ATOMIC GATE] ${py_file}: Organism cannot import from higher Atomic layers (templates or views)." >&2
      ERRORS=$((ERRORS + 1))
    fi
  elif [[ "${py_file}" == *"/ui/templates/"* ]]; then
    if grep -nE '^\s*(from|import)\s+.*\b(views)\b' "${py_file}" >/dev/null 2>&1; then
      echo "❌ [FLET ATOMIC GATE] ${py_file}: Template cannot import from Views." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" -o -name ".git" \) -prune \
  -o -type f -path "*/ui/*.py" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [FLET GATE] Failed with ${ERRORS} Flet MD3 / Atomic Design violation(s)." >&2
  exit 1
fi

echo "✅ [FLET GATE] Flet Material Design 3 & 5-level Atomic Design checks passed."
