---
name: uv-python-workflow
description: "Manage Python dependencies, lockfiles, and builds exclusively with Astral uv (pyproject.toml, uv.lock, uv_build)."
---

# Astral `uv` Workflow (`uv-python-workflow`)

## 1. Hard Rules
- **`uv` Exclusivity**: `Pipfile`, `Pipfile.lock`, `poetry.lock`, and `setup.py` are blocked by `validate-python.sh`. Never suggest `pip install`, `poetry`, or manual `source .venv/bin/activate`.
- **Universal Runner**: Execute lifecycle tasks via `task setup`, `task format`, `task lint`, `task test`, `task verify`.
- **Lockfile Hygiene**: Commit both `pyproject.toml` and `uv.lock`. CI and Docker builds must use `uv sync --frozen`.

## 2. Dependency & Environment Operations
| Operation | Command |
| :--- | :--- |
| Add runtime dependency | `uv add <package>` |
| Add dev/test dependency | `uv add --dev <package>` |
| Remove dependency | `uv remove <package>` |
| Sync environment via Taskfile | `task setup` (invokes `uv sync`) |

## 3. Deep References (Load On-Demand Only)
- Full `pyproject.toml` template (`uv_build`, `[dependency-groups]`, pytest/mypy config): [references/pyproject-template.md](./references/pyproject-template.md)
