---
name: jupyter-expert
description: "Manage reproducible Jupyter (.ipynb) notebooks with uv, Ruff native lint/format, output stripping, <=30 lines/cell, and pytest --nbmake."
---

# Reproducible Jupyter Notebooks with `uv` (`fw:jupyter`)

## 1. Hard Notebook Quality Gates (`validate-jupyter.sh` + `jupyter.yml`)
| Gate | Requirement | Enforcement |
| :--- | :--- | :--- |
| **Schema** | Valid JSON with `nbformat >= 4` | `validate-jupyter.sh` |
| **Clean Output Gate** | Committed `.ipynb` code cells must have `outputs: []` and `execution_count: null` (prevents data leaks & base64 diff bloat) | Auto-stripped by `task format`; verified by `task lint` |
| **Reproducibility** | Zero `!pip install`, `%pip install`, `!conda`, or `%conda` inside cells; declare all packages via `uv add --dev ipykernel jupyterlab nbmake` | `validate-jupyter.sh` + `jupyter.yml` |
| **Cell Modularity** | **<= 30 lines** per code cell; extract reusable functions/classes into typed modules under `src/` and import them | `validate-jupyter.sh` |
| **Code Quality & Execution** | Native Ruff lint/format on `.ipynb` + top-to-bottom execution via `pytest --nbmake` | `Taskfile.jupyter.yml` |

## 2. Standard Notebook Workflow (`task`)
1. Add dependencies declaratively: `uv add --dev ipykernel jupyterlab nbmake`
2. Strip outputs & format cells before commit: `task format` (runs `validate-jupyter.sh --strip .` + `ruff format`)
3. Lint notebooks & Python modules: `task lint` (runs `validate-jupyter.sh .` + `ruff check`)
4. Execute notebooks end-to-end in clean kernel: `task test` (runs `uv run pytest --nbmake notebooks/`)
