# `polyglot-guardrails` — Single Source of Truth for Polyglot DX & AI Vibe-Coding Guardrails

`polyglot-guardrails` is a composable, zero-config-drift meta-framework that enforces **Haskell-grade Architectural Fortress** quality gates across Web, Cloud, JVM / Minecraft Modding, and Python (`uv`) / AI / Jupyter repositories.

## Architecture: 4 Composable Strata (23 Modules)

1. **`core` (Mandatory Universal Foundation)**:
   - `mise.toml`: `go-task`, `lefthook`, `jscpd` (`0%` duplication tolerance), `lizard`, `trivy`, `semgrep`, `copier`
   - `Taskfile.base.yml`: Universal lifecycle contract (`setup`, `dev`, `format`, `lint`, `dup`, `complexity`, `sec`, `test`, `verify`, `check:quick`, `test:quick`, `check:commit`, `check:push`, `guard:check`, `guard:sync`, `feature:add`)
   - `lefthook.yml`, `commitlint.config.mjs` (mandatory architectural scopes, min 15-char subject), `.secretlintrc.json` + `lint-secrets.mjs`
   - `AGENTS.md` + `.agents/skills/vibe-guardrails/SKILL.md`: Strict AI Vibe-Coding contract
2. **`lang:<language>` (Language Stratum)**:
   - `lang:ts` (Full implementation: **Lock 1 Functional Purity & Total Functions** (`complexity <= 3`, `max-depth <= 1`, `max-lines <= 150`, `max-lines-per-function <= 28`, `max-params <= 3`, zero `let`/`var`/loops/`else`/`as T`/`x!`/`throw`), `pnpm`, `tsconfig.base.json`, dynamic `eslint.config.mjs`, `knip.json`, `.dependency-cruiser.cjs`, `.prettierrc.mjs`, `.size-limit.json`, `vitest.config.ts` with 95% per-file coverage, `lint-deprecated-deps.mjs`)
   - `lang:python` (**Geranium Quality Fortress**: `uv` exclusive dependency management, `ruff.toml` with `max-complexity = 8`, `max-statements = 20`, `max-args = 5`, `max-branches = 8`, `max-returns = 4`, `line-length = 120`, `<= 256` lines per `.py` file, strict `mypy`, `radon cc`, `vulture`, `pydantic-settings` `/run/secrets/` secret hygiene, and `pytest`)
   - `lang:kotlin` (Kotlin 2.x K2 JVM stack: Gradle Kotlin DSL, **Detekt** `detekt.yml` with `maxIssues: 0` & `warningsAsErrors: true` + `detekt-formatting` + per-module `ForbiddenImport` boundary overlays, **Kotest** JUnit 5 + property testing, Coroutines test, JaCoCo with `**/mixin/**` exclusion)
   - `lang:java` (Java 21 stack: Gradle, Spotless, Checkstyle `checkstyle.xml`, PMD `pmd-ruleset.xml`, JUnit 5, JaCoCo, and AST rules banning wildcard imports, `System.out`, `printStackTrace()`, and raw `Optional.get()`)
   - `lang:php` (`composer`, `pint`, `phpstan`, `pest`)
3. **`fw:<framework>` (Hierarchical Framework Stratum)**:
   - `fw:react` (Depends on `lang:ts`: **Lock 2 Strict i18n**, **Lock 4 True Atomic Purity & Stateless Atoms**, WCAG 2.2 AA `a11y.mjs`, max 150 lines per `.tsx`, `lint-error-boundaries.mjs`)
   - `fw:react-router` (Depends on `lang:ts` > `fw:react`: route parsimony max 2 top-level layouts & max 12 routes, nested `<Outlet />` hierarchy, loader/action separation)
   - `fw:astro` (Depends on `lang:ts`: `astro check`, island architecture & a11y rules)
   - `fw:flet` (Depends on `lang:python`: Flet Flutter UI engine + Material Design 3 `use_material3=True` & semantic `ft.Colors.*` tokens, 5-level Atomic Design hierarchy `atoms -> molecules -> organisms -> templates -> views`, and `pytest-playwright` E2E verification)
   - `fw:nicegui` (Depends on `lang:python`: NiceGUI FastAPI/Vue reactive UI with `uv`, non-blocking async event-loop gates banning `time.sleep` and sync `requests.*`, Atomic UI structure, and `nicegui.testing.User` headless testing)
   - `fw:langchain` (Depends on `lang:python`: LangChain LCEL + LangGraph `StateGraph` + `langchain-google-genai` + MCP `mcp` + Google Cloud TTS + FFmpeg post-processing, banning legacy `LLMChain`/`initialize_agent` and enforcing `SecretStr` injection & mocked tests)
   - `fw:jupyter` (Depends on `lang:python`, aliased as `jupiter`: Reproducible Jupyter Lab / Notebook stack with `uv`, automatic `.ipynb` cell output stripping via `task format`, Clean Output Gate, zero in-cell `!pip` installs, `<= 30` lines per cell, Ruff native `.ipynb` checks, and `pytest --nbmake`)
   - `fw:minecraft` (Depends on `core`, `lang:java`: Client/Server physical side-separation AST & validator rules banning `net.minecraft.client.*` and `com.mojang.blaze3d.*` in `server/` or `common/`, Spongeian Mixin & MixinExtras conflict gates banning `@Overwrite` and `@Redirect`, Mojang GameTest Server harness `runGameTestServer`, and 1.21+ singular resourcepack/datapack validators)
   - `fw:quilt` (Depends on `fw:minecraft`: Quilt Loom `org.quiltmc.loom`, `quilt.mod.json` schema & entrypoint/mixin config verification, `quilt-kotlin-libraries`)
   - `fw:fabric` (Depends on `fw:minecraft`: Fabric Loom `fabric-loom`, `fabric.mod.json` schema & entrypoint/mixin config verification, Fabric API, `fabric-language-kotlin`)
4. **`addon:<feature>` (Orthogonal Cross-Cutting Addons)**:
   - `addon:design-system` (**Lock 3 M3 Token Purity & Color Pairing** + **Lock 5 Panda CSS Recipes & Canonical Deduplication**, `panda.config.ts`, `lint-css-tokens.mjs`)
   - `addon:testing-fortress` (**Lock 6 Test Assertion Purity**, zero `vi.mock()`/`it.skip`/weak matchers, 1:1 `.test.ts(x)` TDD companions, `stryker.config.mjs` 95% mutation threshold, `playwright.config.ts`)
   - `addon:storybook` (100% CSF3 `.stories.tsx` component coverage & CSF3 AST enforcement)
   - `addon:content-md` (`.remarkrc.mjs`, Markdown structural integrity, zero-styling `.mdx` purity, course frontmatter & simulation registry validation)
   - `addon:cloudflare` (`wrangler`, `cloudflared`, `wrangler.toml` validation, Workers/D1/R2 AST rules)
   - `addon:drizzle-d1` (`drizzle.config.ts`, Cloudflare D1 SQLite schema & migration checks)
   - `addon:lib-exports` (Explicit named barrel exports in `src/index.ts`, zero `export *`, ESM `package.json` export validation)

## Usage

```bash
# Run meta-framework verification + end-to-end integration self-test
task verify

# Initialize a Web project
task init -- --target /path/to/web-app --modules core,lang:ts,fw:react,addon:design-system,addon:testing-fortress,addon:storybook

# Initialize a Python (uv) + Flet MD3 + LangChain/LangGraph AI Studio project (Geranium stack)
task init -- --target /path/to/geranium-app --modules core,lang:python,fw:flet,fw:langchain

# Initialize a Python (uv) + NiceGUI + Jupyter Lab project
task init -- --target /path/to/nicegui-jupyter --modules core,lang:python,fw:nicegui,fw:jupyter

# Initialize a Kotlin + Quilt Minecraft Mod project (stellar-mods stack)
task init -- --target /path/to/mc-mod --modules core,lang:kotlin,fw:quilt
```
