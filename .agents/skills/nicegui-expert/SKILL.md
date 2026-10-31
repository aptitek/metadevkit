---
name: nicegui-expert
description: "Build reactive NiceGUI Python apps enforcing non-blocking async (run.io_bound), @ui.refreshable, app.storage isolation, and User tests."
---

# NiceGUI Reactive Python Architecture (`fw:nicegui`)

## 1. Hard Event-Loop & State Gates (`validate-nicegui.sh` + `nicegui.yml`)
| Gate | Forbidden Anti-Pattern | Required NiceGUI Idiom |
| :--- | :--- | :--- |
| **Event Loop** | `time.sleep(...)` or sync `requests.get/post(...)` in `src/` | `await asyncio.sleep(...)`, `httpx.AsyncClient`, `await run.io_bound(...)`, `await run.cpu_bound(...)` |
| **`app.storage` in Workers** | Accessing `app.storage.user` *inside* a `run.io_bound` function (raises ContextVar error) | Read primitives from `app.storage.user` *before* calling `await run.io_bound(fn, primitive_arg)` |
| **Reactivity Scope** | Wrapping an entire `@ui.page` in `@ui.refreshable` (resets DOM & focus) | Wrap only the granular dynamic widget/list in `@ui.refreshable` (or `@ui.refreshable_method` on classes) |
| **Entrypoint** | Calling `ui.run(...)` inside `ui/pages/` or component modules | Call `ui.run(storage_secret=...)` exclusively in `main.py` / `app.py` |
| **Atomic UI** | Upward imports (`atoms` -> `molecules`/`organisms`/`pages`) | Unidirectional: `atoms` -> `molecules` -> `organisms` -> `pages` |

## 2. Safe `app.storage` + `run.io_bound` Pattern
```python
from nicegui import app, run, ui


async def handle_job() -> None:
    user_id = str(app.storage.user.get("user_id", "anon"))
    summary = await run.io_bound(compute_report_sync, user_id)
    ui.notify(summary, type="positive")
```

## 3. Verification
Run `task lint` (executes `.guardrails/scripts/validate-nicegui.sh .`) and `task test`.

## 4. Deep References (Load On-Demand Only)
- `@ui.refreshable_method`, multi-tab storage, and fast in-memory `nicegui.testing.User` pytest fixtures: [references/patterns-and-testing.md](./references/patterns-and-testing.md)
