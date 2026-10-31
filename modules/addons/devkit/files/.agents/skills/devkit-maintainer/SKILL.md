---
name: devkit-maintainer
description: "Maintain and extend polyglot-guardrails modules, AST rules, progressive-disclosure skills (<=100 lines), and self-tests."
---

# Meta-Devkit Maintainer (`addon:devkit` — "Who Guards the Guardians")

## 1. Self-Governance Architecture
`polyglot-guardrails` enforces its own quality gates on itself via `core`, `lang:shell`, and `addon:devkit`:
- **Locked Root Configs**: `.guardrails.lock` hashes `Taskfile.yml`, `mise.toml`, `lefthook.yml`, `AGENTS.md`, `.guardrails/**`, and all `.agents/skills/**`.
- **Skill Token Parsimony Gate (`validate-devkit.sh`)**: Every `SKILL.md` must be **<= 100 lines** with valid YAML frontmatter (`name` == folder name, concise `description`). Place deep-dive templates in `references/*.md`.
- **Module-to-Root Parity**: `task guard:sync` automatically synchronizes all skills from `modules/**/files/.agents/skills/` and AST rules from `rules/ast/` into the root `.agents/skills/` and `.guardrails/ast/` before regenerating `.guardrails.lock`.

## 2. Standard Workflow for Adding / Updating a Module or Skill
1. Edit module templates under `modules/<stratum>/<name>/files/` or AST rules under `rules/ast/<name>.yml`.
2. Run `task guard:sync` to propagate changes into `.guardrails/`, `.agents/skills/`, and `.guardrails.lock`.
3. Add an integration test assertion in `scripts/self-test.sh`.
4. Run `task verify` (executes `guard:check` -> `lint` -> `dup` -> `complexity` -> `sec` -> `test` / `self-test.sh`).
