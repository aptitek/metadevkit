# `polyglot-guardrails` — Single Source of Truth for Polyglot DX & AI Vibe-Coding Guardrails

`polyglot-guardrails` is a composable, zero-config-drift meta-framework that enforces **Haskell-grade Architectural Fortress** quality gates across Web, Cloud, JVM / Minecraft Modding, PHP / Symfony, Shell / Docker, and Python (`uv`) / Django / AI / Jupyter repositories.

---

## ⚡ Quick Start — Installation & Initialisation en 1 ligne (Linux, macOS & Windows MSYS2)

Vous pouvez initialiser n'importe quel projet (vide ou existant) avec un simple **one-liner** agnostique de l'OS. Les alias courts (`ts,react`, `python,django`, `kotlin,quilt`, `php,symfony`, `shell,docker`) résolvent automatiquement `core` ainsi que toutes leurs dépendances (`addon:ui-guardrails`, `fw:minecraft`, etc.).

### 1. One-Liner Universel `curl | bash` (Linux, macOS, Windows MSYS2 / Git Bash / WSL)

```bash
# Stack par défaut (core + lang:ts)
curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash

# Avec choix des modules en paramètre (ex: Python + Django, TS + React, Kotlin + Quilt...)
curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash -s -- python,django
curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash -s -- ts,react,design-system,testing-fortress
curl -fsSL https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.sh | bash -s -- kotlin,quilt,fabric
```

### 2. One-Liner Windows PowerShell (Zéro Prérequis — Auto-installation de MSYS2)

Depuis un terminal PowerShell sous Windows (même sur une machine vierge sans Bash ni `task`) :

```powershell
# Stack par défaut (core + lang:ts)
irm https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.ps1 | iex

# Avec choix des modules
$env:MODULES="python,django"; irm https://raw.githubusercontent.com/aptitek/metadevkit/main/scripts/bootstrap.ps1 | iex
```

### 3. One-Liner via le `Taskfile.yml` Maître Auto-Amorçant

Si `task` (`go-task`) est déjà présent sur votre machine, téléchargez uniquement le `Taskfile.yml` maître dans votre dossier projet : il contient en dur toute la logique de bootstrap (MSYS2, `mise`, clonage et verrouillage SHA-256) :

```bash
# Télécharge Taskfile.yml et lance l'auto-amorçage (par défaut : core,lang:ts)
curl -fsSLO https://raw.githubusercontent.com/aptitek/metadevkit/main/Taskfile.yml && task

# Ou en spécifiant directement vos modules
curl -fsSLO https://raw.githubusercontent.com/aptitek/metadevkit/main/Taskfile.yml && task init MODULES=python,flet,langchain
```

---

## 🛠️ Comment fonctionne l'auto-amorçage (Sous le capot)

Que vous passiez par `curl ... | bash -s -- <modules>`, `bootstrap.ps1` ou le `Taskfile.yml` maître seul :

1. **Provisionnement automatique de MSYS2 sous Windows** :
   - Détecte automatiquement Windows (`Windows_NT` / `MSYS` / `MINGW`).
   - Si `C:\msys64\usr\bin\bash.exe` est absent, installe **MSYS2** (`MSYS2.MSYS2`) silencieusement via `winget`.
   - Installe les utilitaires POSIX indispensables dans MSYS2 via `pacman -S --noconfirm --needed bash git jq curl tar` et injecte `/c/msys64/usr\bin` dans le `PATH`.
   - Pose un fichier `.gitattributes` (`* text=auto eol=lf`) verrouillé pour empêcher `core.autocrlf` de convertir les scripts `.sh` et fichiers verrouillés en `CRLF`.
2. **Installation automatique de `go-task` et `mise`** :
   - Si `mise` ou `task` ne sont pas encore installés, le bootstrap les installe automatiquement (`winget` sous Windows, `brew` sous macOS, ou l'installeur officiel `https://mise.run` sous Linux), puis active les versions figées (`task@3.54`, `jq@1.8`, `lefthook@2.2`, `trivy@0.76` et les outils des modules choisis).
3. **Assemblage modulaire & Verrouillage SHA-256 (`.guardrails.lock`)** :
   - Télécharge la source maître `metadevkit`, résout le graphe de dépendances (DAG) des modules demandés, assemble dynamiquement `Taskfile.yml`, `AGENTS.md`, `mise.toml` et `.gitignore`, et scelle toutes les configurations dans `.guardrails.lock`.
   - Dès la fin du one-liner :
     - `task` (ou `task verify`) lance la vérification complète du projet.
     - `task update` met à jour ce devkit lui-même, les outils `mise` et toutes les dépendances des modules actifs (`uv`, `pnpm`, `composer`, `gradle`).
     - `task feature:add -- <module>` ajoute une brique à chaud (ex: `task feature:add -- docker`).
     - `task guard:sync` synchronise le projet avec la source maître.

---

## 📋 Référence des Commandes Universelles (`task`)

Toutes les opérations du cycle de vie s'exécutent via `task` (`go-task`) avec exactement la même interface, quelle que soit la stack active dans `.guardrails/manifest.json` :

| Commande | Catégorie | Description |
| :--- | :--- | :--- |
| `task` | Cycle de vie | Auto-amorce le projet s'il n'est pas initialisé, sinon lance `task verify` |
| `task bootstrap` | Cycle de vie | Provisionne les prérequis (MSYS2 sous Windows, `mise`) et initialise le projet |
| `task init MODULES=<m1,m2>` | Cycle de vie | Initialise ou reconfigure le projet avec les modules spécifiés (ex: `MODULES=python,django`) |
| `task setup` | Cycle de vie | Installe la chaîne d'outils `mise`, les hooks Git `lefthook` et les dépendances des modules |
| `task update` | Cycle de vie | Met à jour le devkit lui-même, les outils `mise` (`mise upgrade`) et les dépendances (`uv`, `pnpm`, `composer`, `gradle`) |
| `task dev` | Cycle de vie | Démarre l'environnement de développement des modules actifs |
| `task feature:add -- <mod>` | Guardrails | Ajoute un module ou addon à chaud au projet (ex: `task feature:add -- docker`) |
| `task guard:check` | Guardrails | Vérifie l'intégrité cryptographique SHA-256 de tous les fichiers verrouillés (`.guardrails.lock`) |
| `task guard:sync` | Guardrails | Recompile le VFS et resynchronise les configurations depuis la source maître |
| `task guard:sign` / `task guard:lock` | Guardrails | Synchronise les modules maîtres (si dans le devkit) et signe/régénère les sommes SHA-256 de `.guardrails.lock` |
| `task check:quick` | Tier 1 (< 3s) | Boucle rapide inner-loop : `guard:check` + `ast:check` + `lint` |
| `task test:quick` | Tier 1 (< 3s) | Exécution rapide des tests unitaires |
| `task check:commit` | Tier 2 (< 10s) | Gate de pré-commit : `guard:check` + `lint` + `complexity` + `test` |
| `task check:push` / `task verify` | Tier 3 (Complet) | Forteresse complète : `guard:check` → `lint` → `typecheck` → `a11y` → `i18n` → `dup` → `complexity` → `sec` → `test` → `coverage` → `mutate` |
| `task format` | Qualité | Formate le code source des modules actifs (`ruff`, `prettier`/`eslint`, `pint`, `spotless`, `djlint`, `shfmt`) |
| `task lint` | Qualité | Analyse statique, règles AST et détection de code mort sur tous les modules actifs |
| `task ast:check` | Qualité | Vérifie les règles AST centralisées et l'absence de contournement de linter (`.guardrails/ast/`) |
| `task typecheck` | Qualité | Vérification stricte du typage statique (`tsc`, `mypy --strict`, `javac`, `kotlinc`, `phpstan`) |
| `task a11y` | Qualité | Vérification d'accessibilité WCAG 2.2 AA, sémantique Flet/NiceGUI et narrateur Minecraft |
| `task i18n` | Qualité | Vérification de parité 100 % des clés de traduction JSON et absence de chaînes UI codées en dur |
| `task dup` | Qualité | Détection de duplication de code via `jscpd` (`.jscpd.json`) |
| `task complexity` | Qualité | Contrôle de la complexité cyclomatique (`CCN <= 8`) et de la taille des fonctions (`lizard` / `radon`) |
| `task sec` | Sécurité | Audit de vulnérabilités, secrets et règles AST de sécurité (`trivy` + `semgrep` + `lint-secrets.sh`) |
| `task test` | Tests | Exécute les suites de tests unitaires et d'intégration des modules actifs |
| `task coverage` | Tests | Vérifie les seuils de couverture de branches et lignes (`TS >= 95%`, `Python >= 90%`, `JVM/PHP >= 85%`) |
| `task mutate` | Tests | Exécute les tests de mutation (`StrykerJS`, `mutmut`, `PITest`/`Arcmutate`, `Infection`) |
| `task self-test` | Meta-Devkit | Exécute la suite d'auto-tests d'intégration de bout en bout |

---

## Architecture: 4 Composable Strata (30 Modules)

1. **`core` (Mandatory Universal Foundation)**:
   - `mise.toml`: `task` (`go-task`), `lefthook`, `jq`, `trivy` (standalone native binaries with pinned versions)
   - Self-bootstrapping `Taskfile.yml` + `Taskfile.base.yml`: Universal lifecycle contract (`bootstrap`, `init`, `setup`, `update`, `dev`, `format`, `lint`, `typecheck`, `a11y`, `i18n`, `dup`, `complexity`, `sec`, `test`, `coverage`, `mutate`, `verify`, `check:quick`, `test:quick`, `check:commit`, `check:push`, `guard:check`, `guard:sync`, `feature:add`)
   - `lefthook.yml`, `lint-secrets.sh`, composable `.gitignore`, LF-normalized `.gitattributes` (MSYS2/Windows safe)
   - Dynamic `AGENTS.md` + `.agents/skills/vibe-guardrails/SKILL.md`: Strict AI Vibe-Coding contract assembled from active module fragments
2. **`lang:<language>` (Language Stratum — alias: `ts`, `python`, `kotlin`, `java`, `php`, `shell`)**:
   - `lang:ts` (Full implementation: **Lock 1 Functional Purity & Total Functions** (`complexity <= 3`, `max-depth <= 1`, `max-lines <= 150`, `max-lines-per-function <= 28`, `max-params <= 3`, zero `let`/`var`/loops/`else`/`as T`/`x!`/`throw`), `pnpm`, `tsconfig.base.json`, dynamic `eslint.config.mjs`, `knip.json`, `.dependency-cruiser.cjs`, `.prettierrc.mjs`, `commitlint.config.mjs`, `.secretlintrc.json`, `.jscpd.json`, `vitest.config.ts` with 95% per-file coverage)
   - `lang:python` (**Geranium Quality Fortress**: `uv` exclusive dependency management, `ruff.toml` extending `.guardrails/python/ruff.base.toml` with `max-complexity = 8`, `max-statements = 20`, `max-args = 5`, `max-branches = 8`, `max-returns = 4`, `line-length = 120`, `<= 256` lines per `.py` file, strict `mypy` + zero-`Any` in `src/`, `coverage.toml` `>= 90%` branch coverage, and **mutmut** `mutmut.toml` `>= 90%` mutation score)
   - `lang:kotlin` (Kotlin 2.x K2 JVM stack: Gradle Kotlin DSL, **Detekt** `detekt.yml` with `maxIssues: 0` & `warningsAsErrors: true` + `detekt-formatting` + per-module `ForbiddenImport` boundary overlays, **Kotest** JUnit 5 + property testing, JaCoCo `>= 85%` coverage, and **PITest 1.30.0 + Arcmutate Kotlin** `pitest-kotlin.gradle.kts` `>= 85%` mutation threshold)
   - `lang:java` (Java 21 stack: Gradle, Spotless, Checkstyle `checkstyle.xml`, PMD `pmd-ruleset.xml`, JUnit 5, JaCoCo `>= 85%` coverage, **PITest 1.30.0** `pitest.gradle.kts` `>= 85%` mutation threshold, and AST rules banning wildcard imports, `System.out`, `printStackTrace()`, and raw `Optional.get()`)
   - `lang:php` (`composer`, `pint`, `phpstan` level `max`, `declare(strict_types=1);` enforcement, `pest` `>= 85%` coverage, and **Infection PHP + PHPStan** `infection.json5` `>= 85%` MSI / `>= 90%` Covered MSI)
   - `lang:shell` (`shellcheck`, `shfmt`, `bash -n`, `set -euo pipefail`, zero `eval` / `curl | sh` / unquoted `$`)
3. **`fw:<framework>` (Hierarchical Framework Stratum — alias: `react`, `react-router`, `astro`, `flet`, `nicegui`, `langchain`, `jupyter`, `django`, `symfony`, `minecraft`, `quilt`, `fabric`)**:
   - `fw:react` (Depends on `lang:ts`, `addon:ui-guardrails`: **Lock 2 Strict i18n**, **Lock 4 True Atomic Purity & Stateless Atoms**, WCAG 2.2 AA `a11y.mjs`, `.size-limit.json`, max 150 lines per `.tsx`, `lint-error-boundaries.mjs`)
   - `fw:react-router` (Depends on `lang:ts` > `fw:react`: route parsimony max 2 top-level layouts & max 12 routes, nested `<Outlet />` hierarchy, loader/action separation)
   - `fw:astro` (Depends on `lang:ts`, `addon:ui-guardrails`: `astro check`, `.size-limit.json`, island architecture & a11y rules)
   - `fw:flet` (Depends on `lang:python`, `addon:ui-guardrails`: Flet Flutter UI engine + Material Design 3 `use_material3=True` & semantic `ft.Colors.*` tokens, 5-level Atomic Design hierarchy `atoms -> molecules -> organisms -> templates -> views`, and `pytest-playwright` E2E verification)
   - `fw:nicegui` (Depends on `lang:python`, `addon:ui-guardrails`: NiceGUI FastAPI/Vue reactive UI with `uv`, non-blocking async event-loop gates banning `time.sleep` and sync `requests.*`, Atomic UI structure, and `nicegui.testing.User` headless testing)
   - `fw:langchain` (Depends on `lang:python`: LangChain LCEL + LangGraph `StateGraph` + `langchain-google-genai` + MCP `mcp` + Google Cloud TTS, banning legacy `LLMChain`/`initialize_agent` and enforcing `SecretStr` injection & mocked tests)
   - `fw:jupyter` (Depends on `lang:python`: Reproducible Jupyter Lab / Notebook stack with `uv`, automatic `.ipynb` cell output stripping via `task format`, Clean Output Gate, zero in-cell `!pip` installs, `<= 30` lines per cell, Ruff native `.ipynb` checks, and `pytest --nbmake`)
   - `fw:django` (Depends on `lang:python`, `addon:ui-guardrails`: Django 5.x+ with `uv`, HackSoft Services/Selectors "Fat-Free Views" architecture, Ruff `flake8-django` `DJ001`/`DJ008`/`DJ012`, `.djlintrc` template formatting & WCAG 2.2 AA a11y, `django-upgrade`, `django-stubs` strict MyPy, SQLi/XSS & settings hardening, and `pytest-django` + `mutmut`)
   - `fw:symfony` (Depends on `lang:php`, `addon:ui-guardrails`: Symfony 7.x+ Hexagonal Architecture with locked `deptrac.yaml`, thin invokable controllers with `#[MapRequestPayload]`, Twig-CS-Fixer & Twig XSS/WCAG 2.2 AA gates, `bin/console lint:container`/`lint:yaml`/`lint:twig`, PHPStan Symfony+Doctrine `level: max`, and Infection PHP mutation testing)
   - `fw:minecraft` (Depends on `core`, `lang:java`, `addon:ui-guardrails`: Client/Server physical side-separation AST & validator rules banning `net.minecraft.client.*` and `com.mojang.blaze3d.*` in `server/` or `common/`, Spongeian Mixin & MixinExtras conflict gates banning `@Overwrite` and `@Redirect`, Mojang GameTest Server harness `runGameTestServer`, and 1.21+ singular resourcepack/datapack validators)
   - `fw:quilt` (Depends on `fw:minecraft`: Quilt Loom `org.quiltmc.loom`, `quilt.mod.json` schema & entrypoint/mixin config verification, `quilt-kotlin-libraries`)
   - `fw:fabric` (Depends on `fw:minecraft`: Fabric Loom `fabric-loom`, `fabric.mod.json` schema & entrypoint/mixin config verification, Fabric API, `fabric-language-kotlin`)
4. **`addon:<feature>` (Orthogonal Cross-Cutting Addons — alias: `devkit`, `docker`, `ffmpeg`, `ui-guardrails`, `design-system`, `testing-fortress`, `storybook`, `content-md`, `cloudflare`, `drizzle-d1`, `lib-exports`)**:
   - `addon:devkit` (Self-governance for `polyglot-guardrails`: `validate-devkit.sh` enforcing `module.json` schemas, `SKILL.md <= 100` lines 3-tier Progressive Disclosure, pinned `mise.fragment.toml` versions, and Semgrep AST rule integrity)
   - `addon:docker` (Dockerfile & Compose hardening: pinned image tags, non-root `USER`, `HEALTHCHECK`)
   - `addon:ffmpeg` (FFmpeg audio/video pipeline safety: explicit argument arrays, `loudnorm` EBU R128 normalization)
   - `addon:ui-guardrails` (`validate-i18n-and-a11y.sh`: Cross-language 100% locale JSON key parity, WCAG 2.2 AA JSX/Astro checks, Flet/NiceGUI semantic labels & tooltips, and Minecraft Screen Narrator `Component.translatable` enforcement)
   - `addon:design-system` (**Lock 3 M3 Token Purity & Color Pairing** + **Lock 5 Panda CSS Recipes & Canonical Deduplication**, `panda.config.ts`, `lint-css-tokens.mjs`)
   - `addon:testing-fortress` (**Polyglot Lock 6 Test Assertion Purity**: zero skipped/focused tests, zero weak/tautological assertions, zero `vi.mock()`, 1:1 `.test.ts(x)` TDD companions, cross-language mutation testing via `task mutate`, and `playwright.config.ts` + `stryker.config.mjs` when `lang:ts` is active)
   - `addon:storybook` (100% CSF3 `.stories.tsx` component coverage & CSF3 AST enforcement)
   - `addon:content-md` (`.remarkrc.mjs`, Markdown structural integrity, zero-styling `.mdx` purity, course frontmatter & simulation registry validation)
   - `addon:cloudflare` (`wrangler`, `cloudflared`, `wrangler.toml` validation, Workers/D1/R2 AST rules)
   - `addon:drizzle-d1` (`drizzle.config.ts`, Cloudflare D1 SQLite schema & migration checks)
   - `addon:lib-exports` (Explicit named barrel exports in `src/index.ts`, zero `export *`, ESM `package.json` export validation)
