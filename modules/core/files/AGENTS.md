# AGENTS.md — Strict AI Vibe-Coding Guardrails Contract

> **MANAGED BY `polyglot-guardrails` — Single Source of Truth.**
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
| Run cross-language WCAG 2.2 AA / UI / Narrator accessibility | `task a11y` |
| Run cross-language i18n locale parity & literal check | `task i18n` |
| Run cross-language branch & line coverage verification | `task coverage` |
| Run cross-language mutation testing (StrykerJS, mutmut, PITest, Infection) | `task mutate` |
| Initialize a target project | `task init -- --target <dir> --modules <m1,m2>` |
| Verify config lock | `task guard:check` |
| Sync guardrails | `task guard:sync` |
| Add module/addon | `task feature:add -- <mod>` |

---

## 2. Anti-Tamper & Zero Config Drift Policy (`.guardrails.lock`)
All configuration files tracked in `.guardrails.lock` in child projects are cryptographically locked via SHA-256 checksums:
- `Taskfile.yml`, `mise.toml`, `lefthook.yml`, `.jscpd.json`, `commitlint.config.mjs`, `.secretlintrc.json`, `AGENTS.md`
- `eslint.config.mjs`, `tsconfig.base.json`, `knip.json`, `vitest.config.ts`, `.dependency-cruiser.cjs`, `.prettierrc.mjs`, `.size-limit.json`
- `panda.config.ts`, `stryker.config.mjs`, `playwright.config.ts`, `.remarkrc.mjs`, `drizzle.config.ts`, `ruff.toml`, `.djlintrc`, `detekt.yml`, `pint.json`, `phpstan.neon.dist`, `infection.json5`, `deptrac.yaml`
- Everything inside `.guardrails/**` and `.agents/**`

---

## 3. Architectural Locks, JVM / Minecraft & Python / Jupyter Quality Gates
1. **Lock 1 (`lang:ts` — Functional Purity & Total Functions)**: `complexity <= 3`, `max-depth <= 1`, `max-lines <= 150`, `max-lines-per-function <= 28`, `max-params <= 3` in `src/`. Bans `let`/`var`, mutation, imperative loops, `else`, `as T`, `x!`, `is T` type predicates, `throw`/`try-catch` in pure modules, and wildcard `export *`.
2. **Lock 2 (`fw:react` — Strict i18n & Zero Hardcoded Strings)**: Bans raw user-facing string literals in JSX and functions; requires `src/i18n/strings.ts`.
3. **Lock 3 (`addon:design-system` — M3 Token Purity & Color Pairing)**: Bans hardcoded colors/durations/radii/fonts and enforces MD3 `bg` ↔ `color` semantic token pairing.
4. **Lock 4 (`fw:react` — True Atomic Purity & Stateless Atoms)**: Bans raw HTML (`<div>`), `<panda.div>`, `style={}`, Tailwind classes, `useEffect` in UI/routes, and all `use*` hooks in `src/components/atoms/`.
5. **Lock 5 (`addon:design-system` — Panda CSS Recipes & Canonical Deduplication)**: Max 3 inline layout props on JSX containers, mandatory `defaultVariants`, styled slot anatomy, and commutative recipe block deduplication.
6. **Lock 6 (`addon:testing-fortress` — Polyglot Test Assertion Purity, 1:1 TDD Companions & Mutation Testing)**: Bans skipped/focused tests (`it.skip`, `test.only`, `pytest.skip`, `@Disabled`, `->skip()`), weak/tautological matchers (`toBeTruthy`, `toMatchSnapshot`, `assert True`, `assertTrue(true)`), and `vi.mock()`. Requires 1:1 `.test.ts(x)` companions and enforces cross-language coverage & mutation gates (`StrykerJS >= 95%`, `mutmut >= 90%`, `PITest + Arcmutate >= 85%`, `Infection + PHPStan >= 85%`).
7. **JVM & Minecraft Modding Gates (`lang:java`, `lang:kotlin`, `fw:minecraft`, `fw:quilt`, `fw:fabric`)**:
   - **Detekt & Checkstyle/PMD Fortress**: `maxIssues: 0`, `warningsAsErrors: true`, `CyclomaticComplexMethod <= 10`, `CognitiveComplexMethod <= 10`, `LongMethod <= 40`, `LargeClass <= 250`, zero wildcard imports, zero `!!` non-null assertions in `src/main/`, zero `GlobalScope`, and zero `println`/`System.out`.
   - **Client/Server Physical Side Separation**: `server/` and `common/` packages must NEVER import `net.minecraft.client.*`, `com.mojang.blaze3d.*`, or client-only loader entrypoints. `client/` packages must NEVER import `net.minecraft.server.dedicated.*`.
   - **Mixin Safety**: `@Overwrite` and `@Redirect` are strictly forbidden; use `@Inject` or MixinExtras `@WrapOperation` / `@ModifyExpressionValue` with `injectors.defaultRequire: 1`.
8. **Python (`uv`), Flet, NiceGUI, LangChain & Jupyter Gates (`lang:python`, `fw:flet`, `fw:nicegui`, `fw:langchain`, `fw:jupyter`)**:
   - **`lang:python` (Geranium Fortress)**: Exclusive `uv` package management (`Pipfile`/`poetry.lock`/`setup.py` forbidden), max **256 lines** per `.py` file, Ruff McCabe `max-complexity = 8`, Pylint `max-statements = 20`, `max-args = 5`, `max-branches = 8`, `max-returns = 4`, strict `mypy`, zero raw `print()` in `src/`, zero vague variable names (`data`, `res`, `temp`, `info`) in `src/`, and `pydantic-settings` `SecretStr` `/run/secrets/` injection.
   - **`fw:flet`**: Material Design 3 (`use_material3=True`, semantic `ft.Colors.*` tokens banning hardcoded hex/named colors in `ui/`), 5-level Atomic Design (`atoms` -> `molecules` -> `organisms` -> `templates` -> `views`), and zero direct AI/TTS SDK imports inside `ui/`.
   - **`fw:nicegui`**: Non-blocking async event-loop gates (bans `time.sleep` and synchronous `requests.*` in `src/`; requires `asyncio.sleep`, `httpx.AsyncClient`, `run.io_bound`, or `run.cpu_bound`), Atomic UI hierarchy, and `nicegui.testing.User` verification.
   - **`fw:langchain`**: Modern LCEL (`prompt | llm`) and LangGraph (`StateGraph`) only (bans deprecated `LLMChain`, `SequentialChain`, `initialize_agent`), `SecretStr` API key hygiene, and 100% mocked external LLM/TTS/MCP calls in `tests/`.
   - **`fw:jupyter` (`jupiter`)**: Valid `nbformat >= 4` `.ipynb` JSON, Clean Output Gate (`outputs: []` and `execution_count: null` enforced by `task lint` and auto-stripped by `task format`), zero in-cell `!pip`/`%pip`/`%conda` installs, max 30 lines per code cell, and `pytest --nbmake`.
   - **`fw:django`**: HackSoft Services/Selectors ("Fat-Free Views": zero `.objects.create`/`update`/`delete` or `transaction.atomic` in `views.py`), Ruff `flake8-django` (`DJ001`/`DJ008`/`DJ012`), `.djlintrc` template formatting & WCAG 2.2 AA a11y, `django-stubs` strict MyPy, zero `.raw()`/`.extra()`/`mark_safe()`/`|safe`, and settings secret hardening.
9. **PHP & Symfony 7.x+ Gates (`lang:php`, `fw:symfony` / `symphony`)**:
   - Mandatory `declare(strict_types=1);` in every `.php` file, Laravel Pint, PHPStan (`level: max` + `phpstan-symfony` + `phpstan-doctrine`), **Deptrac** Hexagonal layers (`deptrac.yaml`: `Domain` has zero `Doctrine\*`/`Symfony\*` imports; `Controller` has zero `EntityManager` or `$this->container->get()`), Twig-CS-Fixer + Twig XSS (`|raw` banned) & WCAG 2.2 AA a11y, Pest `>= 85%` coverage, and Infection PHP `>= 85%` MSI.

---

## 4. Zero Linter / Typechecker Bypass Policy (`rules/ast/no-linter-bypass.yml`)
Suppressing errors via comments or annotations (`eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `# noqa`, `# type: ignore`, `@SuppressWarnings`, `@Suppress`, `@file:Suppress`, `@phpstan-ignore`, `nosemgrep`) is strictly forbidden.
