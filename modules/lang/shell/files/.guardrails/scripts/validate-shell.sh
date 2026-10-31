#!/usr/bin/env bash
# =============================================================================
# validate-shell.sh — Defensive Bash & Shell Script Quality Gate (lang:shell)
# Enforces:
#   1. Valid shebang (#!/usr/bin/env bash or #!/bin/sh)
#   2. Mandatory strict mode 'set -euo pipefail' in all bash scripts
#   3. Syntax verification via 'bash -n'
#   4. Zero 'eval ' or remote pipe-to-shell anti-patterns
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0
EVAL_RE='^[[:space:]]*eval[[:space:]]+'
PIPE_SH_RE='^[[:space:]]*(curl|wget)[[:space:]]+[^#]*\|[[:space:]]*(ba)?sh\b'

while IFS= read -r -d '' sh_file; do
  # 1. Shebang check
  first_line="$(head -n 1 "${sh_file}")"
  if [[ "${first_line}" != "#!/usr/bin/env bash" && "${first_line}" != "#!/bin/bash" && "${first_line}" != "#!/bin/sh" ]]; then
    echo "❌ [SHELL GATE] ${sh_file}: Missing valid shebang ('#!/usr/bin/env bash' expected)." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Strict mode check for bash scripts
  if [[ "${first_line}" == *"bash"* ]]; then
    if ! grep -E -q '^[[:space:]]*set[[:space:]]+-euo[[:space:]]+pipefail\b' "${sh_file}"; then
      echo "❌ [SHELL GATE] ${sh_file}: Missing mandatory strict mode 'set -euo pipefail'." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # 3. Syntax check via bash -n
  if ! bash -n "${sh_file}" 2>/dev/null; then
    echo "❌ [SHELL GATE] ${sh_file}: Failed 'bash -n' syntax check." >&2
    bash -n "${sh_file}" >&2 || true
    ERRORS=$((ERRORS + 1))
  fi

  # 4. Forbidden eval / remote pipe-to-shell check on non-comment lines
  if grep -vE '^[[:space:]]*#' "${sh_file}" | grep -E -q "${EVAL_RE}"; then
    echo "❌ [SHELL GATE] ${sh_file}: Forbidden 'eval' statement detected." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -vE '^[[:space:]]*#' "${sh_file}" | grep -E -q "${PIPE_SH_RE}"; then
    echo "❌ [SHELL GATE] ${sh_file}: Forbidden remote pipe-to-shell detected." >&2
    ERRORS=$((ERRORS + 1))
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "node_modules" -o -name ".venv" -o -name "venv" -o -name "dist" -o -name "build" \) -prune \
  -o -type f -name "*.sh" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [SHELL GATE] Failed with ${ERRORS} shell script violation(s)." >&2
  exit 1
fi

echo "✅ [SHELL GATE] All shell scripts passed strict mode, syntax & security checks."
