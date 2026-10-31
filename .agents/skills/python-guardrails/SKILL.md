---
name: python-guardrails
description: "Enforce Python 3.12+ quality gates (uv, Ruff McCabe <=8, <=256 lines/file, MyPy strict, pydantic-settings) when editing .py files."
---

# Python Quality Guardrails (`lang:python`)

## 1. Hard Architectural & Complexity Gates (`ruff.toml` + `validate-python.sh`)
| Gate | Limit / Rule | Enforcement |
| :--- | :--- | :--- |
| **Package Manager** | `uv` exclusively (`pyproject.toml` + `uv.lock`); `Pipfile`/`poetry.lock`/`setup.py` banned | `validate-python.sh` |
| **File Length** | **<= 256 lines** per `.py` file | `validate-python.sh` |
| **Line Length** | **<= 120 chars** (`line-length = 120`) | `ruff.toml` |
| **Cyclomatic Complexity** | **McCabe <= 8** (`C901`), `radon cc` grade A/B | `ruff.toml` |
| **Function Structure** | `max-statements = 20`, `max-args = 5`, `max-branches = 8`, `max-returns = 4` | `ruff.toml` (`PLR091*`) |
| **Static Typing** | Strict `mypy` (`strict = true`, `plugins = ["pydantic.mypy"]`), zero `Any` in domain | `mypy` |
| **Naming & Logging** | Zero `print()` in `src/` (use `logging`); bans vague names (`data`, `res`, `temp`, `info`) | `python.yml` + script |
| **Zero Bypass** | `# noqa`, `# type: ignore`, and `# nosemgrep` are strictly forbidden | `no-linter-bypass.yml` |

## 2. Canonical Idioms
- **Modern Typing (Python 3.12+)**: Use `str | None`, `list[str]`, `dict[str, int]`, `type Alias = ...`, and `@dataclass(frozen=True, slots=True)` or Pydantic v2 `BaseModel`.
- **Parameter Grouping (`PLR0913`)**: When a function needs > 5 arguments, group cohesive parameters into a frozen dataclass or Pydantic model.
- **Guard Clauses (`PLR0912`)**: Flatten nested `if/else` trees using early `return` guard clauses or dict dispatch tables.

## 3. Verification
Always verify via `task` (never run `ruff`, `mypy`, or `pytest` directly):
- Fast lint & AST check: `task check:quick` (runs `.guardrails/scripts/validate-python.sh .` + `ruff` + `mypy`)
- Full gate: `task verify`

## 4. Deep References (Load On-Demand Only)
- Dual-environment `pydantic-settings` (`/run/secrets/` vs `.env`) & strict MyPy setup: [references/secrets-and-typing.md](./references/secrets-and-typing.md)
