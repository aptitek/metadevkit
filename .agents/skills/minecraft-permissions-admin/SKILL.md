---
name: minecraft-permissions-admin
description: >-
  Design and audit Minecraft server permission hierarchies (LuckPerms, Fabric
  Permissions API me.lucko.fabric.api.permissions.v0, and vanilla op levels 1-4).
---

# Minecraft Permissions & Access Control (`minecraft-permissions-admin`)

## 1. Mod Permission Checks
- Prefer checking permissions via the **Fabric Permissions API** (`Permissions.check(source, "<modid>.command.<action>", 2)`) with a fallback to vanilla operator level (`source.hasPermission(2)`).
- Never grant wildcard (`*`) permissions to default player groups or unauthenticated clients.
- Log all administrative state changes (ban, rule toggle, config reload) with the actor's name and UUID.
