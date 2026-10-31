---
name: quilt-modding
description: >-
  Build Minecraft 1.21+ mods on Quilt MC using Quilt Loom (org.quiltmc.loom),
  quilt.mod.json, quilt-kotlin-libraries (QKL), Quilted Fabric API (QFAPI),
  soft optional dependencies, and multi-module Detekt architectural locks.
---

# Quilt MC Modding (`quilt-modding`)

## 1. Universal Command Interface (`task`)
- `task lint` — Validates `quilt.mod.json`, Mixin configs, and side-separation rules
- `task quilt:build` — Builds and remaps Quilt JARs (`remapJar`)
- `task dev` — Launches Quilt Client (`runClient`)
- `task minecraft:gametest` — Runs headless Mojang GameTest Server (`runGameTestServer`)
- `task verify` — Full quality gate

## 2. `quilt.mod.json` Contract (Enforced by `validate-quilt-mod.sh`)
Every Quilt mod must provide a valid `src/main/resources/quilt.mod.json`:
```json
{
  "schema_version": 1,
  "quilt_loader": {
    "group": "com.stellar",
    "id": "stellar_ops",
    "version": "${version}",
    "metadata": {
      "name": "Stellar Ops",
      "description": "High-performance server operations mod.",
      "contributors": {
        "Stellar Team": "Owner"
      },
      "license": "MIT",
      "environment": "dedicated_server"
    },
    "intermediate_mappings": "net.fabricmc:intermediary",
    "entrypoints": {
      "init": [
        "com.stellar.ops.StellarOpsMod"
      ]
    },
    "depends": [
      {
        "id": "quilt_loader",
        "versions": ">=0.29.0"
      },
      {
        "id": "quilt_kotlin_libraries",
        "versions": ">=2.1.0"
      },
      {
        "id": "minecraft",
        "versions": "~1.21.4"
      },
      {
        "id": "stellar_law",
        "versions": "*",
        "optional": true
      }
    ]
  },
  "mixin": "stellar_ops.mixins.json"
}
```

## 3. `stellar-mods` Multi-Module & Soft-Dependency Architecture
1. **Shared Core via Jar-in-Jar (`include`)**:
   Bundle shared core utilities inside standalone feature mods without external runtime dependencies:
   ```kotlin
   dependencies {
       implementation(project(":stellar-core", configuration = "namedElements"))
       include(project(":stellar-core"))
   }
   ```
2. **Soft Optional Integrations (`compileOnly` + `"optional": true`)**:
   Declare optional sibling/third-party mods with `compileOnly(...)` in `build.gradle.kts` and `"optional": true` in `quilt.mod.json`, guarding runtime calls via `QuiltLoader.isModLoaded("stellar_law")`.
3. **Side-Specific Detekt Boundaries (`config/detekt/detekt-<module>.yml`)**:
   - Server-only mods (`environment: "dedicated_server"`) must forbid `net.minecraft.client.*`, `com.mojang.blaze3d.*`, and `org.quiltmc.qsl.base.api.entrypoint.client.*`.
   - Client-only mods (`environment: "client"`) must forbid `net.minecraft.server.dedicated.*` and `org.quiltmc.qsl.base.api.entrypoint.server.*`.
