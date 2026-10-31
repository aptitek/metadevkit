### `fw:nicegui` — NiceGUI Non-Blocking Async & Headless Testing
- **Quality Gates**: Bans `time.sleep` and synchronous `requests.*` in `src/` (requires `asyncio.sleep`, `httpx.AsyncClient`, `run.io_bound`, or `run.cpu_bound`), enforces Atomic UI hierarchy, and verifies screens with `nicegui.testing.User`.
