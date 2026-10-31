### `fw:jupyter` — Reproducible Jupyter Notebooks (`uv`)
- **Quality Gates**: Valid `nbformat >= 4` `.ipynb` JSON, Clean Output Gate (`outputs: []` and `execution_count: null` enforced by `task lint` and auto-stripped by `task format`), zero in-cell `!pip`/`%pip`/`%conda` installs, max 30 lines per code cell, and `pytest --nbmake`.
