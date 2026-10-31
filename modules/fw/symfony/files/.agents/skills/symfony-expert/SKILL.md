---
name: symfony-expert
description: Build and audit Symfony 7.x+ applications (fw:symfony) enforcing Deptrac Hexagonal layers (deptrac.yaml), thin invokable controllers, #[MapRequestPayload] DTOs, Twig-CS-Fixer & WCAG 2.2 AA gates, PHPStan Symfony+Doctrine level max, and Infection mutation testing.
---

# Symfony 7.x+ Enterprise Craftsmanship (`fw:symfony`)

## 1. Mandatory Command Interface (`task`)
Never invoke `php bin/console`, `composer`, `deptrac`, `twig-cs-fixer`, `phpstan`, `pint`, `pest`, or `infection` directly. Always use:
- `task check:quick` / `task lint`: Runs `validate-symfony.sh`, `validate-php.sh`, `deptrac analyse`, `twig-cs-fixer lint`, `lint:container`, `lint:yaml`, `lint:twig`, Pint, and PHPStan `level: max`.
- `task a11y` / `task i18n` / `task typecheck` / `task coverage` / `task mutate`
- `task verify`: Full end-to-end quality gate.

## 2. Symfony 7.x+ Architectural Guardrails (`deptrac.yaml` + `validate-symfony.sh`)
1. **Strict Types & Readonly Classes**: Every `.php` file must start with `declare(strict_types=1);` and use `final readonly class` for Controllers, Services, Commands, and Messenger Handlers.
2. **Deptrac Hexagonal Layer Boundaries (`deptrac.yaml`)**:
   - **`src/Domain/` (`Domain: ~`)**: Pure PHP domain models, value objects, and repository interfaces. **Zero** `Doctrine\*` or `Symfony\*` imports allowed.
   - **`src/Application/`**: Use cases and `#[AsMessageHandler]` command/query handlers; depends only on `Domain`.
   - **`src/Controller/`**: Thin invokable HTTP adapters (`#[Route]`, `#[MapRequestPayload]`, `#[IsGranted]`); depends only on `Application`, `Domain`, and `Symfony`. Direct `EntityManagerInterface` calls (`->persist()`, `->flush()`, `->remove()`, `->createQueryBuilder()`) and `$this->container->get()` are strictly banned.
   - **`src/Infrastructure/`**: Doctrine repositories (`ServiceEntityRepository`), ORM mappings, and Symfony adapters.
3. **Twig Security, Formatting (`twig-cs-fixer`), i18n & WCAG 2.2 AA (`templates/**/*.twig`)**:
   - **Zero `|raw`**: Unescaped `|raw` and `{{ dump() }}` are strictly forbidden in `templates/`.
   - **Accessibility**: Every `<img>` must include `alt="..."` and never use `tabindex > 0`.
4. **Static Analysis & Mutation (`>= 85%` MSI)**:
   - Use `phpstan/phpstan-symfony` + `phpstan/phpstan-doctrine` with explicit generic collection annotations (`/** @var Collection<int, OrderItem> */`).
   - Run `task mutate` (Infection PHP + PHPStan static analysis, `minMsi: 85%`, `minCoveredMsi: 90%`).

## 3. Deep-Dive Reference
- Load `references/doctrine-messenger-and-security.md` for `#[MapRequestPayload]` DTO validation, Messenger CQRS handler patterns, Doctrine DTO queries, and Security Voters.
