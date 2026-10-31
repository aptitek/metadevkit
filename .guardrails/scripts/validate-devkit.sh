#!/usr/bin/env bash
# =============================================================================
# validate-devkit.sh — Meta-Devkit Self-Governance Gate ("Who Guards the Guardians")
# Enforces:
#   1. Algebraic module.json manifest schema (aliases, conflicts_with,
#      commit_scopes, conditional_files), global alias uniqueness,
#      irreflexive & symmetric conflicts_with, DAG acyclicity, satisfiability,
#      layer hierarchy, and conditional_files source_dir existence
#   2. Zero static file collisions across files/, conditional_files, and fragments/
#   3. Colocated Semgrep AST rules (modules/**/files/.guardrails/ast/*.yml;
#      forbids legacy root rules/ directory)
#   4. Agent Skill frontmatter (strictly within --- block), Token Parsimony
#      (<= 100 lines per SKILL.md), and ./references/*.md link resolution
#   5. Strict Root Isolation (DRY): root .agents/skills/ and .guardrails/ast/
#      only contain files from modules active in .guardrails/manifest.json
#   6. JSON configuration validity across all modules
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
  -type d \( -name ".git" -o -name "node_modules" -o -name ".venv" -o -name ".cache" -o -name "__pycache__" \) -prune \
  -o -type f -name "*.json" -print0)

# 2. Validate module.json manifests, dependency DAG, alias uniqueness, symmetric conflicts_with,
# satisfiability, layer hierarchy, conditional_files directories, and zero static file collisions
if [[ -d "${ROOT_DIR}/modules" ]]; then
  declare -A static_file_owners=()
  declare -A fragment_targets=()
  declare -A seen_aliases=()
  declare -a all_mod_jsons=()

  while IFS= read -r -d '' mod_json; do
    all_mod_jsons+=("${mod_json}")
    mod_dir="$(dirname "${mod_json}")"
    mod_id="$(jq -r '.id // empty' "${mod_json}")"
    mod_layer="$(jq -r '.layer // empty' "${mod_json}")"
    mod_desc="$(jq -r '.description // empty' "${mod_json}")"

    if [[ -z "${mod_id}" || -z "${mod_layer}" || -z "${mod_desc}" ]]; then
      echo "❌ [DEVKIT GATE] ${mod_json}: Missing required fields (id, layer, description)." >&2
      ERRORS=$((ERRORS + 1))
    fi

    if ! jq -e '
      (.aliases | type == "array") and
      (.depends_on | type == "array") and
      (.conflicts_with | type == "array") and
      (.commit_scopes | (type == "array" and length > 0)) and
      (.conditional_files | type == "array")
    ' "${mod_json}" >/dev/null 2>&1; then
      echo "❌ [DEVKIT GATE] ${mod_json}: Missing or invalid V5 algebraic fields (aliases, depends_on, conflicts_with, commit_scopes, conditional_files)." >&2
      ERRORS=$((ERRORS + 1))
    fi

    case "${mod_layer}" in
      core|lang|fw|addon) ;;
      *)
        echo "❌ [DEVKIT GATE] ${mod_json}: Invalid layer '${mod_layer}' (expected core|lang|fw|addon)." >&2
        ERRORS=$((ERRORS + 1))
        ;;
    esac

    # Verify global uniqueness of id and aliases across all modules
    while IFS= read -r key_name; do
      [[ -z "${key_name}" ]] && continue
      if [[ -n "${seen_aliases[$key_name]+x}" ]]; then
        echo "❌ [DEVKIT ALIAS GATE] ${mod_json}: Duplicate module ID or alias '${key_name}' (already claimed by '${seen_aliases[$key_name]}')." >&2
        ERRORS=$((ERRORS + 1))
      else
        seen_aliases["$key_name"]="$mod_id"
      fi
    done < <(jq -r '([.id] + (.aliases // []))[]' "${mod_json}")

    # Verify existence of source_dir for every conditional_files entry and check collisions
    while IFS= read -r cond_src_dir; do
      [[ -z "${cond_src_dir}" ]] && continue
      if [[ ! -d "${mod_dir}/${cond_src_dir}" ]]; then
        echo "❌ [DEVKIT CONDITIONAL FILES GATE] ${mod_json}: conditional_files source_dir '${cond_src_dir}' does not exist at '${mod_dir}/${cond_src_dir}'." >&2
        ERRORS=$((ERRORS + 1))
      else
        while IFS= read -r -d '' cfile; do
          rel_c="${cfile#"${mod_dir}/${cond_src_dir}/"}"
          if [[ -n "${static_file_owners[$rel_c]+x}" ]]; then
            echo "❌ [DEVKIT COLLISION GATE] Conditional file '${rel_c}' in '${mod_id}' collides with '${static_file_owners[$rel_c]}'." >&2
            ERRORS=$((ERRORS + 1))
          else
            static_file_owners["$rel_c"]="$mod_id"
          fi
        done < <(find "${mod_dir}/${cond_src_dir}" -type f -print0)
      fi
    done < <(jq -r '.conditional_files[]?.source_dir // empty' "${mod_json}")

    while IFS= read -r ref_id; do
      [[ -z "${ref_id}" ]] && continue
      dep_rel=""
      case "${ref_id}" in
        core) dep_rel="modules/core" ;;
        lang:*) dep_rel="modules/lang/${ref_id#lang:}" ;;
        fw:*) dep_rel="modules/fw/${ref_id#fw:}" ;;
        addon:*) dep_rel="modules/addons/${ref_id#addon:}" ;;
        *)
          echo "❌ [DEVKIT GATE] ${mod_json}: Invalid module reference ID '${ref_id}'." >&2
          ERRORS=$((ERRORS + 1))
          continue
          ;;
      esac
      if [[ ! -f "${ROOT_DIR}/${dep_rel}/module.json" ]]; then
        echo "❌ [DEVKIT GATE] ${mod_json}: Referenced module '${ref_id}' (${dep_rel}/module.json) does not exist." >&2
        ERRORS=$((ERRORS + 1))
      fi
    done < <(jq -r '(.depends_on[]?, .conflicts_with[]?, .conditional_files[]?.when_all[]?)' "${mod_json}")

    # Check static file collision freedom in files/
    if [[ -d "${mod_dir}/files" ]]; then
      while IFS= read -r -d '' sfile; do
        rel_s="${sfile#"${mod_dir}/files/"}"
        if [[ -n "${static_file_owners[$rel_s]+x}" ]]; then
          echo "❌ [DEVKIT COLLISION GATE] Static file '${rel_s}' is defined in both '${static_file_owners[$rel_s]}' and '${mod_id}'. Move shared configs to 'fragments/'." >&2
          ERRORS=$((ERRORS + 1))
        else
          static_file_owners["$rel_s"]="$mod_id"
        fi
      done < <(find "${mod_dir}/files" -type f -print0)
    fi

    # Record fragment target paths
    if [[ -d "${mod_dir}/fragments" ]]; then
      while IFS= read -r -d '' ffile; do
        rel_f="${ffile#"${mod_dir}/fragments/"}"
        [[ "$rel_f" == *.toml.json ]] && rel_f="${rel_f%.json}"
        fragment_targets["$rel_f"]="$mod_id"
      done < <(find "${mod_dir}/fragments" -type f -print0)
    fi
  done < <(find "${ROOT_DIR}/modules" -type f -name "module.json" -print0)

  # Ensure no fragment target path collides with a static file in files/ or conditional_files/
  for f_target in "${!fragment_targets[@]}"; do
    if [[ -n "${static_file_owners[$f_target]+x}" ]]; then
      echo "❌ [DEVKIT COLLISION GATE] Fragment target '${f_target}' ('${fragment_targets[$f_target]}') collides with static file in '${static_file_owners[$f_target]}'." >&2
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Verify DAG acyclicity, satisfiability, layer hierarchy, and conflicts_with symmetry
  if [[ "${#all_mod_jsons[@]}" -gt 0 ]]; then
    while IFS= read -r dag_err; do
      [[ -z "${dag_err}" ]] && continue
      echo "❌ [DEVKIT DAG GATE] ${dag_err}" >&2
      ERRORS=$((ERRORS + 1))
    done < <(jq -rs '
      (INDEX(.[]; .id)) as $by_id |
      def layer_rank($l):
        if $l == "core" then 0
        elif $l == "lang" then 1
        elif $l == "fw" then 2
        elif $l == "addon" then 3
        else 9 end;
      def closure($start; $seen):
        if ($seen | index($start)) != null then
          ["CYCLE:\($start)"]
        else
          ([$start] + ([($by_id[$start].depends_on // [])[] as $d | closure($d; $seen + [$start])[]] | unique))
        end;
      [
        .[] as $m |
        # 1. Irreflexivity and Symmetry of conflicts_with
        (
          ($m.conflicts_with // [])[] as $c |
          if $c == $m.id then
            "Module \($m.id) declares a self-conflict (irreflexivity violation)."
          elif (($by_id[$c].conflicts_with // []) | index($m.id)) == null then
            "Asymmetric conflict: \($m.id) conflicts_with \($c), but \($c) does not declare \($m.id) in conflicts_with."
          else empty end
        ),
        # 2. Layer hierarchy on core and lang (core/lang must never depend on fw/addon)
        (
          select($m.layer == "core" or $m.layer == "lang") |
          ($m.depends_on // [])[] as $d |
          select(layer_rank($by_id[$d].layer) > layer_rank($m.layer)) |
          "Layer hierarchy violation: \($m.id) (\($m.layer)) cannot depend on higher layer \($d) (\($by_id[$d].layer))."
        ),
        # 3. Acyclicity & Satisfiability of transitive closure
        (
          closure($m.id; []) as $cl |
          if any($cl[]; startswith("CYCLE:")) then
            "Dependency cycle detected starting from \($m.id)."
          else
            (
              $cl[] as $u |
              ($by_id[$u].conflicts_with // [])[] as $v |
              select(($cl | index($v)) != null) |
              "Unsatisfiable module \($m.id): transitive dependencies include conflicting pair (\($u), \($v))."
            )
          end
        )
      ] | unique | .[]
    ' "${all_mod_jsons[@]}")
  fi

  declare -A mise_reg_tools=()
  if command -v mise >/dev/null 2>&1; then
    while IFS= read -r reg_line; do
      tname="${reg_line%% *}"
      [[ -n "$tname" ]] && mise_reg_tools["$tname"]=1
    done < <(mise registry 2>/dev/null || true)
  fi

  while IFS= read -r -d '' mise_frag; do
    if grep -E -q '=\s*"latest"' "${mise_frag}"; then
      echo "❌ [DEVKIT MISE PIN GATE] ${mise_frag}: Unpinned '\"latest\"' version is forbidden. Pin all tool versions to major.minor." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if [[ "${#mise_reg_tools[@]}" -gt 0 ]]; then
      while IFS= read -r bare_tool; do
        [[ -z "$bare_tool" ]] && continue
        if [[ -z "${mise_reg_tools[$bare_tool]+x}" ]]; then
          echo "❌ [DEVKIT MISE REGISTRY GATE] ${mise_frag}: Tool '${bare_tool}' does not exist in 'mise registry'." >&2
          ERRORS=$((ERRORS + 1))
        fi
      done < <(awk -F'=' '/^[a-z0-9_-]+[[:space:]]*=/ { gsub(/[[:space:]]/, "", $1); print $1 }' "${mise_frag}")
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

# 4. Validate Agent Skills (Frontmatter strictly inside --- block, Token Parsimony <= 100 lines, and Reference links)
while IFS= read -r -d '' skill_file; do
  skill_dir="$(dirname "${skill_file}")"
  expected_name="$(basename "${skill_dir}")"
  line_count="$(wc -l < "${skill_file}")"

  if [[ "${line_count}" -gt 100 ]]; then
    echo "❌ [DEVKIT SKILL TOKEN GATE] ${skill_file}: ${line_count} lines exceeds 100-line Progressive Disclosure cap. Move detailed examples into '${skill_dir}/references/*.md'." >&2
    ERRORS=$((ERRORS + 1))
  fi

  frontmatter="$(awk 'NR==1 && /^---[[:space:]]*$/ { in_fm=1; next } in_fm && /^---[[:space:]]*$/ { exit } in_fm { print }' "${skill_file}")"

  if [[ -z "${frontmatter}" ]]; then
    echo "❌ [DEVKIT SKILL GATE] ${skill_file}: Missing valid YAML frontmatter block delimited by '---'." >&2
    ERRORS=$((ERRORS + 1))
  else
    if ! grep -E -q "^name:[[:space:]]*${expected_name}[[:space:]]*$" <<< "${frontmatter}"; then
      echo "❌ [DEVKIT SKILL GATE] ${skill_file}: Frontmatter 'name:' must match directory '${expected_name}'." >&2
      ERRORS=$((ERRORS + 1))
    fi
    if ! grep -E -q '^description:' <<< "${frontmatter}"; then
      echo "❌ [DEVKIT SKILL GATE] ${skill_file}: Missing 'description:' in YAML frontmatter." >&2
      ERRORS=$((ERRORS + 1))
    fi
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
