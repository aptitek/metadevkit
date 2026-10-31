---
name: content-markdown-mdx
description: >-
  Author and validate pure Markdown (.md), zero-styling MDX (.mdx), and interactive
  course/simulation content (addon:content-md). Use when editing files in
  content/, courses/, src/content/, or docs/.
---

# Skill: Markdown & MDX Content Purity (`content-markdown-mdx`)

Governed by `.remarkrc.mjs`, `lint-markdown-structure.mjs`, `lint-mdx-purity.mjs`, and `lint-courses-simulations.mjs`.

## 1. Pure Markdown Structural Rules (`lint-markdown-structure.mjs`)
- **Zero Raw HTML in `.md`**: Raw HTML tags (`<div>`, `<span>`, `<br>`) are forbidden in `.md` files. Use Markdown syntax or remark directives (`:::note`, `:::tip`, `:::warning`).
- **Balanced Fences**: Every fenced code block (` ``` `) and every fenced directive block (`:::`, `::::`, `:::::`) must close with the exact matching fence depth.

## 2. Zero-Styling MDX Purity (`lint-mdx-purity.mjs`)
- `.mdx` files are strictly for semantic content and component composition:
  - Inline `style={...}` props are forbidden.
  - `className="..."` props are forbidden.
  - `<style>` tags are forbidden.
  - Direct imports from `styled-system/*` or `*.css` are forbidden in `.mdx`.

## 3. Course Frontmatter & Simulation Registry (`lint-courses-simulations.mjs`)
- Every course file in `courses/**/*.md(x)` must begin with YAML frontmatter declaring `title`, `description`, and `slug`.
- Run `task content-md:lint` (or `task check:quick`) to verify content integrity.
