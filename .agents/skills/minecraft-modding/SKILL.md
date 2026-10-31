---
name: minecraft-modding
description: >-
  Full-stack Minecraft 1.21+ mod development skill for Quilt, Fabric, NeoForge,
  and Architectury. Scaffolds mods, blocks, items, entities, recipes, commands,
  GUIs, dimensions, and data generation while enforcing Client/Server side separation.
---

# Minecraft Modding (`minecraft-modding`)

## 1. Universal Command Interface (`task`)
Always interact with the mod build and test lifecycle through `task`:
- `task dev` — Launch Minecraft Client (`runClient`)
- `task minecraft:server` — Launch Dedicated Server (`runServer`)
- `task minecraft:gametest` — Run headless Mojang GameTest Server (`runGameTestServer`)
- `task minecraft:datagen` — Run Data Generation (`runData`)
- `task lint` — Run Client/Server side-separation, Mixin safety, and 1.21+ asset checks
- `task verify` — Full verification gate (`guard:check`, `lint`, `dup`, `complexity`, `sec`, `test`)

## 2. Core Architectural Rules (`fw:minecraft`)
1. **Strict Physical Side Separation**:
   - **Never** import `net.minecraft.client.*` or `com.mojang.blaze3d.*` inside `server/` or `common/` packages (enforced by `.guardrails/ast/minecraft.yml`, Detekt `ForbiddenImport`, and `validate-minecraft-mod.sh`).
   - **Never** import `net.minecraft.server.dedicated.*` inside `client/` packages.
2. **Registries (`Registries` + `Identifier` / `ResourceLocation`)**:
   - Register all blocks, items, entities, block entities, menus, payloads, and sounds during mod initialization using `ResourceLocation.fromNamespaceAndPath(MOD_ID, path)` or `Identifier.of(MOD_ID, path)`.
3. **1.21+ Singular Data Pack Paths**:
   - Always use singular folder names in `data/<modid>/`: `loot_table/`, `recipe/`, `advancement/`, `predicate/`, `item_modifier/`, `tags/block/`, `tags/item/`, `tags/function/`. Legacy plural paths (`loot_tables/`, `tags/blocks/`, `tags/items/`) are blocked by `task lint`.
4. **Versioning**:
   - Follow `{mod_version}+{mc_version}` (e.g. `1.0.0+1.21.4` or `1.0.0+1.21.11`).
