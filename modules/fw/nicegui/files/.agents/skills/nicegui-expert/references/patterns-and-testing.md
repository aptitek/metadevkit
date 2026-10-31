# NiceGUI `@ui.refreshable_method` & `nicegui.testing.User` Reference

## 1. Class-Based `@ui.refreshable_method` (MyPy-Safe)
```python
from nicegui import ui


class JobQueuePanel:
    def __init__(self) -> None:
        self.jobs: list[str] = []

    @ui.refreshable_method
    def render_list(self) -> None:
        for job_name in self.jobs:
            ui.label(job_name)

    def add_job(self, name: str) -> None:
        self.jobs.append(name)
        self.render_list.refresh()
```

## 2. Fast In-Memory Testing with `nicegui.testing.User`
Use the `user: User` fixture (runs in-memory without launching a browser) for 90%+ of UI tests; reserve `screen: Screen` for browser-specific JS rendering:

```python
from nicegui import ui
from nicegui.testing import User

pytest_plugins = ["nicegui.testing.user_plugin"]


async def test_job_queue_interaction(user: User) -> None:
    await user.open("/")
    await user.should_see("Dashboard")
    user.find(ui.button).click()
    await user.should_see("Completed")
```
