---
name: wrangler
description: >-
  Manage Cloudflare Wrangler configuration (wrangler.toml / wrangler.jsonc),
  binding type generation, and local validation via task cloudflare:*. Use when
  configuring Cloudflare Workers, D1, R2, KV, or Previews.
---

# Skill: Wrangler Configuration & Lifecycle (`wrangler`)

## Core Rules
- `wrangler.toml` / `wrangler.jsonc` must define `name` and `compatibility_date` (`YYYY-MM-DD`).
- Never place secrets (`SECRET`, `TOKEN`, `PASSWORD`, `PRIVATE_KEY`, `API_KEY`) inside `[vars]`.
- Run `task cloudflare:lint`, `task cloudflare:sec`, and `task cloudflare:typegen`.
