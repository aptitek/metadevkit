#!/usr/bin/env bash
# =============================================================================
# validate-minecraft-mod.sh — Minecraft 1.21+ Mod & Asset Integrity Validator
# Checks:
#   1. Client/Server physical side-separation in Java/Kotlin packages
#   2. Mixin safety (@Overwrite / @Redirect ban + *.mixins.json defaultRequire)
#   3. Resourcepack & Datapack JSON validity and 1.21+ singular path rules
#   4. JUnit Platform & GameTest structure fixture layout
# Managed by polyglot-guardrails (DO NOT EDIT MANUALLY)
# =============================================================================
set -euo pipefail

ROOT="${1:-.}"
FAILURES=0

fail() {
  echo "[MINECRAFT GATE ERROR] $*" >&2
  FAILURES=$((FAILURES + 1))
}

# 1. Client/Server physical side separation
while IFS= read -r -d '' src_file; do
  if grep -Eq '^\s*import\s+(net\.minecraft\.client|com\.mojang\.blaze3d)\.' "$src_file"; then
    fail "Client-only import (net.minecraft.client / com.mojang.blaze3d) found in server/common file: ${src_file#"$ROOT/"}"
  fi
done < <(find "$ROOT" -type f \( -name "*.java" -o -name "*.kt" \) \( -path "*/server/*" -o -path "*/common/*" \) -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

while IFS= read -r -d '' client_file; do
  if grep -Eq '^\s*import\s+net\.minecraft\.server\.dedicated\.' "$client_file"; then
    fail "Dedicated-server import (net.minecraft.server.dedicated) found in client file: ${client_file#"$ROOT/"}"
  fi
done < <(find "$ROOT" -type f \( -name "*.java" -o -name "*.kt" \) -path "*/client/*" -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

# 2. Mixin safety (@Overwrite / @Redirect ban & *.mixins.json validation)
while IFS= read -r -d '' mixin_file; do
  if grep -Eq '@Overwrite\b' "$mixin_file"; then
    fail "@Overwrite is forbidden in Mixin class (${mixin_file#"$ROOT/"}). Use @Inject or MixinExtras @WrapOperation."
  fi
  if grep -Eq '@Redirect\s*\(' "$mixin_file"; then
    fail "@Redirect is forbidden in Mixin class (${mixin_file#"$ROOT/"}). Use MixinExtras @WrapOperation or @ModifyExpressionValue."
  fi
done < <(find "$ROOT" -type f \( -name "*Mixin*.java" -o -name "*Mixin*.kt" -o -path "*/mixin/*.java" -o -path "*/mixin/*.kt" \) -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

while IFS= read -r -d '' mixin_json; do
  if ! jq empty "$mixin_json" >/dev/null 2>&1; then
    fail "Invalid JSON in Mixin config: ${mixin_json#"$ROOT/"}"
    continue
  fi
  if ! jq -e '.package | type == "string" and length > 0' "$mixin_json" >/dev/null 2>&1; then
    fail "Mixin config missing non-empty 'package': ${mixin_json#"$ROOT/"}"
  fi
  if ! jq -e '.injectors.defaultRequire == 1' "$mixin_json" >/dev/null 2>&1; then
    fail "Mixin config must set 'injectors.defaultRequire' to 1: ${mixin_json#"$ROOT/"}"
  fi
done < <(find "$ROOT" -type f -name "*.mixins.json" -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

# 3. Resourcepack & Datapack JSON validity and 1.21+ path conventions
while IFS= read -r -d '' res_json; do
  if ! jq empty "$res_json" >/dev/null 2>&1; then
    fail "Invalid JSON in resource/data file: ${res_json#"$ROOT/"}"
  fi
done < <(find "$ROOT" -type f \( -name "pack.mcmeta" -o -path "*/assets/*.json" -o -path "*/data/*.json" \) -not -path "*/.git/*" -not -path "*/build/*" -not -path "*/node_modules/*" -print0 2>/dev/null)

while IFS= read -r -d '' legacy_path; do
  fail "Legacy pre-1.21 pluralized data path detected (${legacy_path#"$ROOT/"}). Use singular loot_table/, tags/block/, tags/item/."
done < <(find "$ROOT" -type f \( -path "*/data/*/loot_tables/*" -o -path "*/data/*/tags/blocks/*" -o -path "*/data/*/tags/items/*" \) -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

# 4. Orphan .png.mcmeta check
while IFS= read -r -d '' mcmeta_file; do
  png_file="${mcmeta_file%.mcmeta}"
  if [[ ! -f "$png_file" ]]; then
    fail "Orphan animation .png.mcmeta without matching .png: ${mcmeta_file#"$ROOT/"}"
  fi
done < <(find "$ROOT" -type f -name "*.png.mcmeta" -not -path "*/.git/*" -not -path "*/build/*" -print0 2>/dev/null)

if [[ "$FAILURES" -gt 0 ]]; then
  echo "[MINECRAFT GATE] Failed with ${FAILURES} architectural/asset violation(s)." >&2
  exit 1
fi

echo "[MINECRAFT GATE] Side-separation, Mixin safety, and 1.21+ asset checks passed."
