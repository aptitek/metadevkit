---
name: minecraft-ci-release
description: >-
  Set up CI/CD pipelines, Modrinth (minotaur) and CurseForge publishing, semantic
  versioning ({mod_version}+{mc_version}), and GitHub Actions workflows for Minecraft mods.
---

# Minecraft CI & Release Automation (`minecraft-ci-release`)

## 1. Versioning & Tagging
- Mod artifact version: `{mod_version}+{mc_version}` (e.g., `1.2.0+1.21.4`).
- Git release tag: `v{mod_version}` (e.g., `v1.2.0`).
- Never hardcode `MODRINTH_TOKEN` or `CURSEFORGE_TOKEN` in `gradle.properties` or `build.gradle.kts` (blocked by `lint-secrets.mjs` and Trivy). Read tokens from `System.getenv(...)`.

## 2. Quality Gate Pipeline before Release
Every CI build and release job MUST run:
1. `task verify` (runs `guard:check`, `lint`, `dup`, `complexity`, `sec`, `test`)
2. `task minecraft:gametest` (headless Mojang GameTest Server verification)
