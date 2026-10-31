#!/usr/bin/env bash
# =============================================================================
# polyglot-guardrails — End-to-End Automated Integration Test (`task self-test`)
# Tests:
#   1. Project generation with lang:ts + fw:react
#   2. Dynamic addon addition via `task feature:add` (cloudflare, design-system,
#      testing-fortress, storybook, content-md, drizzle-d1, lib-exports)
#   3. Integrity verification via `task guard:check`
#   4. Anti-tamper detection on illegal edit of `eslint.config.mjs`
#   5. Self-healing via `task guard:sync` & Taskfile.local.yml boundary checks
#   6. AST anti-bypass enforcement & full `task verify` pipeline
#   7. JVM & Minecraft Modding stack (`lang:kotlin`, `lang:java`, `fw:minecraft`,
#      `fw:quilt`, `fw:fabric`) with Detekt, Client/Server side separation,
#      Mixin safety, and `quilt.mod.json` / `fabric.mod.json` validation
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

TMP_WORKSPACE="$(mktemp -d -t polyglot-guardrails-selftest-XXXXXX)"
TMP_BIN="${TMP_WORKSPACE}/.bin"
TMP_PROJECT="${TMP_WORKSPACE}/sample-react-app"
TMP_MC_PROJECT="${TMP_WORKSPACE}/sample-stellar-mod"
TMP_PY_PROJECT="${TMP_WORKSPACE}/sample-geranium-studio"

cleanup() {
  rm -rf "$TMP_WORKSPACE"
}
trap cleanup EXIT

mkdir -p "$TMP_BIN" "$TMP_PROJECT" "$TMP_MC_PROJECT" "$TMP_PY_PROJECT"

# Ensure `task` binary alias is available in PATH if system installs it as `go-task`
REAL_TASK="$(command -v task || command -v go-task)"
if [[ -z "$REAL_TASK" ]]; then
  echo -e "${RED}[SELF-TEST FAIL] Neither 'task' nor 'go-task' found in PATH.${NC}" >&2
  exit 1
fi
ln -sf "$REAL_TASK" "${TMP_BIN}/task"
export PATH="${TMP_BIN}:${PATH}"

pass() {
  echo -e "${GREEN}  [PASS] $1${NC}"
}

fail() {
  echo -e "${RED}  [FAIL] $1${NC}" >&2
  exit 1
}

echo -e "${BLUE}=============================================================================${NC}"
echo -e "${BLUE} polyglot-guardrails — Running Automated Integration Self-Test Suite${NC}"
echo -e "${BLUE}=============================================================================${NC}"

# -----------------------------------------------------------------------------
# STEP 1: Generate a project with `lang:ts` + `fw:react`
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[1/7] Initializing temporary project with lang:ts + fw:react...${NC}"
bash "${REPO_ROOT}/scripts/guardrails-cli.sh" init \
  --target "$TMP_PROJECT" \
  --source "$REPO_ROOT" \
  --modules "core,lang:ts,fw:react"

for expected_file in \
  ".guardrails/manifest.json" \
  ".guardrails.lock" \
  "Taskfile.yml" \
  "mise.toml" \
  "lefthook.yml" \
  ".jscpd.json" \
  "commitlint.config.mjs" \
  ".secretlintrc.json" \
  "AGENTS.md" \
  ".agents/rules/quality-gates-and-architecture.md" \
  ".agents/skills/vibe-guardrails/SKILL.md" \
  ".agents/skills/clean-code-guard/SKILL.md" \
  ".agents/skills/i-have-adhd/SKILL.md" \
  ".agents/skills/commit/SKILL.md" \
  ".agents/skills/typescript-expert/SKILL.md" \
  ".agents/skills/vitest/SKILL.md" \
  ".agents/skills/zod-4/SKILL.md" \
  ".agents/skills/react-best-practices/SKILL.md" \
  ".agents/skills/accessibility/SKILL.md" \
  ".agents/skills/react-i18next/SKILL.md" \
  "eslint.config.mjs" \
  "tsconfig.base.json" \
  "knip.json" \
  "vitest.config.ts" \
  ".dependency-cruiser.cjs" \
  ".prettierrc.mjs" \
  ".size-limit.json" \
  ".guardrails/eslint/ts.mjs" \
  ".guardrails/eslint/react.mjs" \
  ".guardrails/eslint/a11y.mjs" \
  ".guardrails/ast/no-linter-bypass.yml" \
  ".guardrails/ast/architecture-boundaries.yml"; do
  [[ -f "${TMP_PROJECT}/${expected_file}" ]] || fail "Expected generated file missing: ${expected_file}"
done
pass "Generated project structure with core, lang:ts, and fw:react."

# -----------------------------------------------------------------------------
# STEP 2: Verify `task guard:check` passes on initial project
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[2/7] Verifying initial configuration lock via 'task guard:check'...${NC}"
(cd "$TMP_PROJECT" && task guard:check)
pass "'task guard:check' succeeded on clean generated project."

# -----------------------------------------------------------------------------
# STEP 3: Add orthogonal & architectural fortress addons via `task feature:add`
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[3/7] Adding 'cloudflare', 'design-system', 'testing-fortress', 'storybook', 'content-md', 'drizzle-d1', 'lib-exports' dynamically via 'task feature:add'...${NC}"
for addon_name in cloudflare design-system testing-fortress storybook content-md drizzle-d1 lib-exports; do
  (cd "$TMP_PROJECT" && task feature:add -- "$addon_name")
done

for expected_mod in \
  "addon:cloudflare" \
  "addon:design-system" \
  "addon:testing-fortress" \
  "addon:storybook" \
  "addon:content-md" \
  "addon:drizzle-d1" \
  "addon:lib-exports"; do
  if ! jq -e --arg m "$expected_mod" '.modules | index($m)' "${TMP_PROJECT}/.guardrails/manifest.json" >/dev/null; then
    fail "${expected_mod} was not registered in .guardrails/manifest.json"
  fi
done

for addon_file in \
  ".guardrails/taskfiles/Taskfile.cloudflare.yml" \
  ".guardrails/ast/cloudflare.yml" \
  ".guardrails/scripts/validate-wrangler.sh" \
  "panda.config.ts" \
  ".guardrails/eslint/design-system.mjs" \
  "stryker.config.mjs" \
  "playwright.config.ts" \
  ".guardrails/eslint/testing-fortress.mjs" \
  ".guardrails/eslint/storybook.mjs" \
  ".remarkrc.mjs" \
  "drizzle.config.ts" \
  ".agents/skills/material-3/SKILL.md" \
  ".agents/skills/panda-css/SKILL.md" \
  ".agents/skills/panda-css-theming/SKILL.md" \
  ".agents/skills/tdd/SKILL.md" \
  ".agents/skills/playwright-best-practices/SKILL.md" \
  ".agents/skills/storybook/SKILL.md" \
  ".agents/skills/content-markdown-mdx/SKILL.md" \
  ".agents/skills/workers-best-practices/SKILL.md" \
  ".agents/skills/wrangler/SKILL.md" \
  ".agents/skills/d1-drizzle-schema/SKILL.md" \
  ".agents/skills/lib-exports/SKILL.md"; do
  [[ -f "${TMP_PROJECT}/${addon_file}" ]] || fail "${addon_file} missing after feature:add"
done

(cd "$TMP_PROJECT" && task guard:check)
pass "'task feature:add' installed all 7 addons and updated .guardrails.lock."

# -----------------------------------------------------------------------------
# STEP 4: Simulate illegal modification of `eslint.config.mjs` & verify block
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[4/7] Simulating illegal tampering on 'eslint.config.mjs'...${NC}"
echo "// ILLEGAL MANUAL EDIT BY ROGUE AGENT" >> "${TMP_PROJECT}/eslint.config.mjs"

set +e
TAMPER_OUTPUT="$(cd "$TMP_PROJECT" && task guard:check 2>&1)"
TAMPER_EXIT=$?
set -e

if [[ "$TAMPER_EXIT" -eq 0 ]]; then
  fail "'task guard:check' should have failed after modifying eslint.config.mjs, but exited with 0!"
fi

if ! echo "$TAMPER_OUTPUT" | grep -q "eslint.config.mjs"; then
  fail "'task guard:check' failed but did not report 'eslint.config.mjs' as the modified file!"
fi
pass "'task guard:check' immediately blocked illegal edit to eslint.config.mjs (Exit Code: ${TAMPER_EXIT})."

# -----------------------------------------------------------------------------
# STEP 5: Restore via `task guard:sync` & verify Taskfile.local.yml protection
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[5/7] Testing self-healing via 'task guard:sync' and Taskfile.local.yml guardrails...${NC}"
(cd "$TMP_PROJECT" && task guard:sync)
(cd "$TMP_PROJECT" && task guard:check)
pass "'task guard:sync' restored tampered eslint.config.mjs and passed 'task guard:check'."

# Attempt forbidden override of `guard:check` inside Taskfile.local.yml
cat > "${TMP_PROJECT}/Taskfile.local.yml" << 'EOF'
version: '3'
tasks:
  guard:check:
    cmds:
      - echo "Bypassed!"
EOF

set +e
LOCAL_OVERRIDE_OUTPUT="$(cd "$TMP_PROJECT" && task guard:check 2>&1)"
LOCAL_OVERRIDE_EXIT=$?
set -e

if [[ "$LOCAL_OVERRIDE_EXIT" -eq 0 ]]; then
  fail "'task guard:check' must block Taskfile.local.yml when it attempts to override guard:check!"
fi
pass "'task guard:check' blocked forbidden override of 'guard:check' in Taskfile.local.yml."

# Replace with a valid local business task in Taskfile.local.yml
cat > "${TMP_PROJECT}/Taskfile.local.yml" << 'EOF'
version: '3'
tasks:
  business:seed:
    desc: "Custom local project task"
    cmds:
      - echo "Seeding local database..."
EOF
(cd "$TMP_PROJECT" && task guard:check)
pass "Valid 'Taskfile.local.yml' is allowed without triggering false positives."

# -----------------------------------------------------------------------------
# STEP 6: Verify AST Anti-Bypass & full `task verify` lifecycle
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[6/7] Testing AST anti-bypass rules and full 'task verify' lifecycle...${NC}"
mkdir -p "${TMP_PROJECT}/src/components/atoms"
cat > "${TMP_PROJECT}/src/components/atoms/Button.tsx" << 'EOF'
// @ts-ignore
export function Button(): null {
  return null;
}
EOF

set +e
BYPASS_OUTPUT="$(cd "$TMP_PROJECT" && task verify 2>&1)"
BYPASS_EXIT=$?
set -e

if [[ "$BYPASS_EXIT" -eq 0 ]]; then
  fail "'task verify' should have blocked '// @ts-ignore' in src/components/atoms/Button.tsx!"
fi
pass "AST gate blocked forbidden '// @ts-ignore' linter bypass comment."

# Write compliant code + 1:1 TDD companion + CSF3 Story companion + valid wrangler.toml
cat > "${TMP_PROJECT}/src/components/atoms/Button.tsx" << 'EOF'
export function Button(): null {
  return null;
}
EOF

cat > "${TMP_PROJECT}/src/components/atoms/Button.test.tsx" << 'EOF'
import { Button } from "./Button";

it("returns null for empty atom", () => {
  expect(Button()).toBe(null);
});
EOF

cat > "${TMP_PROJECT}/src/components/atoms/Button.stories.tsx" << 'EOF'
import { Button } from "./Button";

export default {
  title: "Atoms/Button",
  component: Button,
};

export const Primary = {
  args: {},
};
EOF

cat > "${TMP_PROJECT}/wrangler.toml" << 'EOF'
name = "sample-react-cloudflare-app"
compatibility_date = "2026-01-01"
EOF

(cd "$TMP_PROJECT" && task verify)
pass "Full 'task verify' (guard:check -> lint -> dup -> complexity -> sec -> test) passed across all 10 active Web modules!"

# -----------------------------------------------------------------------------
# STEP 7: Verify JVM & Minecraft Modding Stack (lang:java, lang:kotlin,
#         fw:minecraft, fw:quilt, fw:fabric)
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[7/7] Testing JVM & Minecraft Modding stack (lang:kotlin, lang:java, fw:minecraft, fw:quilt, fw:fabric)...${NC}"
bash "${REPO_ROOT}/scripts/guardrails-cli.sh" init \
  --target "$TMP_MC_PROJECT" \
  --source "$REPO_ROOT" \
  --modules "core,lang:kotlin,fw:quilt"

(cd "$TMP_MC_PROJECT" && task feature:add -- fabric)

for mc_mod in "core" "lang:java" "lang:kotlin" "fw:minecraft" "fw:quilt" "fw:fabric"; do
  if ! jq -e --arg m "$mc_mod" '.modules | index($m)' "${TMP_MC_PROJECT}/.guardrails/manifest.json" >/dev/null; then
    fail "${mc_mod} was not resolved in Minecraft project's .guardrails/manifest.json"
  fi
done

for mc_file in \
  "detekt.yml" \
  ".guardrails/java/pmd-ruleset.xml" \
  ".guardrails/java/checkstyle.xml" \
  ".guardrails/kotlin/detekt-server-boundary.yml" \
  ".guardrails/kotlin/detekt-client-boundary.yml" \
  ".guardrails/ast/java.yml" \
  ".guardrails/ast/kotlin.yml" \
  ".guardrails/ast/minecraft.yml" \
  ".guardrails/ast/quilt.yml" \
  ".guardrails/ast/fabric.yml" \
  ".guardrails/scripts/validate-minecraft-mod.sh" \
  ".guardrails/scripts/validate-quilt-mod.sh" \
  ".guardrails/scripts/validate-fabric-mod.sh" \
  ".agents/skills/java-guardrails/SKILL.md" \
  ".agents/skills/clean-code-java/SKILL.md" \
  ".agents/skills/gradle-expert/SKILL.md" \
  ".agents/skills/clean-code-kotlin/SKILL.md" \
  ".agents/skills/kotlin-guardrails/SKILL.md" \
  ".agents/skills/minecraft-modding/SKILL.md" \
  ".agents/skills/minecraft-mixin-expert/SKILL.md" \
  ".agents/skills/minecraft-networking/SKILL.md" \
  ".agents/skills/minecraft-testing/SKILL.md" \
  ".agents/skills/minecraft-ui-rendering/SKILL.md" \
  ".agents/skills/minecraft-multiloader/SKILL.md" \
  ".agents/skills/minecraft-resource-pack/SKILL.md" \
  ".agents/skills/minecraft-datapack/SKILL.md" \
  ".agents/skills/minecraft-commands-scripting/SKILL.md" \
  ".agents/skills/minecraft-ci-release/SKILL.md" \
  ".agents/skills/minecraft-server-admin/SKILL.md" \
  ".agents/skills/minecraft-permissions-admin/SKILL.md" \
  ".agents/skills/quilt-modding/SKILL.md" \
  ".agents/skills/fabric-modding/SKILL.md"; do
  [[ -f "${TMP_MC_PROJECT}/${mc_file}" ]] || fail "Expected Minecraft/JVM file missing: ${mc_file}"
done

# Test 7a: Verify Client/Server Side Separation blocks net.minecraft.client.* in server/
mkdir -p "${TMP_MC_PROJECT}/src/main/kotlin/com/stellar/ops/server"
cat > "${TMP_MC_PROJECT}/src/main/kotlin/com/stellar/ops/server/BadServerService.kt" << 'EOF'
package com.stellar.ops.server

import net.minecraft.client.Minecraft

object BadServerService {
    fun illegalClientCall(): String = Minecraft.getInstance().toString()
}
EOF

set +e
SIDE_OUTPUT="$(cd "$TMP_MC_PROJECT" && task lint 2>&1)"
SIDE_EXIT=$?
set -e

if [[ "$SIDE_EXIT" -eq 0 ]]; then
  fail "Minecraft Side-Separation gate should have blocked net.minecraft.client import in server package!"
fi
rm -f "${TMP_MC_PROJECT}/src/main/kotlin/com/stellar/ops/server/BadServerService.kt"
pass "Minecraft Side-Separation gate blocked net.minecraft.client import in server package."

# Test 7b: Verify Mixin safety gate blocks @Overwrite
mkdir -p "${TMP_MC_PROJECT}/src/main/java/com/stellar/ops/mixin"
cat > "${TMP_MC_PROJECT}/src/main/java/com/stellar/ops/mixin/BadServerMixin.java" << 'EOF'
package com.stellar.ops.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Overwrite;

@Mixin(Object.class)
public class BadServerMixin {
    @Overwrite
    public String toString() {
        return "overwritten";
    }
}
EOF

set +e
MIXIN_OUTPUT="$(cd "$TMP_MC_PROJECT" && task lint 2>&1)"
MIXIN_EXIT=$?
set -e

if [[ "$MIXIN_EXIT" -eq 0 ]]; then
  fail "Minecraft Mixin gate should have blocked @Overwrite in BadServerMixin.java!"
fi
rm -f "${TMP_MC_PROJECT}/src/main/java/com/stellar/ops/mixin/BadServerMixin.java"
pass "Minecraft Mixin gate blocked forbidden @Overwrite annotation."

# Test 7c: Write compliant Quilt + Fabric descriptors, Mixin config, and Kotlin code
cat > "${TMP_MC_PROJECT}/gradle.properties" << 'EOF'
minecraft_version=1.21.4
quilt_loader_version=0.29.0
fabric_loader_version=0.16.10
mod_version=1.0.0
EOF

mkdir -p "${TMP_MC_PROJECT}/src/main/resources/assets/stellar_ops/lang"
mkdir -p "${TMP_MC_PROJECT}/src/main/resources/data/stellar_ops/loot_table/blocks"

cat > "${TMP_MC_PROJECT}/src/main/resources/pack.mcmeta" << 'EOF'
{
  "pack": {
    "pack_format": 46,
    "description": "Stellar Ops Mod Resources"
  }
}
EOF

cat > "${TMP_MC_PROJECT}/src/main/resources/stellar_ops.mixins.json" << 'EOF'
{
  "required": true,
  "package": "com.stellar.ops.mixin",
  "compatibilityLevel": "JAVA_21",
  "injectors": {
    "defaultRequire": 1
  },
  "mixins": []
}
EOF

cat > "${TMP_MC_PROJECT}/src/main/resources/quilt.mod.json" << 'EOF'
{
  "schema_version": 1,
  "quilt_loader": {
    "group": "com.stellar",
    "id": "stellar_ops",
    "version": "${version}",
    "metadata": {
      "name": "Stellar Ops",
      "description": "High-performance server operations mod.",
      "license": "MIT"
    },
    "intermediate_mappings": "net.fabricmc:intermediary",
    "entrypoints": {
      "init": ["com.stellar.ops.server.StellarOpsService"]
    }
  },
  "mixin": "stellar_ops.mixins.json"
}
EOF

cat > "${TMP_MC_PROJECT}/src/main/resources/fabric.mod.json" << 'EOF'
{
  "schemaVersion": 1,
  "id": "stellar_ops",
  "version": "${version}",
  "name": "Stellar Ops",
  "description": "High-performance server operations mod.",
  "license": "MIT",
  "environment": "*",
  "entrypoints": {
    "main": ["com.stellar.ops.server.StellarOpsService"]
  },
  "mixins": ["stellar_ops.mixins.json"],
  "depends": {
    "fabricloader": ">=0.16.10",
    "minecraft": "~1.21.4"
  }
}
EOF

cat > "${TMP_MC_PROJECT}/src/main/kotlin/com/stellar/ops/server/StellarOpsService.kt" << 'EOF'
package com.stellar.ops.server

@JvmInline
value class RuleId(val value: String)

object StellarOpsService {
    fun isRuleActive(ruleId: RuleId): Boolean = ruleId.value.isNotEmpty()
}
EOF

(cd "$TMP_MC_PROJECT" && task verify)
pass "Full 'task verify' passed on compliant Kotlin + Java + Minecraft + Quilt + Fabric mod project!"

# -----------------------------------------------------------------------------
# STEP 8: Verify Python (uv) + Flet MD3 + NiceGUI + LangChain + Jupyter Stack
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[8/8] Testing Python (uv) + Flet MD3 + NiceGUI + LangChain + Jupyter stack...${NC}"
bash "${REPO_ROOT}/scripts/guardrails-cli.sh" init \
  --target "$TMP_PY_PROJECT" \
  --source "$REPO_ROOT" \
  --modules "core,lang:python,fw:flet,fw:langchain"

(cd "$TMP_PY_PROJECT" && task feature:add -- nicegui)
(cd "$TMP_PY_PROJECT" && task feature:add -- jupiter)

for py_mod in "core" "lang:python" "fw:flet" "fw:langchain" "fw:nicegui" "fw:jupyter"; do
  if ! jq -e --arg m "$py_mod" '.modules | index($m)' "${TMP_PY_PROJECT}/.guardrails/manifest.json" >/dev/null; then
    fail "${py_mod} was not resolved in Python project's .guardrails/manifest.json"
  fi
done

for py_file in \
  "ruff.toml" \
  ".guardrails/ast/python.yml" \
  ".guardrails/ast/flet.yml" \
  ".guardrails/ast/nicegui.yml" \
  ".guardrails/ast/langchain.yml" \
  ".guardrails/ast/jupyter.yml" \
  ".guardrails/scripts/validate-python.sh" \
  ".guardrails/scripts/validate-flet.sh" \
  ".guardrails/scripts/validate-nicegui.sh" \
  ".guardrails/scripts/validate-langchain.sh" \
  ".guardrails/scripts/validate-jupyter.sh" \
  ".agents/skills/python-guardrails/SKILL.md" \
  ".agents/skills/python-guardrails/references/secrets-and-typing.md" \
  ".agents/skills/uv-python-workflow/SKILL.md" \
  ".agents/skills/uv-python-workflow/references/pyproject-template.md" \
  ".agents/skills/docker-expert/SKILL.md" \
  ".agents/skills/docker-expert/references/dockerfile-and-compose.md" \
  ".agents/skills/flet-md3/SKILL.md" \
  ".agents/skills/flet-md3/references/atomic-and-e2e-patterns.md" \
  ".agents/skills/nicegui-expert/SKILL.md" \
  ".agents/skills/nicegui-expert/references/patterns-and-testing.md" \
  ".agents/skills/langchain-expert/SKILL.md" \
  ".agents/skills/langchain-expert/references/langgraph-and-mcp.md" \
  ".agents/skills/prompt-engineer/SKILL.md" \
  ".agents/skills/prompt-engineer/references/prompt-and-rag-patterns.md" \
  ".agents/skills/ffmpeg-expert/SKILL.md" \
  ".agents/skills/ffmpeg-expert/references/audio-pipelines.md" \
  ".agents/skills/jupyter-expert/SKILL.md"; do
  [[ -f "${TMP_PY_PROJECT}/${py_file}" ]] || fail "Expected Python/Flet/NiceGUI/LangChain/Jupyter file missing: ${py_file}"
done

# Test 8a: Verify Flet MD3 gate blocks hardcoded hex colors in ui/atoms/
mkdir -p "${TMP_PY_PROJECT}/src/geranium/ui/atoms"
cat > "${TMP_PY_PROJECT}/src/geranium/ui/atoms/bad_button.py" << 'EOF'
def render_bad_button() -> dict[str, str]:
    return dict(color="#FF0055")
EOF

set +e
FLET_OUTPUT="$(cd "$TMP_PY_PROJECT" && task lint 2>&1)"
FLET_EXIT=$?
set -e

if [[ "$FLET_EXIT" -eq 0 ]]; then
  fail "Flet MD3 gate should have blocked hardcoded hex color in src/geranium/ui/atoms/bad_button.py!"
fi
rm -f "${TMP_PY_PROJECT}/src/geranium/ui/atoms/bad_button.py"
pass "Flet MD3 gate blocked hardcoded hex color in ui/atoms/."

# Test 8b: Verify NiceGUI gate blocks blocking time.sleep() in src/
mkdir -p "${TMP_PY_PROJECT}/src/geranium/ui/pages"
cat > "${TMP_PY_PROJECT}/src/geranium/ui/pages/bad_page.py" << 'EOF'
import time


def handle_click() -> None:
    time.sleep(1)
EOF

set +e
NICEGUI_OUTPUT="$(cd "$TMP_PY_PROJECT" && task lint 2>&1)"
NICEGUI_EXIT=$?
set -e

if [[ "$NICEGUI_EXIT" -eq 0 ]]; then
  fail "NiceGUI async gate should have blocked time.sleep() in src/geranium/ui/pages/bad_page.py!"
fi
rm -f "${TMP_PY_PROJECT}/src/geranium/ui/pages/bad_page.py"
pass "NiceGUI async event-loop gate blocked time.sleep() in src/."

# Test 8c: Verify LangChain gate blocks legacy LLMChain
mkdir -p "${TMP_PY_PROJECT}/src/geranium/agents"
cat > "${TMP_PY_PROJECT}/src/geranium/agents/bad_chain.py" << 'EOF'
def make_legacy_chain(prompt: object, llm: object) -> object:
    return LLMChain(prompt=prompt, llm=llm)
EOF

set +e
LC_OUTPUT="$(cd "$TMP_PY_PROJECT" && task lint 2>&1)"
LC_EXIT=$?
set -e

if [[ "$LC_EXIT" -eq 0 ]]; then
  fail "LangChain gate should have blocked legacy LLMChain in src/geranium/agents/bad_chain.py!"
fi
rm -f "${TMP_PY_PROJECT}/src/geranium/agents/bad_chain.py"
pass "LangChain gate blocked deprecated LLMChain."

# Test 8d: Verify Jupyter gate blocks unstripped cell outputs and 'task format' strips them automatically
mkdir -p "${TMP_PY_PROJECT}/notebooks"
cat > "${TMP_PY_PROJECT}/notebooks/experiment.ipynb" << 'EOF'
{
  "cells": [
    {
      "cell_type": "code",
      "execution_count": 3,
      "metadata": {},
      "outputs": [
        {
          "name": "stdout",
          "output_type": "stream",
          "text": ["sensitive output\n"]
        }
      ],
      "source": [
        "sample_rate = 48000\n"
      ]
    }
  ],
  "metadata": {},
  "nbformat": 4,
  "nbformat_minor": 5
}
EOF

set +e
NB_DIRTY_OUTPUT="$(cd "$TMP_PY_PROJECT" && task lint 2>&1)"
NB_DIRTY_EXIT=$?
set -e

if [[ "$NB_DIRTY_EXIT" -eq 0 ]]; then
  fail "Jupyter Clean Output gate should have blocked unstripped outputs in notebooks/experiment.ipynb!"
fi
pass "Jupyter Clean Output gate blocked unstripped notebook outputs."

(cd "$TMP_PY_PROJECT" && task format)

cat > "${TMP_PY_PROJECT}/src/geranium/ui/atoms/primary_button.py" << 'EOF'
"""Compliant Material Design 3 Flet atom."""


def get_primary_button_label(title: str) -> str:
    """Return formatted button label."""
    return title.strip()
EOF

(cd "$TMP_PY_PROJECT" && task verify)
pass "Full 'task verify' passed on compliant Python (uv) + Flet + NiceGUI + LangChain + Jupyter project!"

echo -e "\n${GREEN}=============================================================================${NC}"
echo -e "${GREEN} ALL SELF-TESTS PASSED SUCCESSFULLY (100% Zero Config Drift & AST Verified)${NC}"
echo -e "${GREEN}=============================================================================${NC}"
