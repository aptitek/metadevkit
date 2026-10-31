#!/usr/bin/env bash
# =============================================================================
# polyglot-guardrails — Module Composition, Synchronization & Lock CLI
# Master Source: modules/core/files/.guardrails/scripts/guardrails-cli.sh
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

find_master_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  while [[ "$dir" != "/" && "$dir" != "." && ! "$dir" =~ ^[A-Za-z]:/?$ ]]; do
    if [[ -f "${dir}/modules/core/module.json" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

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
    jupyter|fw:jupyter|addon:jupyter|addons:jupyter) echo "fw:jupyter" ;;
    symfony|fw:symfony) echo "fw:symfony" ;;
    django|fw:django) echo "fw:django" ;;
    devkit|meta-devkit|guardrails|addon:devkit|addons:devkit|fw:devkit) echo "addon:devkit" ;;
    docker|addon:docker|addons:docker) echo "addon:docker" ;;
    ffmpeg|addon:ffmpeg|addons:ffmpeg) echo "addon:ffmpeg" ;;
    ui-guardrails|ui|i18n|a11y|addon:ui-guardrails|addons:ui-guardrails) echo "addon:ui-guardrails" ;;
    cloudflare|addon:cloudflare|addons:cloudflare) echo "addon:cloudflare" ;;
    design-system|addon:design-system|addons:design-system) echo "addon:design-system" ;;
    testing-fortress|addon:testing-fortress|addons:testing-fortress) echo "addon:testing-fortress" ;;
    storybook|addon:storybook|addons:storybook) echo "addon:storybook" ;;
    content-md|addon:content-md|addons:content-md) echo "addon:content-md" ;;
    drizzle-d1|addon:drizzle-d1|addons:drizzle-d1) echo "addon:drizzle-d1" ;;
    lib-exports|addon:lib-exports|addons:lib-exports) echo "addon:lib-exports" ;;
    *)
      echo -e "${RED}[GUARDRAILS ERROR] Unknown module identifier: '${raw}'${NC}" >&2
      return 1
      ;;
  esac
}

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

    local dep
    while IFS= read -r dep; do
      [[ -z "$dep" ]] && continue
      visit_module "$dep"
    done < <(jq -r '.depends_on[]?' "$meta_file")

    seen["$mod_id"]=1
    resolved+=("$mod_id")
  }

  visit_module "core"
  for req in "${requested[@]}"; do
    [[ -z "$req" ]] && continue
    visit_module "$req"
  done

  printf '%s\n' "${resolved[@]}"
}

resolve_source_dir() {
  local source_spec="$1"
  if [[ -d "$source_spec" ]]; then
    (cd "$source_spec" && pwd)
    return 0
  fi

  local tmp_clone
  tmp_clone="$(mktemp -d -t guardrails-src-XXXXXX)"
  git clone --depth 1 -c core.autocrlf=false "$source_spec" "$tmp_clone" >/dev/null 2>&1
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
    ".gitignore"
    ".gitattributes"
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
    "deptrac.yaml"
    ".djlintrc"
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

  # Clean and recreate managed .guardrails and .agents subfolders before populating.
  # Unlinking .guardrails/scripts/* first ensures running scripts keep their old FD cleanly.
  rm -rf \
    "${target_dir}/.guardrails/ast" \
    "${target_dir}/.guardrails/content-md" \
    "${target_dir}/.guardrails/depcruise" \
    "${target_dir}/.guardrails/eslint" \
    "${target_dir}/.guardrails/java" \
    "${target_dir}/.guardrails/kotlin" \
    "${target_dir}/.guardrails/python" \
    "${target_dir}/.guardrails/taskfiles" \
    "${target_dir}/.guardrails/scripts" \
    "${target_dir}/.agents/rules" \
    "${target_dir}/.agents/skills"
  mkdir -p \
    "${target_dir}/.guardrails/ast" \
    "${target_dir}/.guardrails/taskfiles" \
    "${target_dir}/.guardrails/scripts" \
    "${target_dir}/.agents/rules" \
    "${target_dir}/.agents/skills"

  # Remove TS-only root configs if lang:ts is not active
  if ! printf '%s\n' "${active_modules[@]}" | grep -qx "lang:ts"; then
    rm -f \
      "${target_dir}/playwright.config.ts" \
      "${target_dir}/stryker.config.mjs" \
      "${target_dir}/commitlint.config.mjs" \
      "${target_dir}/.secretlintrc.json" \
      "${target_dir}/.jscpd.json" \
      "${target_dir}/.size-limit.json"
  fi

  # Remove .size-limit.json if neither fw:react nor fw:astro is active
  if ! printf '%s\n' "${active_modules[@]}" | grep -qxE "fw:(react|astro)"; then
    rm -f "${target_dir}/.size-limit.json"
  fi

  # Compose mise.toml header
  local mise_file="${target_dir}/mise.toml"
  {
    echo "# ============================================================================="
    echo "# mise.toml — Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)"
    echo "# Active modules: ${active_modules[*]}"
    echo "# ============================================================================="
    echo "[tools]"
  } > "$mise_file"

  # Compose .gitignore header
  local gitignore_file="${target_dir}/.gitignore"
  {
    echo "# ============================================================================="
    echo "# .gitignore — Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)"
    echo "# Active modules: ${active_modules[*]}"
    echo "# For project-specific ignore rules, create '.gitignore.local'."
    echo "# ============================================================================="
  } > "$gitignore_file"

  # Initialize dynamic AGENTS.md
  local agents_file="${target_dir}/AGENTS.md"
  : > "$agents_file"

  local has_ts=0
  if printf '%s\n' "${active_modules[@]}" | grep -qx "lang:ts"; then
    has_ts=1
  fi

  # Copy files, mise fragments, gitignore fragments, and AGENTS fragments ONLY for active modules
  for mod_id in "${active_modules[@]}"; do
    local rel_dir
    rel_dir="$(module_rel_dir "$mod_id")"
    local mod_path="${master_dir}/${rel_dir}"

    if [[ -f "${mod_path}/mise.fragment.toml" ]]; then
      echo "" >> "$mise_file"
      cat "${mod_path}/mise.fragment.toml" >> "$mise_file"
    fi

    if [[ -f "${mod_path}/gitignore.fragment" ]]; then
      echo "" >> "$gitignore_file"
      cat "${mod_path}/gitignore.fragment" >> "$gitignore_file"
    fi

    if [[ -f "${mod_path}/AGENTS.fragment.md" ]]; then
      if [[ -s "$agents_file" ]]; then
        echo "" >> "$agents_file"
      fi
      cat "${mod_path}/AGENTS.fragment.md" >> "$agents_file"
    fi

    if [[ -d "${mod_path}/files" ]]; then
      cp -R "${mod_path}/files/." "${target_dir}/"
    fi

    # Copy TypeScript-specific testing-fortress overlay ONLY when lang:ts is active
    if [[ "${mod_id}" == "addon:testing-fortress" && "${has_ts}" -eq 1 && -d "${mod_path}/ts-files" ]]; then
      cp -R "${mod_path}/ts-files/." "${target_dir}/"
    fi
  done

  if [[ -f "${target_dir}/.gitignore.local" ]]; then
    echo "" >> "$gitignore_file"
    echo "# --- Project-specific (.gitignore.local) ---" >> "$gitignore_file"
    cat "${target_dir}/.gitignore.local" >> "$gitignore_file"
  fi

  # Dynamically generate self-bootstrapping Taskfile.yml for ONLY the active modules
  local taskfile="${target_dir}/Taskfile.yml"
  {
    echo "# ============================================================================="
    echo "# Taskfile.yml — Universal Bootstrap & Polyglot Guardrails Contract"
    echo "# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)"
    echo "# Active modules: ${active_modules[*]}"
    echo "# For project-specific tasks or variables, create 'Taskfile.local.yml'."
    echo "#"
    echo "# Universal One-Liner Bootstrap (Linux / macOS / Windows MSYS2 / Git Bash):"
    echo "#   curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash -s -- python,django"
    echo "#   curl -fsSLO https://raw.githubusercontent.com/aptitek/metadevkit/main/Taskfile.yml && task init MODULES=python,django"
    echo "# Windows PowerShell (Auto-installs MSYS2 + go-task + mise + initializes project):"
    echo "#   irm https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.ps1 | iex"
    echo "# ============================================================================="
    echo "version: '3'"
    echo ""
    echo "vars:"
    echo "  MODULES: '{{.MODULES | default \"core,lang:ts\"}}'"
    echo "  REPO_URL: '{{.REPO_URL | default \"https://github.com/aptitek/metadevkit.git\"}}'"
    echo ""
    echo "includes:"
    echo "  base:"
    echo "    taskfile: ./.guardrails/taskfiles/Taskfile.base.yml"
    echo "    flatten: true"
    echo "    optional: true"
    for mod_id in "${active_modules[@]}"; do
      [[ "${mod_id}" == "core" ]] && continue
      local short="${mod_id#*:}"
      if [[ -f "${target_dir}/.guardrails/taskfiles/Taskfile.${short}.yml" ]]; then
        echo "  ${short}:"
        echo "    taskfile: ./.guardrails/taskfiles/Taskfile.${short}.yml"
        echo "    optional: true"
      fi
    done
    echo "  local:"
    echo "    taskfile: ./Taskfile.local.yml"
    echo "    optional: true"
    echo ""
    echo "tasks:"
    echo "  default:"
    echo "    desc: \"Bootstrap project if uninitialized, otherwise run full verification suite\""
    echo "    cmds:"
    echo "      - |"
    echo "        if [ ! -f ./.guardrails/manifest.json ]; then"
    echo "          {{.TASK_EXE}} bootstrap MODULES=\"{{.MODULES}}\" REPO_URL=\"{{.REPO_URL}}\""
    echo "        else"
    echo "          {{.TASK_EXE}} verify"
    echo "        fi"
    echo ""
    echo "  bootstrap:"
    echo "    desc: \"Auto-install prerequisites (MSYS2 on Windows, mise, jq, git) and initialize project from remote master\""
    echo "    cmds:"
    echo "      - |"
    echo "        if [ \"\${OS:-}\" = \"Windows_NT\" ] || uname -s 2>/dev/null | grep -qiE \"mingw|msys|cygwin\"; then"
    echo "          if [ ! -x \"/c/msys64/usr/bin/bash.exe\" ] && [ ! -x \"C:/msys64/usr/bin/bash.exe\" ] && command -v winget.exe >/dev/null 2>&1; then"
    echo "            winget.exe install -e --id MSYS2.MSYS2 --accept-source-agreements --accept-package-agreements || true"
    echo "          fi"
    echo "          for msys_bin in \"/c/msys64/usr/bin\" \"C:/msys64/usr/bin\"; do"
    echo "            if [ -d \"\$msys_bin\" ]; then"
    echo "              export PATH=\"\${msys_bin}:\${PATH}\""
    echo "              if [ -x \"\${msys_bin}/pacman.exe\" ]; then"
    echo "                \"\${msys_bin}/pacman.exe\" -S --noconfirm --needed bash git jq curl tar || true"
    echo "              fi"
    echo "              break"
    echo "            fi"
    echo "          done"
    echo "        fi"
    echo "        if ! command -v mise >/dev/null 2>&1; then"
    echo "          if command -v winget.exe >/dev/null 2>&1; then"
    echo "            winget.exe install -e --id jdx.mise --accept-source-agreements --accept-package-agreements || true"
    echo "          elif command -v brew >/dev/null 2>&1; then"
    echo "            brew install mise || true"
    echo "          elif command -v curl >/dev/null 2>&1; then"
    echo "            mise_tmp=\"\$(mktemp -d)\""
    echo "            curl -fsSL https://mise.run -o \"\${mise_tmp}/install.sh\" && sh \"\${mise_tmp}/install.sh\" || true"
    echo "            rm -rf \"\${mise_tmp}\""
    echo "            export PATH=\"\${HOME}/.local/bin:\${PATH}\""
    echo "          fi"
    echo "        fi"
    echo "        if [ -d \"{{.REPO_URL}}/modules/core\" ]; then"
    echo "          GUARDRAILS_ORIGIN_URL=\"{{.REPO_URL}}\" bash \"{{.REPO_URL}}/modules/core/files/.guardrails/scripts/guardrails-cli.sh\" init --target \".\" --source \"{{.REPO_URL}}\" --modules \"{{.MODULES}}\" {{.CLI_ARGS}}"
    echo "        else"
    echo "          tmp_src=\"\$(mktemp -d)\""
    echo "          trap 'rm -rf \"\${tmp_src}\"' EXIT"
    echo "          git clone --depth 1 -c core.autocrlf=false \"{{.REPO_URL}}\" \"\${tmp_src}\""
    echo "          GUARDRAILS_ORIGIN_URL=\"{{.REPO_URL}}\" bash \"\${tmp_src}/modules/core/files/.guardrails/scripts/guardrails-cli.sh\" init --target \".\" --source \"\${tmp_src}\" --modules \"{{.MODULES}}\" {{.CLI_ARGS}}"
    echo "        fi"
    echo "        if command -v mise >/dev/null 2>&1; then"
    echo "          mise trust -a || true"
    echo "          mise install || true"
    echo "        fi"
    echo ""
    echo "  init:"
    echo "    desc: \"Initialize or convert a project (auto-bootstraps from remote if .guardrails is absent)\""
    echo "    cmds:"
    echo "      - |"
    echo "        if [ -f ./.guardrails/scripts/guardrails-cli.sh ]; then"
    echo "          if [ -n \"{{.CLI_ARGS}}\" ]; then"
    echo "            bash ./.guardrails/scripts/guardrails-cli.sh init {{.CLI_ARGS}}"
    echo "          else"
    echo "            bash ./.guardrails/scripts/guardrails-cli.sh init --target \".\" --modules \"{{.MODULES}}\""
    echo "          fi"
    echo "        else"
    echo "          {{.TASK_EXE}} bootstrap MODULES=\"{{.MODULES}}\" REPO_URL=\"{{.REPO_URL}}\" CLI_ARGS=\"{{.CLI_ARGS}}\""
    echo "        fi"
  } > "$taskfile"

  chmod +x "${target_dir}/.guardrails/scripts/"*.sh 2>/dev/null || true

  # Write .guardrails/manifest.json
  local commit_sha
  commit_sha="$(get_source_commit "$master_dir")"
  local modules_json
  modules_json="$(printf '%s\n' "${active_modules[@]}" | jq -R . | jq -s .)"
  local manifest_source="${GUARDRAILS_ORIGIN_URL:-$source_spec}"
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
      source_spec="$(find_master_root)"
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
