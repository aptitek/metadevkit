---
name: minecraft-resource-pack
description: "Create and validate Minecraft 1.21.x resource packs and mod assets (assets/<modid>/items/, models, blockstates, sounds, lang)."
---

# Minecraft Resource Pack & Mod Assets (`minecraft-resource-pack`)

## 1. Asset Integrity Gates (`validate-minecraft-mod.sh` via `task lint`)
| Gate | Requirement |
| :--- | :--- |
| **JSON Validity** | All `pack.mcmeta`, `assets/**/items/*.json`, `models/**/*.json`, `blockstates/*.json`, `lang/*.json`, and `sounds.json` must parse via `jq` |
| **1.21.4+ `items/` Definition** | In Minecraft 1.21.4+, every item requires an item model definition at `assets/<modid>/items/<item_id>.json` pointing to `assets/<modid>/models/item/<item_id>.json` |
| **Animation Pairing** | Every `*.png.mcmeta` must have a matching `*.png` texture in the same directory |
| **Pack Formats** | `34` (1.21–1.21.1), `42` (1.21.2–1.21.3), `46` (1.21.4), `55` (1.21.5), `64` (1.21.7–1.21.8) |

## 2. Canonical 1.21.4+ `assets/<modid>/items/<item_id>.json`
```json
{
  "model": {
    "type": "minecraft:model",
    "model": "my_mod:item/custom_wand"
  }
}
```
