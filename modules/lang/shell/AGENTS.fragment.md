### `lang:shell` — Defensive Bash & Shell Scripting Fortress
- **Quality Gates**: Every `.sh` file must include `set -euo pipefail`, pass `bash -n` syntax verification and `shellcheck` / `shfmt`, quote variable expansions, and never use `eval` or `curl | sh`.
