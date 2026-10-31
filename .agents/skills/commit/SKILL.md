---
name: commit
description: >-
  Create git commits following strict Conventional Commits and architectural scope
  rules enforced by commitlint.config.mjs and lefthook.yml. Use whenever committing
  code, preparing a commit message, or saving changes in git.
---

# Skill: Architectural Conventional Commits (`commit`)

Every commit message is validated by `commitlint.config.mjs` and the `lefthook.yml` `commit-msg` hook.

## 1. Mandatory Format
```text
<type>(<scope>): <subject>

<body>

<footer>
```
- **Header max length**: `100` characters (`subject-min-length: 15`).
- **Allowed `<type>` values**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- **Mandatory `<scope>` values** (`scope-empty: never`):
  - Atomic UI layers: `atoms`, `molecules`, `organisms`, `templates`, `pages`
  - Styling & Content: `tokens`, `theme`, `recipes`, `i18n`, `a11y`, `content`, `courses`, `simulations`
  - Platform & Quality: `router`, `seo`, `db`, `auth`, `worker`, `eslint`, `deps`, `ci`, `config`, `scripts`, `tests`, `e2e`, `storybook`, `docs`, `release`, `security`, `guardrails`
- **Subject rules**: lowercase start (`subject-case: lower-case`), imperative mood, no trailing period, at least 15 characters long.
