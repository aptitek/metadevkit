#!/usr/bin/env bash
# =============================================================================
# polyglot-guardrails — Module Composition, Synchronization & Lock CLI
# Commands:
#   init        --target <dir> --source <path|url> --modules <m1,m2,...>
#   sync        [--target <dir>] [--source <path|url>]
#   feature-add <module> [--target <dir>]
#   check       [--target <dir>]
#   lock        [--target <dir>]
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

# Normalize module shorthand or full identifier into canonical ID
normalize_module_id() {
  local raw="$1"
  case "$raw" in
    core) echo "core" ;;
    ts|lang:ts) echo "lang:ts" ;;
    python|lang:python) echo "lang:python" ;;
    java|lang:java) echo "lang:java" ;;
    kotlin|lang:kotlin) echo "lang:kotlin" ;;
    php|lang:php) echo "lang:php" ;;
    shell|bash|lang:shell|lang:bash) echo "lang:shell" ;;
    react|fw:react) echo "fw:react" ;;
    react-router|fw:react-router) echo "fw:react-router" ;;
    astro|fw:astro) echo "fw:astro" ;;
    minecraft|fw:minecraft) echo "fw:minecraft" ;;
    quilt|fw:quilt) echo "fw:quilt" ;;
    fabric|fw:fabric) echo "fw:fabric" ;;
    flet|fw:flet) echo "fw:flet" ;;
    nicegui|fw:nicegui) echo "fw:nicegui" ;;
    langchain|langgraph|fw:langchain|addon:langchain|addons:langchain) echo "fw:langchain" ;;
    jupyter|jupiter|fw:jupyter|fw:jupiter|addon:jupyter|addons:jupyter) echo "fw:jupyter" ;;
    devkit|meta-devkit|guardrails|addon:devkit|addons:devkit|fw:devkit) echo "addon:devkit" ;;
    cloudflare|addon:cloudflare|addons:cloudflare) echo "addon:cloudflare" ;;
    design-system|addon:design-system|addons:design-system) echo "addon:design-system" ;;
    testing-fortress|addon:testing-fortress|addons:testing-fortress) echo "addon:testing-fortress" ;;
    storybook|addon:storybook|addons:storybook) echo "addon:storybook" ;;
    content-md|addon:content-md|addons:content-md) echo "addon:content-md" ;;
    drizzle-d1|addon:drizzle-d1|addons:drizzle-d1) echo "addon:drizzle-d1" ;;
    lib-exports|addon:lib-exports|addons:lib-exports) echo "addon:lib-exports" ;;
    *)
      echo -e "${RED}[GUARDRAILS ERROR] Unknown module identifier: '${raw}'${NC}" >&2
      echo "Supported modules: core, lang:ts, lang:python, lang:java, lang:kotlin, lang:php, lang:shell, fw:react, fw:react-router, fw:astro, fw:minecraft, fw:quilt, fw:fabric, fw:flet, fw:nicegui, fw:langchain, fw:jupyter, addon:devkit, addon:cloudflare, addon:design-system, addon:testing-fortress, addon:storybook, addon:content-md, addon:drizzle-d1, addon:lib-exports" >&2
      return 1
      ;;
  esac
}

# Convert canonical module ID to relative path inside polyglot-guardrails
module_rel_dir() {
  local mod_id="$1"
  case "$mod_id" in
    core) echo "modules/core" ;;
    lang:*) echo "modules/lang/${mod_id#lang:}" ;;
    fw:*) echo "modules/fw/${mod_id#fw:}" ;;
    addon:*) echo "modules/addons/${mod_id#addon:}" ;;
    *)
      echo -e "${RED}[GUARDRAILS ERROR] Invalid canonical module ID: '${mod_id}'${NC}" >&2
      return 1
      ;;
  esac
}

# Resolve dependency graph and topological ordering for a list of modules
resolve_modules() {
  local master_dir="$1"
  shift
  local requested=("$@")
  local -a resolved=()
  local -A seen=()

  visit_module() {
    local mod_id
    mod_id="$(normalize_module_id "$1")"
    if [[ -n "${seen[$mod_id]+x}" ]]; then
      return 0
    fi

    local rel_dir
    rel_dir="$(module_rel_dir "$mod_id")"
    local meta_file="${master_dir}/${rel_dir}/module.json"
    if [[ ! -f "$meta_file" ]]; then
      echo -e "${RED}[GUARDRAILS ERROR] Module metadata not found: ${meta_file}${NC}" >&2
      return 1
    fi

    # Visit dependencies first
    local dep
    while IFS= read -r dep; do
      [[ -z "$dep" ]] && continue
      visit_module "$dep"
    done < <(jq -r '.depends_on[]?' "$meta_file")

    seen["$mod_id"]=1
    resolved+=("$mod_id")
  }

  # Core is always first
  visit_module "core"
  for req in "${requested[@]}"; do
    [[ -z "$req" ]] && continue
    visit_module "$req"
  done

  printf '%s\n' "${resolved[@]}"
}

# Resolve master source (local path or git URL) into a local directory path
resolve_source_dir() {
  local source_spec="$1"
  if [[ -d "$source_spec" ]]; then
    (cd "$source_spec" && pwd)
    return 0
  fi

  local tmp_clone
  tmp_clone="$(mktemp -d -t guardrails-src-XXXXXX)"
  git clone --depth 1 "$source_spec" "$tmp_clone" >/dev/null 2>&1
  echo "$tmp_clone"
}

get_source_commit() {
  local src_dir="$1"
  if git -C "$src_dir" rev-parse --short HEAD >/dev/null 2>&1; then
    git -C "$src_dir" rev-parse --short HEAD
  else
    echo "local-uncommitted"
  fi
}

generate_lockfile() {
  local target_dir="$1"
  local lock_file="${target_dir}/.guardrails.lock"
  local -a CandidateFiles=(
    "Taskfile.yml"
    "mise.toml"
    "lefthook.yml"
    ".jscpd.json"
    "commitlint.config.mjs"
    ".secretlintrc.json"
    "AGENTS.md"
    ".agents/skills/vibe-guardrails/SKILL.md"
    "eslint.config.mjs"
    "tsconfig.base.json"
    "knip.json"
    "vitest.config.ts"
    ".dependency-cruiser.cjs"
    ".prettierrc.mjs"
    ".size-limit.json"
    "panda.config.ts"
    "stryker.config.mjs"
    "playwright.config.ts"
    ".remarkrc.mjs"
    "drizzle.config.ts"
    "ruff.toml"
    "detekt.yml"
    "pint.json"
    "phpstan.neon.dist"
    "infection.json5"
  )

  local -a existing_files=()
  for rel in "${CandidateFiles[@]}"; do
    if [[ -f "${target_dir}/${rel}" ]]; then
      existing_files+=("$rel")
    fi
  done

  if [[ -d "${target_dir}/.guardrails" ]]; then
    while IFS= read -r -d '' gf; do
      local rel_gf="${gf#"${target_dir}/"}"
      existing_files+=("$rel_gf")
    done < <(find "${target_dir}/.guardrails" -type f -print0)
  fi

  if [[ -d "${target_dir}/.agents" ]]; then
    while IFS= read -r -d '' af; do
      local rel_af="${af#"${target_dir}/"}"
      existing_files+=("$rel_af")
    done < <(find "${target_dir}/.agents" -type f -print0)
  fi

  # Sort deterministically
  mapfile -t sorted_files < <(printf '%s\n' "${existing_files[@]}" | LC_ALL=C sort -u)

  {
    echo "# ============================================================================="
    echo "# .guardrails.lock — DO NOT EDIT MANUALLY (Zero Config Drift)"
    echo "# Managed automatically by polyglot-guardrails ('task guard:sync')."
    echo "# ============================================================================="
    for rel_path in "${sorted_files[@]}"; do
      local hash
      hash="$(compute_sha256 "${target_dir}/${rel_path}")"
      printf '%s  %s\n' "$hash" "$rel_path"
    done
  } > "$lock_file"
}

apply_modules() {
  local target_dir="$1"
  local source_spec="$2"
  shift 2
  local input_modules=("$@")

  mkdir -p "$target_dir"
  target_dir="$(cd "$target_dir" && pwd)"

  local master_dir
  master_dir="$(resolve_source_dir "$source_spec")"

  mapfile -t active_modules < <(resolve_modules "$master_dir" "${input_modules[@]}")

  echo -e "${BLUE}[GUARDRAILS] Synchronizing modules: ${active_modules[*]}${NC}"

  # Clean and recreate managed .guardrails and .agents subfolders before populating
  mkdir -p \
    "${target_dir}/.guardrails/ast" \
    "${target_dir}/.guardrails/eslint" \
    "${target_dir}/.guardrails/java" \
    "${target_dir}/.guardrails/kotlin" \
    "${target_dir}/.guardrails/python" \
    "${target_dir}/.guardrails/taskfiles" \
    "${target_dir}/.guardrails/scripts" \
    "${target_dir}/.agents/rules" \
    "${target_dir}/.agents/skills"
  rm -rf \
    "${target_dir}/.guardrails/ast/"* \
    "${target_dir}/.guardrails/eslint/"* \
    "${target_dir}/.guardrails/java/"* \
    "${target_dir}/.guardrails/kotlin/"* \
    "${target_dir}/.guardrails/python/"* \
    "${target_dir}/.guardrails/taskfiles/"* \
    "${target_dir}/.agents/rules/"* \
    "${target_dir}/.agents/skills/"*

  # Compose mise.toml header
  local mise_file="${target_dir}/mise.toml"
  {
    echo "# ============================================================================="
    echo "# mise.toml — Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)"
    echo "# Active modules: ${active_modules[*]}"
    echo "# ============================================================================="
    echo "[tools]"
  } > "$mise_file"

  # Copy files and mise fragments for each module in dependency order
  for mod_id in "${active_modules[@]}"; do
    local rel_dir
    rel_dir="$(module_rel_dir "$mod_id")"
    local mod_path="${master_dir}/${rel_dir}"

    if [[ -f "${mod_path}/mise.fragment.toml" ]]; then
      echo "" >> "$mise_file"
      cat "${mod_path}/mise.fragment.toml" >> "$mise_file"
    fi

    if [[ -d "${mod_path}/files" ]]; then
      cp -R "${mod_path}/files/." "${target_dir}/"
    fi
  done

  # Synchronize centralized AST rules (universal + module-specific)
  cp "${master_dir}/rules/ast/no-linter-bypass.yml" "${target_dir}/.guardrails/ast/"
  cp "${master_dir}/rules/ast/architecture-boundaries.yml" "${target_dir}/.guardrails/ast/"

  for mod_id in "${active_modules[@]}"; do
    local short_name="${mod_id#*:}"
    if [[ -f "${master_dir}/rules/ast/${short_name}.yml" ]]; then
      cp "${master_dir}/rules/ast/${short_name}.yml" "${target_dir}/.guardrails/ast/"
    fi
  done

  # When addon:devkit is active on a meta-devkit repository (containing modules/),
  # synchronize the entire skill catalog & AST rule library for 100% parity
  if [[ -d "${target_dir}/modules" ]] && printf '%s\n' "${active_modules[@]}" | grep -qx "addon:devkit"; then
    while IFS= read -r -d '' mod_skills_dir; do
      cp -R "${mod_skills_dir}/." "${target_dir}/.agents/skills/"
    done < <(find "${master_dir}/modules" -type d -path "*/files/.agents/skills" -print0)
    cp "${master_dir}/rules/ast/"*.yml "${target_dir}/.guardrails/ast/"
  fi

  # Synchronize internal scripts atomically via mv to avoid mutating an open Bash FD
  cp "${master_dir}/scripts/verify-lock.sh" "${target_dir}/.guardrails/scripts/verify-lock.sh.tmp"
  mv -f "${target_dir}/.guardrails/scripts/verify-lock.sh.tmp" "${target_dir}/.guardrails/scripts/verify-lock.sh"
  cp "${master_dir}/scripts/guardrails-cli.sh" "${target_dir}/.guardrails/scripts/guardrails-cli.sh.tmp"
  mv -f "${target_dir}/.guardrails/scripts/guardrails-cli.sh.tmp" "${target_dir}/.guardrails/scripts/guardrails-cli.sh"
  chmod +x "${target_dir}/.guardrails/scripts/"*.sh 2>/dev/null || true

  # Write .guardrails/manifest.json
  local commit_sha
  commit_sha="$(get_source_commit "$master_dir")"
  local modules_json
  modules_json="$(printf '%s\n' "${active_modules[@]}" | jq -R . | jq -s .)"
  local manifest_source="$source_spec"
  if [[ "${target_dir}" == "${master_dir}" ]]; then
    manifest_source="."
  fi

  jq -n \
    --arg version "1.0.0" \
    --arg source "$manifest_source" \
    --arg commit "$commit_sha" \
    --argjson modules "$modules_json" \
    '{
      schema_version: $version,
      master_source: $source,
      master_commit: $commit,
      modules: $modules
    }' > "${target_dir}/.guardrails/manifest.json"

  # Generate .guardrails.lock
  generate_lockfile "$target_dir"

  echo -e "${GREEN}[GUARDRAILS] Successfully synchronized ${#active_modules[@]} module(s) and locked configuration checksums.${NC}"
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  init)
    target_dir="."
    source_spec=""
    modules_csv="core,lang:ts"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --target) target_dir="$2"; shift 2 ;;
        --source) source_spec="$2"; shift 2 ;;
        --modules) modules_csv="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
      esac
    done
    if [[ -z "$source_spec" ]]; then
      script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      source_spec="$(cd "${script_dir}/.." && pwd)"
    fi
    IFS=',' read -r -a raw_mods <<< "$modules_csv"
    apply_modules "$target_dir" "$source_spec" "${raw_mods[@]}"
    ;;

  sync)
    target_dir="."
    source_override=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --target) target_dir="$2"; shift 2 ;;
        --source) source_override="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
      esac
    done
    manifest="${target_dir}/.guardrails/manifest.json"
    if [[ ! -f "$manifest" ]]; then
      echo -e "${RED}[GUARDRAILS ERROR] Cannot sync: ${manifest} not found.${NC}" >&2
      exit 1
    fi
    source_spec="${source_override:-$(jq -r '.master_source' "$manifest")}"
    mapfile -t current_mods < <(jq -r '.modules[]' "$manifest")
    apply_modules "$target_dir" "$source_spec" "${current_mods[@]}"
    ;;

  feature-add)
    if [[ $# -lt 1 ]]; then
      echo -e "${RED}Usage: guardrails-cli.sh feature-add <module> [--target <dir>]${NC}" >&2
      exit 1
    fi
    new_mod=""
    target_dir="."
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --target) target_dir="$2"; shift 2 ;;
        *)
          if [[ -z "$new_mod" ]]; then
            new_mod="$1"
          fi
          shift
          ;;
      esac
    done
    manifest="${target_dir}/.guardrails/manifest.json"
    if [[ ! -f "$manifest" ]]; then
      echo -e "${RED}[GUARDRAILS ERROR] Cannot add feature: ${manifest} not found.${NC}" >&2
      exit 1
    fi
    canonical_mod="$(normalize_module_id "$new_mod")"
    source_spec="$(jq -r '.master_source' "$manifest")"
    mapfile -t current_mods < <(jq -r '.modules[]' "$manifest")
    current_mods+=("$canonical_mod")
    echo -e "${BLUE}[GUARDRAILS] Adding module '${canonical_mod}' to project...${NC}"
    apply_modules "$target_dir" "$source_spec" "${current_mods[@]}"
    ;;

  check)
    target_dir="."
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --target) target_dir="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${target_dir}/.guardrails/scripts/verify-lock.sh" ]]; then
      bash "${target_dir}/.guardrails/scripts/verify-lock.sh" "$target_dir"
    else
      bash "${script_dir}/verify-lock.sh" "$target_dir"
    fi
    ;;

  lock)
    target_dir="."
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --target) target_dir="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    generate_lockfile "$target_dir"
    ;;

  *)
    echo "Usage: guardrails-cli.sh {init|sync|feature-add|check|lock}"
    exit 1
    ;;
esac
