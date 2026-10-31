---
name: docker-expert
description: "Author multi-stage uv Alpine Dockerfiles and hardened compose.yaml files with /run/secrets tmpfs secret injection."
---

# Docker & Compose for `uv` Python (`docker-expert`)

## 1. Hard Container Security & Performance Gates
| Gate | Requirement |
| :--- | :--- |
| **Base Image** | Pin `ghcr.io/astral-sh/uv:python3.12-alpine` (or `python3.14-alpine`) in multi-stage builder + runtime |
| **Layer Caching** | Copy `pyproject.toml` + `uv.lock` first; run `uv sync --frozen --no-install-project --no-dev` with `--mount=type=cache,target=/root/.cache/uv` before copying `src/` |
| **Bytecode & Copy** | Set `UV_COMPILE_BYTECODE=1` and `UV_LINK_MODE=copy` in builder stage |
| **Non-Root User** | Create and switch to `USER appuser` in runtime stage (`no-new-privileges:true` in Compose) |
| **Secrets Injection** | Mount production API keys via Compose `secrets:` (`/run/secrets/<name>`), never plaintext `ENV` |

## 2. Deep References (Load On-Demand Only)
- Complete multi-stage `Dockerfile`, `.dockerignore`, and hardened `compose.yaml`: [references/dockerfile-and-compose.md](./references/dockerfile-and-compose.md)
