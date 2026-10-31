---
name: devkit-maintainer
description: "Maintain and extend polyglot-guardrails modules, colocated AST rules, progressive-disclosure skills (<=100 lines), and self-tests."
---

# Meta-Devkit Maintainer (`addon:devkit` — "Who Guards the Guardians")

## 1. Self-Governance & DRY Architecture
`polyglot-guardrails` enforces its own quality gates on itself via `["core", "lang:python", "lang:shell", "addon:devkit"]`:
- **Colocated AST Rules & Skills**: Every Semgrep AST rule (`files/.guardrails/ast/<name>.yml`) and agent skill (`files/.agents/skills/<skill>/SKILL.md`) lives exclusively inside its owning module under `modules/<stratum>/<name>/`.
- **Strict Root Isolation (DRY)**: The root `.agents/skills/` and `.guardrails/ast/` of `metadevkit` only contain files from `core`, `lang:python`, `lang:shell`, and `addon:devkit`. Inactive module skills/configs are never duplicated at the root.
- **Unified CLI Source of Truth**: `guardrails-cli.sh` and `verify-lock.sh` live in `modules/core/files/.guardrails/scripts/` and are synchronized to `.guardrails/scripts/` via `task guard:sync`.
- **Skill Token Parsimony Gate (`validate-devkit.sh`)**: Every `SKILL.md` must be **<= 100 lines** with valid YAML frontmatter (`name` == folder name, concise `description`). Place deep-dive templates in `references/*.md`.

## 2. Standard Workflow for Adding / Updating a Module or Skill
1. Edit module templates, AST rules, or skills under `modules/<stratum>/<name>/files/`.
2. Run `task guard:sync` to propagate changes into `.guardrails/`, `.agents/skills/`, and `.guardrails.lock`.
3. Add or update integration tests in `tests/`.
4. Run `task verify` (`guard:check` -> `lint` -> `typecheck` -> `a11y` -> `i18n` -> `dup` -> `complexity` -> `sec` -> `test` -> `coverage` -> `mutate`).
