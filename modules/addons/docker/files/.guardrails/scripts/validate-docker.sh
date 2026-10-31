#!/usr/bin/env bash
# =============================================================================
# validate-docker.sh — Docker & Compose Security Gate (addon:docker)
# Enforces:
#   1. Zero unpinned ':latest' image tags in FROM instructions
#   2. Mandatory non-root 'USER' instruction in production Dockerfiles
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

while IFS= read -r -d '' dockerfile; do
  if grep -vE '^[[:space:]]*#' "${dockerfile}" | grep -iE '^[[:space:]]*FROM[[:space:]]+[^[:space:]]+:latest\b' >/dev/null 2>&1; then
    echo "❌ [DOCKER GATE] ${dockerfile}: Unpinned ':latest' image tag in FROM is forbidden. Pin an explicit version or digest." >&2
    ERRORS=$((ERRORS + 1))
  fi
  if ! grep -vE '^[[:space:]]*#' "${dockerfile}" | grep -iE '^[[:space:]]*USER[[:space:]]+[a-zA-Z0-9_-]+' >/dev/null 2>&1; then
    echo "❌ [DOCKER GATE] ${dockerfile}: Missing non-root 'USER' instruction in Dockerfile." >&2
    ERRORS=$((ERRORS + 1))
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "node_modules" -o -name ".venv" -o -name ".guardrails" -o -name "modules" \) -prune \
  -o -type f \( -name "Dockerfile" -o -name "Dockerfile.*" \) -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [DOCKER GATE] Failed with ${ERRORS} container security violation(s)." >&2
  exit 1
fi

echo "✅ [DOCKER GATE] Dockerfile & Compose security checks passed."
