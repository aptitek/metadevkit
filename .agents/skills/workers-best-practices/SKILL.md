---
name: workers-best-practices
description: >-
  Cloudflare Workers, Pages, D1, and R2 production best practices and security
  guardrails (addon:cloudflare). Use when writing or reviewing Worker handlers,
  bindings, D1 queries, or R2/KV storage operations.
---

# Skill: Cloudflare Workers & Edge Security (`workers-best-practices`)

## Core Rules
- **Parameterized D1 SQL Only**: Never interpolate strings inside `env.DB.prepare(\`...\`)`; always use `?` placeholders and `.bind(...)`.
- **No Module-Level Mutable Request State**: Pass request state explicitly.
- **Promise Lifetime**: Always `await` or pass background promises to `ctx.waitUntil(promise)`.
- **Web Crypto**: Use `crypto.randomUUID()` / `crypto.getRandomValues()`, never `Math.random()`.
