#!/usr/bin/env bash
# =============================================================================
# validate-quilt-mod.sh — Quilt MC (quilt.mod.json & Quilt Loom) Gate
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT="${1:-.}"
FAILURES=0

fail() {
  echo "[QUILT GATE ERROR] $*" >&2
  FAILURES=$((FAILURES + 1))
}

while IFS= read -r -d '' qmj; do
  rel="${qmj#"$ROOT/"}"
  res_dir="$(dirname "$qmj")"

  if ! jq empty "$qmj" >/dev/null 2>&1; then
    fail "Invalid JSON in ${rel}"
    continue
  fi

  if ! jq -e '.schema_version == 1' "$qmj" >/dev/null 2>&1; then
    fail "${rel}: 'schema_version' must be 1"
  fi

  if ! jq -e '.quilt_loader.id | type == "string" and test("^[a-z][a-z0-9_]{1,63}$")' "$qmj" >/dev/null 2>&1; then
    fail "${rel}: 'quilt_loader.id' must match ^[a-z][a-z0-9_]{1,63}$"
  fi

  if ! jq -e '.quilt_loader.version | type == "string" and length > 0' "$qmj" >/dev/null 2>&1; then
    fail "${rel}: 'quilt_loader.version' must be a non-empty string (e.g. \"\${version}\")"
  fi

  if ! jq -e '.quilt_loader.metadata.name | type == "string" and length > 0' "$qmj" >/dev/null 2>&1; then
    fail "${rel}: 'quilt_loader.metadata.name' is required"
  fi

  if ! jq -e '.quilt_loader.metadata.license | (type == "string" and length > 0) or (type == "array" and length > 0)' "$qmj" >/dev/null 2>&1; then
    fail "${rel}: 'quilt_loader.metadata.license' is required"
  fi

  if ! jq -e '.quilt_loader.intermediate_mappings == "net.fabricmc:intermediary"' "$qmj" >/dev/null 2>&1; then
    fail "${rel}: 'quilt_loader.intermediate_mappings' must be 'net.fabricmc:intermediary'"
  fi

  while IFS= read -r mixin_cfg; do
    [[ -z "$mixin_cfg" ]] && continue
    if [[ ! -f "${res_dir}/${mixin_cfg}" ]]; then
      fail "${rel}: declared mixin config '${mixin_cfg}' does not exist at ${res_dir}/${mixin_cfg}"
    fi
  done < <(jq -r '(.mixin // empty) | if type == "array" then .[] else . end' "$qmj")
done < <(find "$ROOT" -type f -name "quilt.mod.json" -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

if [[ -f "${ROOT}/gradle.properties" ]]; then
  if ! grep -Eq '^minecraft_version=[^[:space:]]+' "${ROOT}/gradle.properties"; then
    fail "gradle.properties is missing 'minecraft_version='"
  fi
fi

if [[ "$FAILURES" -gt 0 ]]; then
  echo "[QUILT GATE] Failed with ${FAILURES} error(s)." >&2
  exit 1
fi

echo "[QUILT GATE] All quilt.mod.json descriptors and Quilt Loom properties are valid."
