#!/usr/bin/env bash
# =============================================================================
# validate-shell.sh — Defensive Bash & Shell Script AST Quality Gate (lang:shell)
# Enforces:
#   1. Valid shebang (#!/usr/bin/env bash or #!/bin/sh)
#   2. Mandatory strict mode 'set -euo pipefail' in all bash scripts
#   3. Syntax verification via 'bash -n'
#   4. AST / Lexer-level ban on 'eval', 'sudo', and remote pipe-to-shell
#      ('curl|wget ... | sh|bash'), ignoring comments and multiline strings
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT_DIR="${1:-.}"
ERRORS=0
HAS_SHFMT=0
if command -v shfmt >/dev/null 2>&1; then
  HAS_SHFMT=1
fi

# Strip quoted string contents ('...' and "...", preserving state across multiline strings)
# and # comments outside quotes so string literals never cause false positives or false negatives.
strip_shell_quotes_and_comments() {
  local file="$1"
  awk '
  BEGIN {
    in_sq = 0
    in_dq = 0
  }
  {
    line = $0
    out = ""
    i = 1
    len = length(line)
    while (i <= len) {
      c = substr(line, i, 1)
      if (in_sq) {
        if (c == "\047") { in_sq = 0; out = out "\047" }
        i++
      } else if (in_dq) {
        if (c == "\\") { i += 2; continue }
        if (c == "\"") { in_dq = 0; out = out "\"" }
        i++
      } else {
        if (c == "\\") {
          out = out substr(line, i, 2)
          i += 2
          continue
        }
        if (c == "\047") { in_sq = 1; out = out "\047"; i++; continue }
        if (c == "\"") { in_dq = 1; out = out "\""; i++; continue }
        if (c == "#" && (i == 1 || substr(line, i - 1, 1) ~ /[ \t;|&(]/)) {
          break
        }
        out = out c
        i++
      }
    }
    print out
  }' "$file"
}

check_shell_tokens_fallback() {
  local sh_file="$1"
  local stripped="$2"

  if grep -E -q '(^|[;|&({[:space:]])((builtin|command|env)[[:space:]]+)?(eval|sudo)[[:space:]]+' <<< "$stripped"; then
    echo "❌ [SHELL AST GATE] ${sh_file}: Forbidden 'eval' or 'sudo' statement detected." >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -E -q '(^|[;|&({[:space:]])([^[:space:]|;]*/)?(curl|wget)[[:space:]]+[^;]*\|[[:space:]]*((builtin|command|env)[[:space:]]+)?([^[:space:]|;]*/)?(ba)?sh\b' <<< "$stripped"; then
    echo "❌ [SHELL AST GATE] ${sh_file}: Forbidden remote pipe-to-shell detected." >&2
    ERRORS=$((ERRORS + 1))
  fi
}

check_shell_ast_with_shfmt() {
  local sh_file="$1"
  local stripped="$2"
  local ast_json
  if ! ast_json="$(shfmt -tojson "${sh_file}" 2>/dev/null)"; then
    check_shell_tokens_fallback "${sh_file}" "$stripped"
    return 0
  fi

  # 1. Detect eval or sudo (even via builtin/command/env)
  if printf '%s' "$ast_json" | jq -e '
    [.. | objects | select(.Type == "CallExpr")
      | [ .Args[]?.Parts[0]? | select(.Type == "Lit") | .Value ]
      | select(
          (.[0]? == "eval" or .[0]? == "sudo") or
          ((.[0]? == "builtin" or .[0]? == "command" or .[0]? == "env") and (.[1]? == "eval" or .[1]? == "sudo"))
        )
    ] | length > 0
  ' >/dev/null 2>&1; then
    echo "❌ [SHELL AST GATE] ${sh_file}: Forbidden 'eval' or 'sudo' CallExpr detected in AST." >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Detect any pipeline (BinaryCmd Op 12) containing curl/wget on the left and sh/bash on the right
  if printf '%s' "$ast_json" | jq -e '
    def call_names($node):
      [ $node | .. | objects | select(.Type == "CallExpr") | .Args[]?.Parts[0]?.Value? // empty ];
    [.. | objects | select(.Type == "BinaryCmd" and .Op == 12)
      | select(
          (call_names(.X) | any(test("(^|/)(curl|wget)$"))) and
          (call_names(.Y) | any(test("(^|/)(ba)?sh$")))
        )
    ] | length > 0
  ' >/dev/null 2>&1; then
    echo "❌ [SHELL AST GATE] ${sh_file}: Forbidden remote pipe-to-shell (curl/wget | sh/bash) BinaryCmd detected in AST." >&2
    ERRORS=$((ERRORS + 1))
  fi
}

while IFS= read -r -d '' sh_file; do
  # 1. Shebang check
  first_line="$(head -n 1 "${sh_file}")"
  if [[ "${first_line}" != "#!/usr/bin/env bash" && "${first_line}" != "#!/bin/bash" && "${first_line}" != "#!/bin/sh" ]]; then
    echo "❌ [SHELL GATE] ${sh_file}: Missing valid shebang ('#!/usr/bin/env bash' expected)." >&2
    ERRORS=$((ERRORS + 1))
  fi

  stripped_content="$(strip_shell_quotes_and_comments "${sh_file}")"

  # 2. Strict mode check for bash scripts (ignoring comments and multiline quoted strings)
  if [[ "${first_line}" == *"bash"* ]]; then
    if ! grep -E -q '^[[:space:]]*set[[:space:]]+-euo[[:space:]]+pipefail\b' <<< "$stripped_content"; then
      echo "❌ [SHELL GATE] ${sh_file}: Missing mandatory strict mode 'set -euo pipefail'." >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # 3. Syntax check via bash -n
  if ! bash -n "${sh_file}" 2>/dev/null; then
    echo "❌ [SHELL GATE] ${sh_file}: Failed 'bash -n' syntax check." >&2
    bash -n "${sh_file}" >&2 || true
    ERRORS=$((ERRORS + 1))
  fi

  # 4. AST check via shfmt -tojson + jq (with fail-closed quote-aware lexer fallback)
  if [[ "$HAS_SHFMT" -eq 1 ]]; then
    check_shell_ast_with_shfmt "${sh_file}" "$stripped_content"
  else
    check_shell_tokens_fallback "${sh_file}" "$stripped_content"
  fi
done < <(find "${ROOT_DIR}" \
  -type d \( -name ".git" -o -name "node_modules" -o -name ".venv" -o -name "venv" -o -name "dist" -o -name "build" \) -prune \
  -o -type f -name "*.sh" -print0)

if [[ "${ERRORS}" -gt 0 ]]; then
  echo "🚫 [SHELL GATE] Failed with ${ERRORS} shell script violation(s)." >&2
  exit 1
fi

echo "✅ [SHELL GATE] All shell scripts passed strict mode, syntax & AST security checks."
