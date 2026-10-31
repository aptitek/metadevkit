---
name: shell-guardrails
description: "Write defensive Bash CLI scripts enforcing set -euo pipefail, bash -n syntax, safe quoting, trap cleanup, and zero eval."
---

# Defensive Bash & Shell Guardrails (`lang:shell`)

## 1. Hard Shell Gates (`validate-shell.sh` + `shell.yml`)
| Gate | Requirement |
| :--- | :--- |
| **Shebang** | Start every executable script with `#!/usr/bin/env bash` |
| **Strict Mode** | Include `set -euo pipefail` before any command execution |
| **Quoting & Arrays** | Quote all parameter expansions (`"${var}"`, `"${arr[@]}"`); use bash arrays instead of word-splitting strings |
| **Temp Workspace** | Create temp directories via `mktemp -d` and register `trap cleanup EXIT` immediately |
| **Security Bans** | `eval`, `sudo`, and `curl ... \| bash` are strictly forbidden |
| **Syntax Gate** | Every `.sh` file must pass `bash -n` and `.guardrails/scripts/validate-shell.sh .` |

## 2. Canonical Defensive Script Skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d -t guardrails-XXXXXX)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT
```
