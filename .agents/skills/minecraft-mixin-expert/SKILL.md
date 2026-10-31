---
name: minecraft-mixin-expert
description: >-
  Expert Spongeian Mixin and MixinExtras engineering skill for Minecraft modding.
  Covers injection point selection (HEAD, RETURN, INVOKE, TAIL), MixinExtras
  (@WrapOperation, @ModifyExpressionValue, @Local, @Share), conflict avoidance
  (banning @Redirect and @Overwrite), remap = false, and Kotlin Mixin interop.
---

# Minecraft Mixin & MixinExtras Engineering (`minecraft-mixin-expert`)

## 1. Zero-Conflict Hierarchy (Enforced by `.guardrails/ast/minecraft.yml`)

| Injector | Conflict Risk | Policy |
| :--- | :--- | :--- |
| `@Inject` (`HEAD`, `RETURN`, `TAIL`) | **Minimal** | Allowed & Recommended |
| `@ModifyVariable` | **Low** | Allowed |
| `@ModifyExpressionValue` *(MixinExtras)* | **Low** | Recommended over `@Redirect` |
| `@WrapOperation` *(MixinExtras)* | **Low** | Recommended over `@Redirect` |
| `@WrapWithCondition` *(MixinExtras)* | **Low** | Allowed |
| `@Redirect` | **Extreme** | **FORBIDDEN** by AST gate |
| `@Overwrite` | **Fatal** | **FORBIDDEN** by AST gate |

## 2. MixinExtras Patterns
1. **`@WrapOperation` (Replaces `@Redirect`)**:
   ```java
   @WrapOperation(
       method = "render",
       at = @At(value = "INVOKE", target = "Lnet/minecraft/client/gui/GuiGraphics;drawString(...)I")
   )
   private int wrapDrawString(
       GuiGraphics instance, Font font, Component text, int x, int y, int color, Operation<Integer> original
   ) {
       return original.call(instance, font, modifyText(text), x, y, color);
   }
   ```
2. **`@ModifyExpressionValue` (Intercepts Return Values)**:
   ```java
   @ModifyExpressionValue(
       method = "tickMovement",
       at = @At(value = "INVOKE", target = "Lnet/minecraft/world/entity/player/Player;isSprinting()Z")
   )
   private boolean forceSprintCondition(boolean original) {
       return original || shouldAutoSprint();
   }
   ```
3. **`@Local` (Captures Locals Safely)**:
   Use `@Local` instead of fragile `LocalCapture.CAPTURE_FAILHARD`.

## 3. Mandatory Mixin Hygiene
- **Namespace with `@Unique`**: Prefix all helper fields and methods in Mixin classes with `@Unique` and `<modid>$` (e.g., `@Unique private boolean stellar$isActive;`).
- **`remap = false` on Non-Minecraft Targets**: Always set `remap = false` when targeting JVM or third-party library classes (`java.*`, `org.joml.*`, `io.netty.*`).
- **`<modid>.mixins.json`**: Must declare `"required": true`, non-empty `"package"`, and `"injectors": { "defaultRequire": 1 }`.
