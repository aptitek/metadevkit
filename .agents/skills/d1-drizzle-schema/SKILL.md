---
name: d1-drizzle-schema
description: >-
  Design and migrate Drizzle ORM schemas for Cloudflare D1 SQLite databases
  (addon:drizzle-d1, drizzle.config.ts). Use when creating tables, relations,
  indexes, or D1 migrations in src/db/schema.ts.
---

# Skill: Drizzle ORM + Cloudflare D1 Schema (`d1-drizzle-schema`)

Governed by `drizzle.config.ts` (`schema: "./src/db/schema.ts"`, `out: "./drizzle/migrations"`, `dialect: "sqlite"`) and `.guardrails/taskfiles/Taskfile.drizzle-d1.yml`.

## 1. Critical Cloudflare D1 SQLite Constraints
1. **Foreign keys are ALWAYS enforced** in D1. Define `.references(() => parent.id, { onDelete: "cascade" })` carefully.
2. **No native BOOLEAN or DATETIME types**:
   - Booleans: `integer("is_active", { mode: "boolean" }).notNull().default(false)`
   - Timestamps: `integer("created_at", { mode: "timestamp" }).notNull().$defaultFn(() => new Date())`
   - UUID Primary Keys: `text("id").primaryKey().$defaultFn(() => crypto.randomUUID())`
3. **100 Bound Parameter Limit**:
   - D1 caps bound parameters at **100 per query**. Batch bulk inserts with `const batchSize = Math.floor(100 / columnsPerRow)`.

## 2. Migration Commands (`task`)
- Generate SQLite/D1 migrations: `task drizzle-d1:db:generate`
- Verify migration consistency: `task drizzle-d1:db:check`
- Lint Drizzle config: `task drizzle-d1:lint`
