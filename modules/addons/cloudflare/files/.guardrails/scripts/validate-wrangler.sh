#!/usr/bin/env bash
# =============================================================================
# polyglot-guardrails — Cloudflare wrangler.toml / wrangler.jsonc Validator
# =============================================================================
set -euo pipefail

WRANGLER_TOML="wrangler.toml"

if [[ ! -f "$WRANGLER_TOML" ]]; then
  echo "[addon:cloudflare] No wrangler.toml present yet (skipped file syntax check)."
  exit 0
fi

if ! grep -E -q '^[[:space:]]*name[[:space:]]*=' "$WRANGLER_TOML"; then
  echo "[addon:cloudflare ERROR] wrangler.toml is missing required 'name' field." >&2
  exit 1
fi

if ! grep -E -q '^[[:space:]]*compatibility_date[[:space:]]*=' "$WRANGLER_TOML"; then
  echo "[addon:cloudflare ERROR] wrangler.toml is missing required 'compatibility_date' field." >&2
  exit 1
fi

if grep -E -i -q '(api_key|secret|password|token)[[:space:]]*=[[:space:]]*"[^"]+"' "$WRANGLER_TOML"; then
  echo "[addon:cloudflare ERROR] Potential plaintext secret detected in wrangler.toml. Use 'wrangler secret put' or '.dev.vars'." >&2
  exit 1
fi

echo "[addon:cloudflare] wrangler.toml validation passed."
