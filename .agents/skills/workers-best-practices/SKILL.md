---
name: workers-best-practices
description: >-
  Cloudflare Workers, Pages, D1, and R2 production best practices and security
  guardrails (addon:cloudflare). Use when writing or reviewing Worker handlers,
  bindings, D1 queries, or R2/KV storage operations.
---

# Skill: Cloudflare Workers & Edge Security (`workers-best-practices`)

Governed by `.guardrails/ast/cloudflare.yml` and `.guardrails/taskfiles/Taskfile.cloudflare.yml`.

## 1. Mandatory AST & Security Rules (`.guardrails/ast/cloudflare.yml`)
1. **Parameterized D1 SQL Queries Only**:
   - String interpolation inside `env.DB.prepare(\`SELECT ... \${val}\`)` is strictly forbidden.
   - Always use positional `?` placeholders and `.bind(...)`:
     ```typescript
     const user = await env.DB.prepare("SELECT id, email FROM users WHERE id = ?")
       .bind(userId)
       .first();
     ```
2. **No Module-Level Mutable Request State**:
   - Workers reuse isolates across concurrent requests; never store per-request state in module-scoped variables.
3. **Promise Lifetime & Streaming**:
   - Always `await` async operations or attach background work to `ctx.waitUntil(promise)` (never destructure `const { waitUntil } = ctx`).
   - Stream large payloads instead of buffering unbounded `await response.text()`.
4. **Web Crypto Security**:
   - Never use `Math.random()` for tokens or IDs; use `crypto.randomUUID()` or `crypto.getRandomValues()`.
   - Never hardcode secrets in code or `wrangler.toml`.
