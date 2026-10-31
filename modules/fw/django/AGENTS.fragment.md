### `fw:django` — Django 5.x+ Services/Selectors & Template Fortress
- **Locked Configs**: `ruff.toml` (with `DJ` flake8-django rules), `.djlintrc`.
- **Quality Gates**: HackSoft Services/Selectors ("Fat-Free Views": zero `.objects.create`/`update`/`delete` or `transaction.atomic` in `views.py`), Ruff `DJ001`/`DJ008`/`DJ012`, `.djlintrc` template formatting & WCAG 2.2 AA a11y, `django-stubs` strict MyPy, zero `.raw()`/`.extra()`/`mark_safe()`/`|safe`, and settings secret hardening.
