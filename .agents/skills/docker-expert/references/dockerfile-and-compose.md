# Multi-Stage `Dockerfile` & Hardened `compose.yaml` Reference

## 1. `Dockerfile`
```dockerfile
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

FROM ghcr.io/astral-sh/uv:python3.12-alpine
RUN apk add --no-cache ffmpeg && addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app /app
ENV PATH="/app/.venv/bin:$PATH" PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
USER appuser
EXPOSE 8550
CMD ["python", "-m", "my_app.main"]
```

## 2. `compose.yaml`
```yaml
services:
  app:
    build: .
    ports:
      - "8550:8550"
    environment:
      - ENV=production
    secrets:
      - gemini_api_key
      - google_tts_api_key
    security_opt:
      - no-new-privileges:true
    restart: unless-stopped

secrets:
  gemini_api_key:
    file: ./secrets/gemini_api_key.txt
  google_tts_api_key:
    file: ./secrets/google_tts_api_key.txt
```
