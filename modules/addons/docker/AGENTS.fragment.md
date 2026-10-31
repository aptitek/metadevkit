### `addon:docker` — Dockerfile & Docker Compose Hardening
- **Quality Gates**: Bans `:latest` image tags, requires non-root `USER` in Dockerfiles, and enforces `healthcheck` definitions in Compose services.
