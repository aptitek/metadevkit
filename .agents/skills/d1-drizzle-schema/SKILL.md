---
name: d1-drizzle-schema
description: >-
  Design and migrate Drizzle ORM schemas for Cloudflare D1 SQLite databases
  (addon:drizzle-d1, drizzle.config.ts). Use when creating tables, relations,
  indexes, or D1 migrations in src/db/schema.ts.
---

# Skill: Drizzle ORM + Cloudflare D1 Schema (`d1-drizzle-schema`)

## Core Rules
- Foreign keys are always enforced in D1.
- Use `integer("col", { mode: "boolean" })` for booleans and `integer("col", { mode: "timestamp" })` for timestamps.
- Batch bulk inserts to respect D1's 100 bound parameter limit.
- Run `task drizzle-d1:db:generate` and `task drizzle-d1:db:check`.
