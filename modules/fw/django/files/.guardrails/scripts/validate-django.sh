#!/usr/bin/env bash
# =============================================================================
# validate-django.sh — Django 5.x+ Architecture, ORM, Settings & Template Gate
# Enforces:
#   1. Locked .djlintrc configuration presence
#   2. Production Settings Security: bans hardcoded SECRET_KEY, DEBUG = True,
#      and wildcard ALLOWED_HOSTS = ["*"] in *settings*.py
#   3. Fat-Free Views (HackSoft Services/Selectors pattern): bans direct ORM
#      writes (.objects.create/bulk_create/update/delete) and transaction.atomic
#      inside views.py / views/*.py
#   4. ORM & Model Hygiene (Ruff DJ001 + SQLi/XSS): bans .raw(), .extra(),
#      mark_safe(), and CharField/TextField(null=True)
#   5. Django HTML Templates (XSS & WCAG 2.2 AA): bans '|safe', <img> missing
#      alt=, and positive tabindex in templates/**/*.html
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

if [[ ! -f "${ROOT_DIR}/.djlintrc" ]]; then
  echo "❌ [DJANGO GATE] Missing locked .djlintrc template linter configuration." >&2
  ERRORS=$((ERRORS + 1))
fi

# 1. Scan Python files for Django settings, views, models, and SQLi/XSS gates
while IFS= read -r -d '' py_file; do
  # 1a. Global Django SQLi & XSS checks (.raw, .extra, mark_safe)
  if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- '\.(raw|extra)\s*\(' >/dev/null 2>&1; then
    echo "❌ [DJANGO SECURITY] ${py_file}: Raw SQL query (.raw() / .extra()) is forbidden. Use parameterized Django ORM QuerySets." >&2
    ERRORS=$((ERRORS + 1))
  fi
  if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- '\bmark_safe\s*\(' >/dev/null 2>&1; then
    echo "❌ [DJANGO SECURITY] ${py_file}: mark_safe() is forbidden (XSS risk). Use django.utils.html.format_html()." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 1b. Settings Security Checks (*settings*.py)
  if [[ "${py_file}" == *"settings"* ]]; then
    if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- '^[[:space:]]*SECRET_KEY[[:space:]]*=[[:space:]]*["'\''][^"'\'']+["'\'']' >/dev/null 2>&1; then
      echo "❌ [DJANGO SETTINGS GATE] ${py_file}: Hardcoded SECRET_KEY string literal is forbidden. Load from environment or /run/secrets/." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- '^[[:space:]]*DEBUG[[:space:]]*=[[:space:]]*True\b' >/dev/null 2>&1; then
      echo "❌ [DJANGO SETTINGS GATE] ${py_file}: Hardcoded 'DEBUG = True' is forbidden. Read from environment defaulting to False." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- 'ALLOWED_HOSTS[[:space:]]*=[[:space:]]*\[\s*["'\'']\*["'\'']\s*\]' >/dev/null 2>&1; then
      echo "❌ [DJANGO SETTINGS GATE] ${py_file}: Wildcard ALLOWED_HOSTS = ['*'] is forbidden." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # 1c. Fat-Free Views Check (*views*.py) — HackSoft Services/Selectors Styleguide
  if [[ "${py_file}" == *"views"* ]]; then
    if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- '\.objects\.(create|bulk_create|update|delete)\s*\(|transaction\.atomic' >/dev/null 2>&1; then
      echo "❌ [DJANGO ARCHITECTURE] ${py_file}: Direct ORM mutation (.objects.create/update/delete or transaction.atomic) inside views is forbidden. Delegate writes to services.py and reads to selectors.py." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # 1d. Model Field Hygiene (*models*.py) — DJ001 (no null=True on CharField/TextField)
  if [[ "${py_file}" == *"models"* ]]; then
    if grep -vE '^[[:space:]]*#' "${py_file}" | grep -E -- '(CharField|TextField|SlugField|EmailField)\s*\([^)]*null\s*=\s*True' >/dev/null 2>&1; then
      echo "❌ [DJANGO MODEL GATE (DJ001)] ${py_file}: null=True on string-based field (CharField/TextField/SlugField/EmailField) is forbidden. Use blank=True, default=\"\"." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" -o -name ".git" -o -name "migrations" -o -name ".guardrails" -o -name "modules" \) -prune \
  -o -type f -name "*.py" -print0)

# 2. Scan Django HTML Templates (templates/**/*.html) for XSS and WCAG 2.2 AA
if [[ -d "${ROOT_DIR}/templates" ]]; then
  while IFS= read -r -d '' html_file; do
    if grep -E -- '\|\s*safe\b|\{%\s*autoescape\s+off\s*%\}' "${html_file}" >/dev/null 2>&1; then
      echo "❌ [DJANGO TEMPLATE SECURITY] ${html_file}: Unescaped '|safe' filter or '{% autoescape off %}' is forbidden in templates (XSS risk)." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -E -- '<img\b[^>]*>' "${html_file}" | grep -vE -- '\balt\s*=' >/dev/null 2>&1; then
      echo "❌ [DJANGO A11Y GATE] ${html_file}: <img> element missing mandatory 'alt=' attribute in Django template." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if grep -E -- 'tabindex\s*=\s*"[1-9][0-9]*"' "${html_file}" >/dev/null 2>&1; then
      echo "❌ [DJANGO A11Y GATE] ${html_file}: Positive tabindex (> 0) is forbidden by WCAG 2.2 AA." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/templates" -type f -name "*.html" -print0)
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [DJANGO GATE] Failed with ${ERRORS} Django architectural/security violation(s)." >&2
  exit 1
fi

echo "✅ [DJANGO GATE] Django 5.x+ Services/Selectors architecture, ORM, settings & template gates passed."
