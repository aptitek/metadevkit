---
name: flet-md3
description: "Build Python Flet UIs with Material Design 3 (ft.Colors.*, ft.Icons.*), 5-level Atomic Design, and page.run_task concurrency."
---

# Flet Material Design 3 & Atomic UI (`fw:flet`)

## 1. Hard API & Architectural Gates (`validate-flet.sh` + `flet.yml`)
| Gate | Forbidden (Deprecated / Anti-Pattern) | Required Modern Idiom |
| :--- | :--- | :--- |
| **Colors & Icons** | `color="#FF0055"`, `bgcolor="pink"`, `ft.colors.*`, `ft.icons.*` | PascalCase enums `ft.Colors.*` & `ft.Icons.*` (`ft.Colors.PRIMARY`, `ft.Colors.SURFACE`) |
| **Custom Controls** | `class MyWidget(ft.UserControl):` (removed in modern Flet) | Subclass layout controls directly (`class MyCard(ft.Container):`) or use pure factory functions |
| **Concurrency** | Blocking calls on UI handlers; global `page.update()` everywhere | `page.run_task(async_fn, *args)` for async I/O, `page.run_thread(sync_fn)` for CPU, targeted `self.update()` |
| **Atomic Hierarchy** | Upward imports (`atoms` importing `molecules`/`organisms`/`views`) | Strict 5-level DAG: `atoms` -> `molecules` -> `organisms` -> `templates` -> `views` |
| **Domain Separation** | Importing `langchain`, `langgraph`, `mcp`, or `texttospeech` in `ui/` | Inject typed callbacks (`Callable[[str], None]`) from service/agent layer |

## 2. Canonical Custom Control & Async Task Pattern
```python
import flet as ft


class StatusChipAtom(ft.Container):
    def __init__(self, label: str) -> None:
        super().__init__(
            padding=8,
            bgcolor=ft.Colors.SECONDARY_CONTAINER,
            content=ft.Text(label, color=ft.Colors.ON_SECONDARY_CONTAINER),
        )
```

## 3. Verification
Run `task lint` (executes `.guardrails/scripts/validate-flet.sh .`) and `task test`.

## 4. Deep References (Load On-Demand Only)
- Full `ui/theme.py` MD3 setup, `page.run_task` streaming, and `pytest-playwright` E2E tests: [references/atomic-and-e2e-patterns.md](./references/atomic-and-e2e-patterns.md)
