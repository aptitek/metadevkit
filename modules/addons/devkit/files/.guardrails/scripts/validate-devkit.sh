#!/usr/bin/env bash
# =============================================================================
# validate-devkit.sh — Meta-Devkit Self-Governance Gate ("Who Guards the Guardians")
# Enforces:
#   1. Module manifest schema & DAG integrity (modules/**/module.json)
#   2. Semgrep AST rule file structure (rules/ast/*.yml & .guardrails/ast/*.yml)
#   3. Agent Skill frontmatter, Token Parsimony (<= 100 lines per SKILL.md),
#      and ./references/*.md link resolution
#   4. Module-to-Root Skill & Reference byte-for-byte parity
#   5. JSON configuration validity across all modules
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

# 1. Validate all JSON files in the repository
while IFS= read -r -d '' json_file; do
  if ! jq empty "${json_file}" >/dev/null 2>&1; then
    echo "❌ [DEVKIT GATE] ${json_file}: Invalid JSON syntax." >&2
    ERRORS=$((ERRORS + 1))
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "node_modules" -o -name ".venv" \) -prune \
  -o -type f -name "*.json" -print0)

# 2. Validate module.json manifests & dependency DAG (when modules/ directory exists)
if [[ -d "${ROOT_DIR}/modules" ]]; then
  while IFS= read -r -d '' mod_json; do
    mod_id="$(jq -r '.id // empty' "${mod_json}")"
    mod_layer="$(jq -r '.layer // empty' "${mod_json}")"
    mod_desc="$(jq -r '.description // empty' "${mod_json}")"

    if [[ -z "${mod_id}" || -z "${mod_layer}" || -z "${mod_desc}" ]]; then
      echo "❌ [DEVKIT GATE] ${mod_json}: Missing required fields (id, layer, description)." >&2
      ERRORS=$((ERRORS + 1))
    fi

    case "${mod_layer}" in
      core|lang|fw|addon) ;;
      *)
        echo "❌ [DEVKIT GATE] ${mod_json}: Invalid layer '${mod_layer}' (expected core|lang|fw|addon)." >&2
        ERRORS=$((ERRORS + 1))
        ;;
    esac

    # Verify each dependency in depends_on exists
    while IFS= read -r dep_id; do
      [[ -z "${dep_id}" ]] && continue
      dep_rel=""
      case "${dep_id}" in
        core) dep_rel="modules/core" ;;
        lang:*) dep_rel="modules/lang/${dep_id#lang:}" ;;
        fw:*) dep_rel="modules/fw/${dep_id#fw:}" ;;
        addon:*) dep_rel="modules/addons/${dep_id#addon:}" ;;
        *)
          echo "❌ [DEVKIT GATE] ${mod_json}: Invalid dependency ID '${dep_id}'." >&2
          ERRORS=$((ERRORS + 1))
          continue
          ;;
      esac
      if [[ ! -f "${ROOT_DIR}/${dep_rel}/module.json" ]]; then
        echo "❌ [DEVKIT GATE] ${mod_json}: Dependency '${dep_id}' (${dep_rel}/module.json) does not exist." >&2
        ERRORS=$((ERRORS + 1))
      fi
    done < <(jq -r '.depends_on[]?' "${mod_json}")
  done < <(find "${ROOT_DIR}/modules" -type f -name "module.json" -print0)
fi

# 3. Validate AST YAML rule files
for ast_dir in "${ROOT_DIR}/rules/ast" "${ROOT_DIR}/.guardrails/ast"; do
  [[ -d "${ast_dir}" ]] || continue
  while IFS= read -r -d '' yml_file; do
    if ! grep -E -q '^rules:' "${yml_file}"; then
      echo "❌ [DEVKIT GATE] ${yml_file}: Missing top-level 'rules:' key." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if ! grep -E -q '^[[:space:]]*-[[:space:]]+id:[[:space:]]+[a-z0-9-]+' "${yml_file}"; then
      echo "❌ [DEVKIT GATE] ${yml_file}: Missing valid rule '- id: <kebab-case-id>'." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if ! grep -E -q '^[[:space:]]*severity:[[:space:]]+(ERROR|WARNING|INFO)' "${yml_file}"; then
      echo "❌ [DEVKIT GATE] ${yml_file}: Missing 'severity: ERROR|WARNING|INFO'." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ast_dir}" -type f -name "*.yml" -print0)
done

# 4. Validate Agent Skills (Frontmatter, Token Parsimony <= 100 lines, and Reference links)
while IFS= read -r -d '' skill_file; do
  skill_dir="$(dirname "${skill_file}")"
  expected_name="$(basename "${skill_dir}")"
  line_count="$(wc -l < "${skill_file}")"

  # 4a. Token Parsimony Gate (<= 100 lines per SKILL.md; move bulky content to references/)
  if [[ "${line_count}" -gt 100 ]]; then
    echo "❌ [DEVKIT SKILL TOKEN GATE] ${skill_file}: ${line_count} lines exceeds 100-line Progressive Disclosure cap. Move detailed examples into '${skill_dir}/references/*.md'." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 4b. Frontmatter name & description check
  if [[ "$(head -n 1 "${skill_file}")" != "---" ]]; then
    echo "❌ [DEVKIT SKILL GATE] ${skill_file}: Missing YAML frontmatter opening '---'." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if ! grep -E -q "^name:\s*${expected_name}\s*$" "${skill_file}"; then
    echo "❌ [DEVKIT SKILL GATE] ${skill_file}: Frontmatter 'name:' must match directory '${expected_name}'." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if ! grep -E -q '^description:' "${skill_file}"; then
    echo "❌ [DEVKIT SKILL GATE] ${skill_file}: Missing 'description:' in YAML frontmatter." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 4c. Verify all relative ./references/... links resolve to existing files
  while IFS= read -r ref_rel; do
    [[ -z "${ref_rel}" ]] && continue
    clean_rel="${ref_rel#./}"
    if [[ ! -f "${skill_dir}/${clean_rel}" ]]; then
      echo "❌ [DEVKIT SKILL GATE] ${skill_file}: Broken Progressive Disclosure link '${ref_rel}' (missing ${skill_dir}/${clean_rel})." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(grep -oE '\./references/[A-Za-z0-9._/-]+\.md' "${skill_file}" || true)
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "node_modules" \) -prune \
  -o -type f -name "SKILL.md" -print0)

# 5. Module-to-Root Skill Parity Gate (when both modules/ and .agents/skills/ exist)
if [[ -d "${ROOT_DIR}/modules" && -d "${ROOT_DIR}/.agents/skills" ]]; then
  while IFS= read -r -d '' mod_skill_file; do
    rel_skill="${mod_skill_file#*/files/.agents/skills/}"
    root_skill_file="${ROOT_DIR}/.agents/skills/${rel_skill}"
    if [[ ! -f "${root_skill_file}" ]]; then
      echo "❌ [DEVKIT PARITY GATE] Skill file '${rel_skill}' exists in '${mod_skill_file}' but is missing from '.agents/skills/${rel_skill}'. Run 'task guard:sync'." >&2
      ERRORS=$((ERRORS + 1))
    elif ! cmp -s "${mod_skill_file}" "${root_skill_file}"; then
      echo "❌ [DEVKIT PARITY GATE] Skill drift detected between '${mod_skill_file}' and '.agents/skills/${rel_skill}'. Run 'task guard:sync'." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/modules" -type f -path "*/files/.agents/skills/*" -print0)
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [DEVKIT GATE] Failed with ${ERRORS} meta-devkit self-governance violation(s)." >&2
  exit 1
fi

echo "✅ [DEVKIT GATE] Meta-devkit self-governance checks passed (modules, AST rules, & progressive skills verified)."
