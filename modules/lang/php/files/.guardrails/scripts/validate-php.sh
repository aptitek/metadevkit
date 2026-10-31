#!/usr/bin/env bash
# =============================================================================
# validate-php.sh — PHP Strict Types & Hygiene Gate (lang:php)
# Enforces:
#   1. Mandatory declare(strict_types=1); in every .php file
#   2. Zero debug dumps (var_dump, dd, dump, print_r) in src/ or app/
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

while IFS= read -r -d '' php_file; do
  if ! grep -qE 'declare\s*\(\s*strict_types\s*=\s*1\s*\)\s*;' "${php_file}"; then
    echo "❌ [PHP GATE] ${php_file}: Missing mandatory 'declare(strict_types=1);' declaration." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if [[ "${php_file}" == *"/src/"* || "${php_file}" == "src/"* || "${php_file}" == *"/app/"* || "${php_file}" == "app/"* ]]; then
    if grep -vE '^[[:space:]]*(//|\*|#)' "${php_file}" | grep -E '\b(var_dump|dd|dump|print_r)\s*\(' >/dev/null 2>&1; then
      echo "❌ [PHP GATE] ${php_file}: Forbidden debug function (var_dump, dd, dump, print_r) in production source." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "vendor" -o -name "node_modules" -o -name ".guardrails" -o -name "storage" -o -name "bootstrap" \) -prune \
  -o -type f -name "*.php" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [PHP GATE] Failed with ${ERRORS} strict-typing / hygiene violation(s)." >&2
  exit 1
fi

echo "✅ [PHP GATE] PHP strict_types=1 & hygiene gates passed."
