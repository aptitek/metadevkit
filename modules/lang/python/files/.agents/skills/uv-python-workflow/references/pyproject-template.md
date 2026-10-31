# Production `pyproject.toml` Template (`uv_build`)

```toml
[project]
name = "my-app"
version = "0.1.0"
description = "Strictly typed Python application managed with uv"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "pydantic>=2.10.0",
    "pydantic-settings>=2.10.0",
]

[project.scripts]
my-app = "my_app.main:run_app"

[build-system]
requires = ["uv_build>=0.11.0,<0.12.0"]
build-backend = "uv_build"

[dependency-groups]
dev = [
    "mypy>=1.15.0",
    "pytest>=8.3.0",
    "pytest-asyncio>=0.25.0",
    "pytest-playwright>=0.7.0",
    "radon>=6.0.1",
    "ruff>=0.11.0",
    "vulture>=2.14",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
addopts = "-ra -q"
```
