---
name: django-expert
description: Build and audit Django 5.x+ applications with uv (fw:django) enforcing the HackSoft Services/Selectors pattern (Fat-Free Views), Ruff flake8-django (DJ001/DJ008/DJ012), djLint template formatting & WCAG 2.2 AA a11y, django-stubs strict MyPy, N+1 prevention, and pytest-django + mutmut.
---

# Django 5.x+ Enterprise Craftsmanship (`fw:django`)

## 1. Mandatory Command Interface (`task`)
Never invoke `python manage.py`, `uv`, `ruff`, `djlint`, `django-upgrade`, `mypy`, `pytest`, or `mutmut` directly. Always use:
- `task check:quick` / `task lint`: Runs `validate-django.sh`, `validate-python.sh`, Ruff (`DJ` rules), `djlint --lint --check`, and `makemigrations --check --dry-run`.
- `task format`: Runs `ruff format`, `django-upgrade --target-version 5.1`, and `djlint --reformat`.
- `task a11y` / `task i18n` / `task typecheck` / `task coverage` / `task mutate`
- `task verify`: Full end-to-end quality gate.

## 2. HackSoft Layering Architecture ("Fat-Free Views" — `validate-django.sh`)
Never place ORM mutations or complex QuerySet joins inside `views.py`, serializers, or forms:
1. **`models.py`**: Schema definitions, field validators, `GeneratedField` (Django 5), and mandatory `__str__(self) -> str` (`DJ008`). Never use `null=True` on `CharField`/`TextField`/`SlugField`/`EmailField` (`DJ001`; use `blank=True, default=""`).
2. **`selectors.py` (Read Layer)**: Keyword-only functions (`def order_list(*, user_id: int) -> QuerySet[Order]:`) encapsulating all complex filtering, `select_related()`, and `prefetch_related()` to eliminate N+1 queries.
3. **`services.py` (Write Layer)**: Keyword-only functions (`@transaction.atomic def order_create(*, user: User, sku: str) -> Order:`) handling all `.objects.create()`, `.save()`, `.update()`, `.delete()`, and domain side effects.
4. **`views.py` (Transport Layer)**: Thin sync/async HTTP adapters that validate input, call a selector or service, and return an `HttpResponse` / `JsonResponse`. Direct `.objects.create()`, `.update()`, `.delete()`, and `transaction.atomic` are strictly banned in `views.py`.

## 3. Security, Templates (`djlint`) & Type Safety (`django-stubs`)
- **Zero SQLi & XSS**: `.raw()`, `.extra()`, `mark_safe()`, and template `|safe` / `{% autoescape off %}` are strictly forbidden. Use parameterized QuerySets and `format_html()`.
- **Settings Hygiene**: Never hardcode `SECRET_KEY = "..."`, `DEBUG = True`, or `ALLOWED_HOSTS = ["*"]` in `*settings*.py`. Inject secrets via `pydantic-settings` (`/run/secrets/`).
- **Templates (`.djlintrc` + WCAG 2.2 AA)**: All `templates/**/*.html` must pass `djlint --profile=django`, include `alt="..."` on every `<img>`, and never use `tabindex > 0`.
- **Typing (`django-stubs`)**: Enable `plugins = ["mypy_django_plugin.main"]` in `pyproject.toml` and parameterize `QuerySet[MyModel]` explicitly (zero `Any`).

## 4. Deep-Dive Reference
- Load `references/services-selectors-and-orm.md` for canonical `services.py` / `selectors.py` implementations, `django-stubs` setup, and `pytest-django` + `mutmut` testing patterns.
