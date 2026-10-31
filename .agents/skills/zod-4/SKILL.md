---
name: zod-4
description: >-
  Zod 4 schema validation and safeParse patterns for trust boundaries. Use when
  creating or updating Zod v4 schemas for forms, API payloads, environment
  variables, content collections, or replacing banned 'as T' type assertions.
---

# Skill: Zod 4 Trust-Boundary Validation (`zod-4`)

Because Lock 1 bans `as T` type assertions, `x is T` type predicates, and `throw` statements in pure modules, always parse untrusted data at I/O boundaries using **Zod 4** and `.safeParse()`.

## 1. Zod 4 Top-Level Validators
```typescript
import { z } from "zod";

const userSchema = z.object({
  id: z.uuid(),
  email: z.email({ error: "Invalid email address" }),
  website: z.url().optional(),
  name: z.string().min(1, { error: "Name is required" }),
  role: z.enum(["admin", "editor", "viewer"]),
});

export type User = z.infer<typeof userSchema>;
```
