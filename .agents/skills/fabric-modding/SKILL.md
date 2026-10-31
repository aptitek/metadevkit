---
name: fabric-modding
description: >-
  Build Minecraft 1.21+ mods on Fabric MC using Fabric Loom (fabric-loom),
  splitEnvironmentSourceSets(), fabric.mod.json, Fabric API, fabric-language-kotlin,
  and Fabric GameTest API (fabric-gametest-api-v1).
---

# Fabric MC Modding (`fabric-modding`)

## 1. Universal Command Interface (`task`)
- `task lint` — Validates `fabric.mod.json`, Mixin configs, and side-separation rules
- `task fabric:build` — Builds and remaps Fabric JARs (`remapJar`)
- `task dev` — Launches Fabric Client (`runClient`)
- `task minecraft:gametest` — Runs headless Fabric GameTest Server (`runGameTestServer`)
- `task verify` — Full quality gate

## 2. `fabric.mod.json` Contract (Enforced by `validate-fabric-mod.sh`)
Every Fabric mod must provide a valid `src/main/resources/fabric.mod.json`:
```json
{
  "schemaVersion": 1,
  "id": "stellar_tweak",
  "version": "${version}",
  "name": "Stellar Tweak",
  "description": "High-performance Fabric 1.21+ mod.",
  "authors": ["Stellar Team"],
  "license": "MIT",
  "environment": "*",
  "entrypoints": {
    "main": [
      {
        "adapter": "kotlin",
        "value": "com.stellar.tweak.StellarTweakMod"
      }
    ],
    "client": [
      {
        "adapter": "kotlin",
        "value": "com.stellar.tweak.client.StellarTweakClient"
      }
    ],
    "fabric-gametest": [
      "com.stellar.tweak.gametest.StellarTweakGameTests"
    ]
  },
  "mixins": [
    "stellar_tweak.mixins.json"
  ],
  "depends": {
    "fabricloader": ">=0.16.10",
    "fabric-api": "*",
    "fabric-language-kotlin": ">=1.13.0+kotlin.2.1.0",
    "minecraft": "~1.21.4",
    "java": ">=21"
  }
}
```

## 3. Fabric Loom & SourceSet Isolation
1. **Split Environment SourceSets (`loom.splitEnvironmentSourceSets()`)**:
   Prefer `splitEnvironmentSourceSets()` in `build.gradle.kts` or strict `client/` vs `server/` / `common/` package separation so server code can never reference `net.minecraft.client.*` or `net.fabricmc.fabric.api.client.*` at compile time.
2. **Kotlin Entrypoints (`fabric-language-kotlin`)**:
   Specify `"adapter": "kotlin"` in `fabric.mod.json` when an entrypoint is a Kotlin `object` implementing `ModInitializer` or `ClientModInitializer`.
3. **Fabric Events & Networking**:
   Use `PayloadTypeRegistry.playS2C()` / `playC2S()`, `ServerPlayNetworking`, `ClientPlayNetworking`, and `ServerTickEvents` / `ClientTickEvents`. Always hop from Netty worker threads onto `server.execute { ... }` or `client.execute { ... }`.
