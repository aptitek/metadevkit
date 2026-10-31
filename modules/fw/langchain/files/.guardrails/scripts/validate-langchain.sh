#!/usr/bin/env bash
# =============================================================================
# validate-langchain.sh — LangChain / LangGraph / MCP Architecture Gate (fw:langchain)
# Enforces:
#   1. Zero legacy LLMChain, SequentialChain, ConversationChain, or initialize_agent
#   2. Zero hardcoded API key string literals in src/
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

while IFS= read -r -d '' py_file; do
  if [[ "${py_file}" == *"/src/"* || "${py_file}" == "src/"* ]]; then
    # 1. Legacy chain/agent check
    if grep -nE '(^|[^a-zA-Z0-9_])(LLMChain|SequentialChain|SimpleSequentialChain|ConversationChain|initialize_agent)\s*\(' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [LANGCHAIN GATE] ${py_file}: Deprecated legacy chain/agent (LLMChain/SequentialChain/initialize_agent) detected. Use LCEL (prompt | llm) or LangGraph StateGraph." >&2
      ERRORS=$((ERRORS + 1))
    fi

    # 2. Hardcoded API key check
    if grep -nE '(api_key|google_api_key|openai_api_key|anthropic_api_key)\s*=\s*["'\''][A-Za-z0-9_\-]{8,}["'\'']' "${py_file}" | grep -vE '^\s*#' >/dev/null 2>&1; then
      echo "❌ [LANGCHAIN SECURITY GATE] ${py_file}: Hardcoded API key literal detected. Load secrets via pydantic-settings SecretStr." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" -o -name ".git" \) -prune \
  -o -type f -name "*.py" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [LANGCHAIN GATE] Failed with ${ERRORS} LangChain/LangGraph architectural violation(s)." >&2
  exit 1
fi

echo "✅ [LANGCHAIN GATE] LangChain LCEL, LangGraph & SecretStr checks passed."
