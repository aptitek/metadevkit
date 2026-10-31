# AGENTS.md — Strict AI Vibe-Coding Guardrails Contract

> **MANAGED BY `polyglot-guardrails` — Single Source of Truth (DO NOT EDIT MANUALLY).**
> Load `.agents/skills/vibe-guardrails/SKILL.md` before writing or modifying any code.

## 1. Mandatory Universal Command Interface (`task`)
You MUST interact with the repository **exclusively** through the universal `task` runner (`go-task`).
**Direct execution of underlying package managers or linters (`pnpm`, `npm`, `npx`, `uv`, `pip`, `poetry`, `pytest`, `ruff`, `mypy`, `gradle`, `./gradlew`, `detekt`, `composer`, `eslint`, `vitest`, `wrangler`, `jupyter`) is strictly FORBIDDEN.**

| Action | Allowed Command |
| :--- | :--- |
| Run full meta-framework verification | `task verify` |
| Run automated end-to-end integration self-test | `task self-test` |
| Tier 1 (< 3s): Fast inner-loop AST + lint check | `task check:quick` |
| Tier 1 (< 3s): Fast unit test check | `task test:quick` |
| Tier 2 (< 10s): Pre-commit verification gate | `task check:commit` |
| Tier 3: Pre-push full architectural fortress gate | `task check:push` / `task verify` |
| Run cross-language static typechecking | `task typecheck` |
| Run cross-language WCAG 2.2 AA / UI accessibility | `task a11y` |
| Run cross-language i18n locale parity & literal check | `task i18n` |
| Run cross-language branch & line coverage verification | `task coverage` |
| Run cross-language mutation testing | `task mutate` |
| Initialize or bootstrap a project | `task init MODULES=<m1,m2>` / `task bootstrap` |
| Verify config lock | `task guard:check` |
| Sync guardrails | `task guard:sync` |
| Update devkit, mise toolchain & dependencies | `task update` |
| Add module/addon | `task feature:add -- <mod>` |

---

## 2. Anti-Tamper & Zero Config Drift Policy (`.guardrails.lock`)
All configuration files tracked in `.guardrails.lock` are cryptographically locked via SHA-256 checksums:
- Core foundation files: `.gitignore`, `.gitattributes`, `Taskfile.yml`, `mise.toml`, `lefthook.yml`, `AGENTS.md`
- Everything inside `.guardrails/**` and `.agents/**`
- Module-specific configuration files installed by active modules in `.guardrails/manifest.json`

---

## 3. Zero Linter / Typechecker Bypass Policy (`.guardrails/ast/no-linter-bypass.yml`)
Suppressing errors via comments or annotations (`eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `# noqa`, `# type: ignore`, `@SuppressWarnings`, `@Suppress`, `@file:Suppress`, `@phpstan-ignore`, `nosemgrep`) is strictly forbidden.

---

## 4. Active Module Quality Gates

### `lang:python` — Python 3.12+ Geranium Quality Fortress (`uv`)
- **Locked Configs**: `ruff.toml`, `.guardrails/python/coverage.toml`, `.guardrails/python/mutmut.toml`.
- **Toolchain & Modularity**: Exclusive `uv` package management (`Pipfile`/`poetry.lock`/`setup.py` forbidden), max **256 lines** per `.py` file, Ruff McCabe `max-complexity = 8`, Pylint `max-statements = 20`, `max-args = 5`, `max-branches = 8`, `max-returns = 4`, strict `mypy` (zero `Any` in `src/`), zero raw `print()` in `src/`, zero vague variable names (`data`, `res`, `temp`, `info`) in `src/`, `>= 90%` branch coverage, and `mutmut >= 90%` mutation score.

### `lang:shell` — Defensive Bash & Shell Scripting Fortress
- **Quality Gates**: Every `.sh` file must include `set -euo pipefail`, pass `bash -n` syntax verification and `shellcheck` / `shfmt`, quote variable expansions, and never use `eval` or `curl | sh`.

### `addon:devkit` — Meta-Devkit Self-Governance ("Who Guards the Guardians")
- **Quality Gates**: Enforces valid `module.json` schemas & DAG dependencies, colocated Semgrep AST rules (`files/.guardrails/ast/*.yml`), pinned `mise.fragment.toml` versions, root DRY isolation, and `SKILL.md <= 100` lines 3-tier Progressive Disclosure.
