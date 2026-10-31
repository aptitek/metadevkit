---
name: minecraft-server-admin
description: >-
  Configure, profile, and operate Minecraft 1.21.x dedicated servers (Quilt, Fabric,
  Paper, Folia, Velocity) including Spark profiling, JVM G1GC tuning, Docker Compose,
  and backup/recovery runbooks.
---

# Minecraft Dedicated Server Operations (`minecraft-server-admin`)

## 1. Performance Profiling & Tick Budget (20 TPS = 50ms MSPT)
- Profile server tick bottlenecks with **Spark** (`spark profiler`, `spark healthreport`, `spark tickmonitor`) before changing server or mod configurations.
- Keep average MSPT well below `50ms` so the server maintains a steady `20.0 TPS`.
- Use Java 21 with Aikar's / G1GC flags (`-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200`).
- Never expose backend server ports or RCON ports directly to the public internet.
