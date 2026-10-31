#!/usr/bin/env bash
# =============================================================================
# polyglot-guardrails — Configuration Anti-Tamper & Lock Verifier
# Executed automatically by `task guard:check`, `task verify`, and `pre-commit`
# =============================================================================
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
LOCK_FILE="${PROJECT_ROOT}/.guardrails.lock"
MANIFEST_FILE="${PROJECT_ROOT}/.guardrails/manifest.json"
LOCAL_TASKFILE="${PROJECT_ROOT}/Taskfile.local.yml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

compute_sha256() {
  local target_file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target_file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$target_file" | awk '{print $1}'
  else
    echo "ERROR: Neither sha256sum nor shasum is available." >&2
    exit 1
  fi
}

if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo -e "${RED}[GUARDRAILS ERROR] Missing manifest file: .guardrails/manifest.json${NC}" >&2
  exit 1
fi

if [[ ! -f "$LOCK_FILE" ]]; then
  echo -e "${RED}[GUARDRAILS ERROR] Missing lock file: .guardrails.lock${NC}" >&2
  echo -e "${YELLOW}Run 'task guard:sync' to regenerate locked configurations from the master source.${NC}" >&2
  exit 1
fi

violations=0
checked_count=0
declare -A locked_paths=()

while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip comments and empty lines
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  expected_hash="${line%%  *}"
  rel_path="${line#*  }"
  full_path="${PROJECT_ROOT}/${rel_path}"
  locked_paths["$rel_path"]=1
  checked_count=$((checked_count + 1))

  if [[ ! -f "$full_path" ]]; then
    echo -e "${RED}[TAMPER DETECTED] Locked configuration file was deleted: ${rel_path}${NC}" >&2
    violations=$((violations + 1))
    continue
  fi

  actual_hash="$(compute_sha256 "$full_path")"
  if [[ "$actual_hash" != "$expected_hash" ]]; then
    echo -e "${RED}[TAMPER DETECTED] Illicit modification in locked file: ${rel_path}${NC}" >&2
    echo -e "  Expected SHA-256: ${expected_hash}" >&2
    echo -e "  Actual   SHA-256: ${actual_hash}" >&2
    violations=$((violations + 1))
  fi
done < "$LOCK_FILE"

# Ensure no untracked files were injected into .guardrails/
if [[ -d "${PROJECT_ROOT}/.guardrails" ]]; then
  while IFS= read -r -d '' file; do
    rel_file="${file#"${PROJECT_ROOT}/"}"
    if [[ -z "${locked_paths[$rel_file]+x}" ]]; then
      echo -e "${RED}[TAMPER DETECTED] Unregistered file injected into .guardrails/: ${rel_file}${NC}" >&2
      violations=$((violations + 1))
    fi
  done < <(find "${PROJECT_ROOT}/.guardrails" -type f -print0)
fi

# Inspect Taskfile.local.yml if present to forbid overriding core guardrail tasks
if [[ -f "$LOCAL_TASKFILE" ]]; then
  if grep -E -q '^[[:space:]]*(guard:check|guard:sync|verify|feature:add|mutate|a11y|i18n|typecheck|coverage)[[:space:]]*:' "$LOCAL_TASKFILE"; then
    echo -e "${RED}[TAMPER DETECTED] Taskfile.local.yml attempts to override protected guardrail tasks (guard:check, guard:sync, verify, feature:add, mutate, a11y, i18n, typecheck, or coverage).${NC}" >&2
    violations=$((violations + 1))
  fi
fi

if [[ "$violations" -gt 0 ]]; then
  echo "" >&2
  echo -e "${RED}=============================================================================${NC}" >&2
  echo -e "${RED} ZERO CONFIG DRIFT POLICY VIOLATION (${violations} issue(s) detected)${NC}" >&2
  echo -e "${RED}=============================================================================${NC}" >&2
  echo -e "${YELLOW}Configuration and quality guardrail files are strictly locked and managed by${NC}" >&2
  echo -e "${YELLOW}polyglot-guardrails. Manual or AI-agent edits to locked files are forbidden.${NC}" >&2
  echo -e "${YELLOW}  -> To revert your local changes: git checkout -- <file> or run 'task guard:sync'${NC}" >&2
  echo -e "${YELLOW}  -> To add local project tasks: use 'Taskfile.local.yml' only.${NC}" >&2
  exit 1
fi

echo -e "${GREEN}[GUARDRAILS OK] Verified ${checked_count} locked configuration files against .guardrails.lock (Zero Config Drift).${NC}"
exit 0
