---
name: zod-4
description: >-
  Zod 4 schema validation and safeParse patterns for trust boundaries. Use when
  creating or updating Zod v4 schemas for forms, API payloads, environment
  variables, content collections, or replacing banned 'as T' type assertions.
---

# Skill: Zod 4 Trust-Boundary Validation (`zod-4`)

Because Lock 1 bans `as T` type assertions, `x is T` type predicates, and `throw` statements in pure modules, always parse untrusted data at I/O boundaries using **Zod 4** and `.safeParse()`.

## 1. Zod 4 Top-Level Validators (Breaking Changes from Zod 3)
```typescript
import { z } from "zod";

// Zod 4 top-level format validators (do NOT use deprecated z.string().email())
const userSchema = z.object({
  id: z.uuid(),
  email: z.email({ error: "Invalid email address" }),
  website: z.url().optional(),
  name: z.string().min(1, { error: "Name is required" }),
  role: z.enum(["admin", "editor", "viewer"]),
});

export type User = z.infer<typeof userSchema>;
```

## 2. Total Parsing Without Exceptions (`safeParse`)
Never call `.parse()` inside pure domain modules (it throws on invalid input). Wrap `.safeParse()` to return an explicit discriminated union:
```typescript
export function parseUserPayload(raw: unknown) {
  const parsed = userSchema.safeParse(raw);
  if (!parsed.success) {
    return { ok: false, issues: parsed.error.issues } as const;
  }
  return { ok: true, data: parsed.data } as const;
}
```
