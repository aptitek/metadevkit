# Flet MD3 Theme, Async `page.run_task`, and Playwright E2E Reference

## 1. `src/<pkg>/ui/theme.py`
```python
import flet as ft


def get_app_theme() -> ft.Theme:
    return ft.Theme(
        use_material3=True,
        color_scheme_seed=ft.Colors.PINK_200,
        color_scheme=ft.ColorScheme(
            primary=ft.Colors.PINK_300,
            on_primary=ft.Colors.WHITE,
            secondary=ft.Colors.PURPLE_200,
            tertiary=ft.Colors.AMBER_200,
            surface=ft.Colors.PINK_50,
            on_surface=ft.Colors.GREY_900,
        ),
        visual_density=ft.VisualDensity.COMFORTABLE,
    )
```

## 2. Non-Blocking Async Updates via `page.run_task`
```python
import asyncio
import flet as ft


def mount_counter(page: ft.Page) -> None:
    status = ft.Text("Ready", color=ft.Colors.ON_SURFACE)

    async def run_synthesis() -> None:
        await asyncio.sleep(0.2)
        status.value = "Completed"
        status.update()  # Targeted delta update

    page.add(
        ft.ElevatedButton(
            text="Synthesize",
            icon=ft.Icons.GRAPHIC_EQ,
            on_click=lambda _: page.run_task(run_synthesis),
        ),
        status,
    )
```

## 3. Accessibility & Headless `pytest-playwright` E2E
Enable `page.semantics_enabled = True` in `main(page: ft.Page)` so Playwright can query ARIA semantics deterministically in Chromium.
