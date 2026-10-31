---
name: php-guardrails
description: >-
  PHP quality guardrails for lang:php modules (Composer, Laravel Pint, PHPStan
  level max, Pest). Use when writing, formatting, linting, or testing PHP code.
---

# Skill: PHP Quality Guardrails (`php-guardrails`)

## Core Rules
- Use `task` (`task format`, `task lint`, `task test`, `task verify`).
- Enforces `declare_strict_types`, Laravel Pint (`pint.json`), PHPStan `level: max` (`phpstan.neon.dist`), and Pest coverage `>= 80%`.
- `@phpstan-ignore` and `@psalm-suppress` are forbidden.
