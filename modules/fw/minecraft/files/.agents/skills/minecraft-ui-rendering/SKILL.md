---
name: minecraft-ui-rendering
description: >-
  Modern Minecraft 1.21+ Screen and UI rendering skill. Covers GuiGraphics /
  DrawContext operations, custom Widgets (AbstractWidget, Button, EditBox),
  PoseStack matrix transformations, scissor clipping, and zero-allocation render loops.
---

# Minecraft UI & Screen Rendering 1.21+ (`minecraft-ui-rendering`)

## 1. Rendering Rules (`GuiGraphics` / `DrawContext`)
- **Client-Side Only**: All `Screen`, `AbstractWidget`, `GuiGraphics`, and `RenderSystem` code must live inside `client/` packages (or the `client` sourceSet) and must never be referenced from `common/` or `server/`.
- **Balanced Matrix & Scissor Stacks**:
  - Every `graphics.pose().pushPose()` MUST be paired with `pose.popPose()` in a `try / finally` block.
  - Every `graphics.enableScissor(...)` MUST be paired with `graphics.disableScissor()` in a `try / finally` block.
- **Zero-Allocation `render()` Loop**:
  - `render(graphics, mouseX, mouseY, delta)` runs 60–240+ times per second.
  - Never allocate `Component.literal(...)`, string concatenations, or collection pipelines inside `render()`. Cache `Component` instances in `init()` or state-change handlers.
- **Localization**:
  - Use `Component.translatable("<modid>.screen.title")` backed by `assets/<modid>/lang/en_us.json`.
