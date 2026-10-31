---
name: minecraft-commands-scripting
description: >-
  Write Minecraft 1.21.x vanilla commands, Brigadier mod commands, NBT path queries,
  scoreboards, and execute chains for .mcfunction files or server administration.
---

# Minecraft Commands & Brigadier Scripting (`minecraft-commands-scripting`)

## 1. Brigadier Command Registration (Modding)
When registering server commands in Quilt/Fabric mods:
- Register via `CommandRegistrationCallback.EVENT` (or QSL `CommandRegistrationCallback`).
- Always enforce permission levels immediately on the command node:
  ```kotlin
  literal("stellar")
      .requires { source -> source.hasPermission(2) }
  ```
- Keep command execution handlers fast and non-blocking; offload any I/O or HTTP calls to a background `CoroutineScope` and hop back via `source.server.execute { ... }` to send feedback (`source.sendSuccess({ Component.translatable(...) }, true)`).

## 2. Vanilla `execute` & `.mcfunction` Rules
- Avoid unbounded `@e` selectors without `type=`, `distance=`, or `tag=` filters in tick functions.
- Prefer storage NBT (`data modify storage <ns>:<id> ...`) and scoreboards over entity NBT reads in hot tick loops.
