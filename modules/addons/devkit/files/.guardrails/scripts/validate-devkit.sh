#!/usr/bin/env bash
# =============================================================================
# validate-devkit.sh — Meta-Devkit Self-Governance Gate ("Who Guards the Guardians")
# Enforces:
#   1. Module manifest schema & DAG integrity (modules/**/module.json)
#   2. Colocated Semgrep AST rules (modules/**/files/.guardrails/ast/*.yml;
#      forbids legacy root rules/ directory)
#   3. Agent Skill frontmatter, Token Parsimony (<= 100 lines per SKILL.md),
#      and ./references/*.md link resolution
#   4. Strict Root Isolation (DRY): root .agents/skills/ and .guardrails/ast/
#      only contain files from modules active in .guardrails/manifest.json
#   5. JSON configuration validity across all modules
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0

# 0. Forbid legacy global rules/ directory (AST rules must be colocated in modules/)
if [[ -d "${ROOT_DIR}/rules" ]]; then
  echo "❌ [DEVKIT DRY GATE] Legacy global '${ROOT_DIR}/rules' directory detected. Colocate all AST rules inside 'modules/<layer>/<name>/files/.guardrails/ast/'." >&2
  ERRORS=$((ERRORS + 1))
fi

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

  while IFS= read -r -d '' mise_frag; do
    if grep -E -q '=\s*"latest"' "${mise_frag}"; then
      echo "❌ [DEVKIT MISE PIN GATE] ${mise_frag}: Unpinned '\"latest\"' version is forbidden. Pin all tool versions to major.minor." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(find "${ROOT_DIR}/modules" -type f -name "mise.fragment.toml" -print0)
fi

# 3. Validate all colocated & active AST YAML rule files
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
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "node_modules" -o -name ".venv" \) -prune \
  -o -type f -path "*/.guardrails/ast/*.yml" -print0)

# 4. Validate Agent Skills (Frontmatter, Token Parsimony <= 100 lines, and Reference links)
while IFS= read -r -d '' skill_file; do
  skill_dir="$(dirname "${skill_file}")"
  expected_name="$(basename "${skill_dir}")"
  line_count="$(wc -l < "${skill_file}")"

  if [[ "${line_count}" -gt 100 ]]; then
    echo "❌ [DEVKIT SKILL TOKEN GATE] ${skill_file}: ${line_count} lines exceeds 100-line Progressive Disclosure cap. Move detailed examples into '${skill_dir}/references/*.md'." >&2
    ERRORS=$((ERRORS + 1))
  fi

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

# 5. Root DRY Isolation Gate: ensure root .agents/skills/ and .guardrails/ast/ only contain
# files from modules active in .guardrails/manifest.json
if [[ -d "${ROOT_DIR}/modules" && -f "${ROOT_DIR}/.guardrails/manifest.json" ]]; then
  declare -A allowed_skills=()
  declare -A allowed_ast=()

  while IFS= read -r active_mod; do
    [[ -z "${active_mod}" ]] && continue
    mod_rel=""
    case "${active_mod}" in
      core) mod_rel="modules/core" ;;
      lang:*) mod_rel="modules/lang/${active_mod#lang:}" ;;
      fw:*) mod_rel="modules/fw/${active_mod#fw:}" ;;
      addon:*) mod_rel="modules/addons/${active_mod#addon:}" ;;
    esac
    if [[ -d "${ROOT_DIR}/${mod_rel}/files/.agents/skills" ]]; then
      while IFS= read -r -d '' sdir; do
        allowed_skills["$(basename "${sdir}")"]=1
      done < <(find "${ROOT_DIR}/${mod_rel}/files/.agents/skills" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    if [[ -d "${ROOT_DIR}/${mod_rel}/files/.guardrails/ast" ]]; then
      while IFS= read -r -d '' afile; do
        allowed_ast["$(basename "${afile}")"]=1
      done < <(find "${ROOT_DIR}/${mod_rel}/files/.guardrails/ast" -type f -name "*.yml" -print0)
    fi
  done < <(jq -r '.modules[]' "${ROOT_DIR}/.guardrails/manifest.json")

  if [[ -d "${ROOT_DIR}/.agents/skills" ]]; then
    while IFS= read -r -d '' root_sdir; do
      sname="$(basename "${root_sdir}")"
      if [[ -z "${allowed_skills[$sname]+x}" ]]; then
        echo "❌ [DEVKIT DRY GATE] Root '.agents/skills/${sname}' belongs to an inactive module and must not be duplicated at root." >&2
        ERRORS=$((ERRORS + 1))
      fi
    done < <(find "${ROOT_DIR}/.agents/skills" -mindepth 1 -maxdepth 1 -type d -print0)
  fi

  if [[ -d "${ROOT_DIR}/.guardrails/ast" ]]; then
    while IFS= read -r -d '' root_afile; do
      aname="$(basename "${root_afile}")"
      if [[ -z "${allowed_ast[$aname]+x}" ]]; then
        echo "❌ [DEVKIT DRY GATE] Root '.guardrails/ast/${aname}' belongs to an inactive module and must not be duplicated at root." >&2
        ERRORS=$((ERRORS + 1))
      fi
    done < <(find "${ROOT_DIR}/.guardrails/ast" -type f -name "*.yml" -print0)
  fi
fi

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [DEVKIT GATE] Failed with ${ERRORS} meta-devkit self-governance violation(s)." >&2
  exit 1
fi

echo "✅ [DEVKIT GATE] Meta-devkit self-governance checks passed (modules, colocated AST rules, & DRY root verified)."
