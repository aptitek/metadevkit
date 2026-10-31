#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Universal Zero-Prerequisite One-Liner Project Bootstrapper
# Supports: Linux, macOS, and Windows (MSYS2 / Git Bash / WSL)
#
# One-Liner Usage:
#   curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash -s -- python,django
#   curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash -s -- ts,react,design-system
# =============================================================================
set -euo pipefail

main() {
  local modules="${1:-${MODULES:-core,lang:ts}}"
  local repo_url="${REPO_URL:-https://github.com/aptitek/metadevkit.git}"
  local raw_taskfile_url="${RAW_TASKFILE_URL:-https://raw.githubusercontent.com/aptitek/metadevkit/main/Taskfile.yml}"

  echo "🚀 [polyglot-guardrails] Bootstrapping project with modules: ${modules}"

  # 1. Windows / MSYS2 / Git Bash environment detection & auto-provisioning
  if [[ "${OS:-}" == "Windows_NT" ]] || uname -s 2>/dev/null | grep -qiE "mingw|msys|cygwin"; then
    if [[ ! -x "/c/msys64/usr/bin/bash.exe" && ! -x "C:/msys64/usr/bin/bash.exe" ]] && command -v winget.exe >/dev/null 2>&1; then
      echo "📦 [Windows] Installing MSYS2 via winget..."
      winget.exe install -e --id MSYS2.MSYS2 --accept-source-agreements --accept-package-agreements </dev/null || true
    fi
    for msys_bin in "/c/msys64/usr/bin" "C:/msys64/usr/bin"; do
      if [[ -d "${msys_bin}" ]]; then
        export PATH="${msys_bin}:${PATH}"
        if [[ -x "${msys_bin}/pacman.exe" ]]; then
          echo "📦 [MSYS2] Ensuring bash, git, jq, curl, and tar are installed..."
          "${msys_bin}/pacman.exe" -S --noconfirm --needed bash git jq curl tar </dev/null || true
        fi
        break
      fi
    done
    if ! command -v task >/dev/null 2>&1 && ! command -v go-task >/dev/null 2>&1 && command -v winget.exe >/dev/null 2>&1; then
      echo "📦 [Windows] Installing go-task via winget..."
      winget.exe install -e --id Task.Task --accept-source-agreements --accept-package-agreements </dev/null || true
    fi
  fi

  # 2. Ensure mise is available (cross-platform toolchain manager)
  if ! command -v mise >/dev/null 2>&1; then
    if command -v winget.exe >/dev/null 2>&1; then
      winget.exe install -e --id jdx.mise --accept-source-agreements --accept-package-agreements </dev/null || true
    elif command -v brew >/dev/null 2>&1; then
      brew install mise </dev/null || true
    elif command -v curl >/dev/null 2>&1; then
      local mise_tmp
      mise_tmp="$(mktemp -d)"
      curl -fsSL "https://mise.run" -o "${mise_tmp}/install-mise.sh"
      sh "${mise_tmp}/install-mise.sh" </dev/null || true
      rm -rf "${mise_tmp}"
      export PATH="${HOME}/.local/bin:${HOME}/.local/share/mise/shims:${PATH}"
    fi
  fi

  # 3. Ensure task (go-task) and jq are available via mise if not already on PATH
  if command -v mise >/dev/null 2>&1; then
    if ! command -v task >/dev/null 2>&1 && ! command -v go-task >/dev/null 2>&1; then
      mise use -g "go-task@3.42" </dev/null || true
    fi
    if ! command -v jq >/dev/null 2>&1; then
      mise use -g "jq@1.7" </dev/null || true
    fi
    export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:${PATH}"
  fi

  # 4. Download master self-bootstrapping Taskfile.yml & delegate to task init
  local task_bin=""
  if command -v task >/dev/null 2>&1; then
    task_bin="task"
  elif command -v go-task >/dev/null 2>&1; then
    task_bin="go-task"
  fi

  if [[ -n "${task_bin}" ]]; then
    if [[ ! -f "Taskfile.yml" ]] && command -v curl >/dev/null 2>&1; then
      curl -fsSL "${raw_taskfile_url}" -o Taskfile.yml
    fi
    if [[ -f "Taskfile.yml" ]]; then
      "${task_bin}" init MODULES="${modules}" REPO_URL="${repo_url}" </dev/null
      return 0
    fi
  fi

  # 5. Fallback direct bootstrap if task binary is not yet in current shell PATH
  if [[ -d "${repo_url}/modules/core" ]]; then
    GUARDRAILS_ORIGIN_URL="${repo_url}" bash "${repo_url}/modules/core/files/.guardrails/scripts/guardrails-cli.sh" \
      init --target "." --source "${repo_url}" --modules "${modules}" </dev/null
  else
    local tmp_src
    tmp_src="$(mktemp -d)"
    trap 'rm -rf "${tmp_src}"' EXIT
    git clone --depth 1 -c core.autocrlf=false "${repo_url}" "${tmp_src}" </dev/null
    GUARDRAILS_ORIGIN_URL="${repo_url}" bash "${tmp_src}/modules/core/files/.guardrails/scripts/guardrails-cli.sh" \
      init --target "." --source "${tmp_src}" --modules "${modules}" </dev/null
  fi

  if command -v mise >/dev/null 2>&1; then
    mise trust -a </dev/null || true
    mise install </dev/null || true
  fi
}

main "$@"
