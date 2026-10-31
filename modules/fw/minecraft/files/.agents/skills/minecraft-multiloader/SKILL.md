---
name: minecraft-multiloader
description: >-
  Build Minecraft 1.21+ mods targeting multiple loaders (Quilt, Fabric, NeoForge)
  using Architectury or common/loader subproject layouts. Covers @ExpectPlatform,
  shared registries, gradle.properties version alignment, and side isolation.
---

# Minecraft Multiloader Architecture (`minecraft-multiloader`)

## 1. Subproject Architecture
- `common/`: Shared game logic, pure domain models, and loader-agnostic abstractions. Must NEVER import `net.fabricmc.*`, `org.quiltmc.*`, or `net.neoforged.*`.
- `fabric/` or `quilt/` or `neoforge/`: Loader-specific entrypoints, platform helpers (`*Impl`), and loader-specific Mixins.

## 2. Version Sanity Rules (`gradle.properties`)
- Pin `minecraft_version`, `loom_version`, and loader versions explicitly in `gradle.properties`.
- Never commit `SNAPSHOT` dependency versions in production branches.
- Keep `assets/` and `data/` in the shared `common/src/main/resources/` directory to prevent asset duplication across loader JARs.
