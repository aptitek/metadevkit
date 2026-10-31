### `fw:minecraft` — Minecraft 1.21+ Side Separation & Mixin Safety
- **Client/Server Physical Side Separation**: `server/` and `common/` packages must NEVER import `net.minecraft.client.*`, `com.mojang.blaze3d.*`, or client-only entrypoints. `client/` packages must NEVER import `net.minecraft.server.dedicated.*`.
- **Mixin Safety**: `@Overwrite` and `@Redirect` are strictly forbidden; use `@Inject` or MixinExtras `@WrapOperation` / `@ModifyExpressionValue` with `injectors.defaultRequire: 1`.
- **1.21+ Assets & Narrator**: Enforces singular datapack folder names (`loot_table`, `recipe`, `function`) and `Component.translatable(...)` on Screen titles/widgets.
