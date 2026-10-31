---
name: minecraft-datapack
description: >-
  Create, edit, and validate Minecraft 1.21.x datapacks and mod data files (data/<modid>/):
  pack.mcmeta, .mcfunction files, advancements, recipes, loot_table, predicates,
  item_modifier, tags, and worldgen overrides.
---

# Minecraft Datapack & Mod Data (`minecraft-datapack`)

## 1. 1.21+ Singular Directory Layout (Enforced by `task lint`)
Starting in Minecraft 1.21+, data pack directories use **singular** names:
- `data/<namespace>/loot_table/` (NOT `loot_tables/`)
- `data/<namespace>/recipe/` (NOT `recipes/`)
- `data/<namespace>/advancement/` (NOT `advancements/`)
- `data/<namespace>/predicate/` (NOT `predicates/`)
- `data/<namespace>/item_modifier/` (NOT `item_modifiers/`)
- `data/<namespace>/function/` (NOT `functions/`)
- `data/<namespace>/tags/block/` (NOT `tags/blocks/`)
- `data/<namespace>/tags/item/` (NOT `tags/items/`)
- `data/<namespace>/tags/function/` (NOT `tags/functions/`)

Legacy plural paths are automatically rejected by `.guardrails/scripts/validate-minecraft-mod.sh`.
