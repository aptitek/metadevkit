---
name: wrangler
description: >-
  Manage Cloudflare Wrangler configuration (wrangler.toml / wrangler.jsonc),
  binding type generation, and local validation via task cloudflare:*. Use when
  configuring Cloudflare Workers, D1, R2, KV, or Previews.
---

# Skill: Wrangler Configuration & Lifecycle (`wrangler`)

Governed by `.guardrails/scripts/validate-wrangler.sh` and `.guardrails/taskfiles/Taskfile.cloudflare.yml`.

## 1. Mandatory `wrangler.toml` / `wrangler.jsonc` Rules
1. **Required Fields**:
   - `name` and `compatibility_date` (`YYYY-MM-DD`) are mandatory.
2. **Zero Hardcoded Secrets**:
   - Never place keys matching `SECRET`, `TOKEN`, `PASSWORD`, `PRIVATE_KEY`, or `API_KEY` inside `[vars]` in `wrangler.toml`. Use `.dev.vars` (git-ignored) locally and `wrangler secret put` in production.
3. **Allowed Commands (`task` Interface)**:
   - Validate config & security AST rules: `task cloudflare:lint` / `task cloudflare:sec`
   - Generate Worker binding types (`worker-configuration.d.ts`): `task cloudflare:typegen`
   - Start local edge dev server: `task dev`
