#!/usr/bin/env bash
# =============================================================================
# validate-i18n-and-a11y.sh — Universal Polyglot i18n & Accessibility Gate (addon:ui-guardrails)
# Enforces according to active modules in .guardrails/manifest.json:
#   1. i18n Locale Key Parity: All locale JSON files in the same folder (locales/,
#      i18n/, assets/<modid>/lang/) must have 100% identical key sets and zero empty values.
#   2. Web A11y (fw:react / fw:astro): Zero <img> without alt, zero tabIndex > 0, zero autoFocus.
#   3. Flet A11y (fw:flet): Zero ft.IconButton without tooltip=, zero ft.Image without semantics_label/tooltip.
#   4. NiceGUI A11y (fw:nicegui): Zero ui.image without alt/props, zero ui.input without label/placeholder.
#   5. Minecraft A11y & i18n (fw:minecraft): Custom Screen classes must use Component.translatable /
#      Text.translatable (never Component.literal / Text.literal) for Narrator & i18n.
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

MODE="all"
if [[ "${1:-}" == "--i18n" ]]; then
  MODE="i18n"
  shift
elif [[ "${1:-}" == "--a11y" ]]; then
  MODE="a11y"
  shift
fi

ROOT_DIR="${1:-.}"
MANIFEST_FILE="${ROOT_DIR}/.guardrails/manifest.json"
ERRORS=0

has_module() {
  local mod="$1"
  [[ -f "${MANIFEST_FILE}" ]] && jq -e --arg m "${mod}" '.modules | index($m) != null' "${MANIFEST_FILE}" >/dev/null 2>&1
}

check_locale_dir_parity() {
  local dir_path="$1"
  local -a json_files=()
  while IFS= read -r -d '' jf; do
    json_files+=("${jf}")
  done < <(find "${dir_path}" -maxdepth 1 -type f -name "*.json" -print0 | sort -z)

  if [[ "${#json_files[@]}" -eq 0 ]]; then
    return 0
  fi

  local base_file="${json_files[0]}"
  local base_keys
  base_keys="$(jq -r '[paths(scalars) | map(tostring) | join(".")] | sort | .[]' "${base_file}" 2>/dev/null || true)"

  for jf in "${json_files[@]}"; do
    local empty_count
    empty_count="$(jq '[.. | scalars | select(type == "string" and (. | gsub("^\\s+|\\s+$"; "") == ""))] | length' "${jf}" 2>/dev/null || echo 0)"
    if [[ "${empty_count}" -gt 0 ]]; then
      echo "❌ [I18N GATE] ${jf}: Contains ${empty_count} empty translation string(s)." >&2
      ERRORS=$((ERRORS + 1))
    fi

    if [[ "${jf}" != "${base_file}" ]]; then
      local curr_keys
      curr_keys="$(jq -r '[paths(scalars) | map(tostring) | join(".")] | sort | .[]' "${jf}" 2>/dev/null || true)"
      if [[ "${base_keys}" != "${curr_keys}" ]]; then
        echo "❌ [I18N PARITY GATE] Locale key mismatch between '${base_file}' and '${jf}'. All locales must define identical translation keys." >&2
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
}

# -----------------------------------------------------------------------------
# 1. Universal & Module-Aware i18n Checks
# -----------------------------------------------------------------------------
if [[ "${MODE}" == "all" || "${MODE}" == "i18n" ]]; then
  while IFS= read -r -d '' locale_dir; do
    check_locale_dir_parity "${locale_dir}"
  done < <(find "${ROOT_DIR}" \
    -type d \( -name ".git" -o -name "node_modules" -o -name ".venv" -o -name "dist" -o -name "build" \) -prune \
    -o -type d \( -name "locales" -o -name "i18n" -o -path "*/assets/*/lang" \) -print0)

  # Minecraft i18n check (only when fw:minecraft is active in manifest.json)
  if has_module "fw:minecraft"; then
    while IFS= read -r -d '' mc_screen; do
      if grep -vE '^[[:space:]]*//' "${mc_screen}" | grep -E -q '(Component|Text)\.literal[[:space:]]*\('; then
        echo "❌ [I18N / NARRATOR GATE] ${mc_screen}: Hardcoded Component.literal/Text.literal in Screen class. Use Component.translatable/Text.translatable for localization and Narrator accessibility." >&2
        ERRORS=$((ERRORS + 1))
      fi
    done < <(find "${ROOT_DIR}" \
      -type d \( -name ".git" -o -name "build" \) -prune \
      -o -type f \( -name "*Screen.java" -o -name "*Screen.kt" \) -print0)
  fi
fi

# -----------------------------------------------------------------------------
# 2. Module-Aware Accessibility (a11y) Checks
# -----------------------------------------------------------------------------
if [[ "${MODE}" == "all" || "${MODE}" == "a11y" ]]; then
  # 2a. Web JSX / Astro a11y checks (when fw:react or fw:astro is active)
  if has_module "fw:react" || has_module "fw:astro"; then
    while IFS= read -r -d '' web_file; do
      if grep -nE 'tabIndex=\{?[1-9][0-9]*\}?' "${web_file}" >/dev/null 2>&1; then
        echo "❌ [A11Y GATE] ${web_file}: Positive tabIndex (> 0) disrupts keyboard navigation order (WCAG 2.4.3)." >&2
        ERRORS=$((ERRORS + 1))
      fi
      if grep -nE '\bautoFocus\b' "${web_file}" >/dev/null 2>&1; then
        echo "❌ [A11Y GATE] ${web_file}: 'autoFocus' disorients screen reader and keyboard users (WCAG 2.4.3)." >&2
        ERRORS=$((ERRORS + 1))
      fi
    done < <(find "${ROOT_DIR}" \
      -type d \( -name ".git" -o -name "node_modules" -o -name "dist" -o -name ".guardrails" \) -prune \
      -o -type f \( -name "*.tsx" -o -name "*.jsx" -o -name "*.astro" \) -print0)
  fi

  # 2b. Python Flet & NiceGUI UI a11y checks (only when fw:flet or fw:nicegui is active)
  if has_module "fw:flet" || has_module "fw:nicegui"; then
    while IFS= read -r -d '' py_ui_file; do
      if has_module "fw:flet"; then
        if grep -vE '^[[:space:]]*#' "${py_ui_file}" | grep -E 'ft\.IconButton\([^)]*\)' | grep -vE 'tooltip[[:space:]]*=' >/dev/null 2>&1; then
          echo "❌ [A11Y GATE] ${py_ui_file}: ft.IconButton missing mandatory 'tooltip=' accessible label." >&2
          ERRORS=$((ERRORS + 1))
        fi
        if grep -vE '^[[:space:]]*#' "${py_ui_file}" | grep -E 'ft\.Image\([^)]*\)' | grep -vE '(semantics_label|tooltip)[[:space:]]*=' >/dev/null 2>&1; then
          echo "❌ [A11Y GATE] ${py_ui_file}: ft.Image missing mandatory 'semantics_label=' or 'tooltip='." >&2
          ERRORS=$((ERRORS + 1))
        fi
      fi
      if has_module "fw:nicegui"; then
        if grep -vE '^[[:space:]]*#' "${py_ui_file}" | grep -E 'ui\.image\([^)]*\)' | grep -vE '(alt|\.props)' >/dev/null 2>&1; then
          echo "❌ [A11Y GATE] ${py_ui_file}: ui.image missing accessible alt text (.props('alt=...'))." >&2
          ERRORS=$((ERRORS + 1))
        fi
      fi
    done < <(find "${ROOT_DIR}" \
      -type d \( -name ".git" -o -name ".venv" -o -name "venv" \) -prune \
      -o -type f -path "*/ui/*.py" -print0)
  fi
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [I18N / A11Y GATE] Failed with ${ERRORS} violation(s)." >&2
  exit 1
fi

echo "✅ [I18N / A11Y GATE] Universal localization parity & accessibility checks passed."
