---
name: php-guardrails
description: >-
  PHP quality guardrails for lang:php modules (Composer, Laravel Pint, PHPStan
  level max, Pest). Use when writing, formatting, linting, or testing PHP code.
---

# Skill: PHP Quality Guardrails (`php-guardrails`)

## Rules & Workflow
1. **Command Interface**: Always run PHP checks via `task` (`task format`, `task lint`, `task test`, `task verify`). Never invoke `composer`, `pint`, `phpstan`, or `pest` directly.
2. **Static Analysis (`pint.json` & `phpstan.neon.dist`)**:
   - Strict PSR-12 / Laravel Pint formatting (`declare_strict_types: true`).
   - PHPStan runs at `level: max` over `src/` and `app/`.
3. **Zero Bypass**: `@phpstan-ignore`, `@phpstan-ignore-next-line`, and `@psalm-suppress` are strictly forbidden by `.guardrails/ast/no-linter-bypass.yml`.
4. **Testing**: `pest --coverage --min=80` enforces unit test coverage.
