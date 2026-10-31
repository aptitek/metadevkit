# Dual-Environment Secret Management & Strict MyPy Configuration

## 1. `src/<pkg>/config.py` (`pydantic-settings` + `/run/secrets/`)
Load secrets from `.env` in development and `/run/secrets/` tmpfs mounts in production Docker containers:

```python
import os
from functools import lru_cache
from pathlib import Path
from pydantic import SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_ENV = os.getenv("ENV", "development")
_SECRETS_DIR = "/run/secrets" if _ENV == "production" and Path("/run/secrets").is_dir() else None


class Settings(BaseSettings):
    env: str = "development"
    gemini_api_key: SecretStr = SecretStr("")

    model_config = SettingsConfigDict(
        env_file=".env" if _ENV != "production" else None,
        env_file_encoding="utf-8",
        secrets_dir=_SECRETS_DIR,
        extra="ignore",
    )

    @model_validator(mode="after")
    def validate_production_secrets(self) -> "Settings":
        if self.env == "production":
            raw = self.gemini_api_key.get_secret_value().strip()
            if not raw or raw.startswith("your_") or raw == "placeholder":
                raise ValueError("Production secret 'gemini_api_key' is missing or invalid.")
        return self


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
```

## 2. `pyproject.toml` Strict MyPy + Pydantic Plugin
```toml
[tool.mypy]
python_version = "3.12"
strict = true
plugins = ["pydantic.mypy"]
warn_unused_ignores = true
show_error_codes = true

[tool.pydantic-mypy]
init_forbid_extra = true
init_typed = true
warn_required_dynamic_aliases = true
```
