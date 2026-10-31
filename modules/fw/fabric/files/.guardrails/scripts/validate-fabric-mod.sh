#!/usr/bin/env bash
# =============================================================================
# validate-fabric-mod.sh — Fabric MC (fabric.mod.json & Fabric Loom) Gate
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT="${1:-.}"
FAILURES=0

fail() {
  echo "[FABRIC GATE ERROR] $*" >&2
  FAILURES=$((FAILURES + 1))
}

while IFS= read -r -d '' fmj; do
  rel="${fmj#"$ROOT/"}"
  res_dir="$(dirname "$fmj")"

  if ! jq empty "$fmj" >/dev/null 2>&1; then
    fail "Invalid JSON in ${rel}"
    continue
  fi

  if ! jq -e '.schemaVersion == 1' "$fmj" >/dev/null 2>&1; then
    fail "${rel}: 'schemaVersion' must be 1"
  fi

  if ! jq -e '.id | type == "string" and test("^[a-z][a-z0-9_-]{1,63}$")' "$fmj" >/dev/null 2>&1; then
    fail "${rel}: 'id' must match ^[a-z][a-z0-9_-]{1,63}$"
  fi

  if ! jq -e '.version | type == "string" and length > 0' "$fmj" >/dev/null 2>&1; then
    fail "${rel}: 'version' must be a non-empty string (e.g. \"\${version}\")"
  fi

  if ! jq -e '.name | type == "string" and length > 0' "$fmj" >/dev/null 2>&1; then
    fail "${rel}: 'name' is required"
  fi

  if ! jq -e '.license | (type == "string" and length > 0) or (type == "array" and length > 0)' "$fmj" >/dev/null 2>&1; then
    fail "${rel}: 'license' is required"
  fi

  if ! jq -e '.environment == "*" or .environment == "client" or .environment == "server"' "$fmj" >/dev/null 2>&1; then
    fail "${rel}: 'environment' must be '*', 'client', or 'server'"
  fi

  if ! jq -e '(.depends.fabricloader != null or .depends["quilt_loader"] != null) and .depends.minecraft != null' "$fmj" >/dev/null 2>&1; then
    fail "${rel}: 'depends' must declare 'fabricloader' and 'minecraft'"
  fi

  while IFS= read -r mixin_cfg; do
    [[ -z "$mixin_cfg" ]] && continue
    if [[ ! -f "${res_dir}/${mixin_cfg}" ]]; then
      fail "${rel}: declared mixin config '${mixin_cfg}' does not exist at ${res_dir}/${mixin_cfg}"
    fi
  done < <(jq -r '(.mixins // [])[] | if type == "object" then .config else . end' "$fmj")
done < <(find "$ROOT" -type f -name "fabric.mod.json" -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

if [[ -f "${ROOT}/gradle.properties" ]]; then
  if ! grep -Eq '^minecraft_version=[^[:space:]]+' "${ROOT}/gradle.properties"; then
    fail "gradle.properties is missing 'minecraft_version='"
  fi
fi

if [[ "$FAILURES" -gt 0 ]]; then
  echo "[FABRIC GATE] Failed with ${FAILURES} error(s)." >&2
  exit 1
fi

echo "[FABRIC GATE] All fabric.mod.json descriptors and Fabric Loom properties are valid."
