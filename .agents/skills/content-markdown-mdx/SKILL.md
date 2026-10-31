---
name: content-markdown-mdx
description: >-
  Author and validate pure Markdown (.md), zero-styling MDX (.mdx), and interactive
  course/simulation content (addon:content-md). Use when editing files in
  content/, courses/, src/content/, or docs/.
---

# Skill: Markdown & MDX Content Purity (`content-markdown-mdx`)

## Core Rules
- **Pure `.md`**: No raw HTML tags; balanced code fences (` ``` `) and depth-matched directive fences (`:::`, `::::`).
- **Zero-Styling `.mdx`**: No `style={}`, `className=`, `<style>`, or CSS/`styled-system` imports in `.mdx`.
- **Courses (`courses/**`)**: Mandatory YAML frontmatter with `title`, `description`, and `slug`.
