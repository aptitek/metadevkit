---
name: minecraft-networking
description: "Implement Minecraft 1.21+ CustomPacketPayload, StreamCodec, RegistryFriendlyByteBuf, and thread-safe C2S/S2C networking."
---

# Minecraft Modern Networking 1.21+ (`minecraft-networking`)

## 1. Hard Networking & Codec Gates (1.20.5+ / 1.21.4+)
| Gate | Requirement |
| :--- | :--- |
| **Payload Contract** | Implement `CustomPacketPayload` (`record` in Java, `data class` in Kotlin) with a static `CustomPacketPayload.Type<T>` |
| **Buffer Type** | Use `StreamCodec<RegistryFriendlyByteBuf, T>` (required for `ItemStack` and 1.21+ Data Components) |
| **ItemStack Safety** | Always use `ItemStack.OPTIONAL_PACKET_CODEC` instead of `ItemStack.PACKET_CODEC` when stacks may be empty |
| **DoS Prevention** | Bound strings & collections (`ByteBufCodecs.stringUtf8(128)`, `ByteBufCodecs.collection(ArrayList::new, codec, 64)`) |
| **Thread Safety** | Netty decodes off-thread; hop to the game loop via `context.server().execute { ... }` or `context.client().execute { ... }` before touching world/screen state |
| **C2S Authority** | Validate permission level, reach distance (`<= 6.0` blocks), cooldowns, and `Double.isFinite()` on all C2S packets |

## 2. Canonical `CustomPacketPayload` + `StreamCodec` (Kotlin)
```kotlin
data class RuleSyncPayload(
    val ruleId: String,
    val iconStack: ItemStack,
    val severityLevel: Int,
) : CustomPacketPayload {
    override fun type(): CustomPacketPayload.Type<RuleSyncPayload> = TYPE

    companion object {
        val ID: ResourceLocation = ResourceLocation.fromNamespaceAndPath("stellar_law", "rule_sync")
        val TYPE: CustomPacketPayload.Type<RuleSyncPayload> = CustomPacketPayload.Type(ID)
        val CODEC: StreamCodec<RegistryFriendlyByteBuf, RuleSyncPayload> = StreamCodec.composite(
            ByteBufCodecs.stringUtf8(128), RuleSyncPayload::ruleId,
            ItemStack.OPTIONAL_PACKET_CODEC, RuleSyncPayload::iconStack,
            ByteBufCodecs.VAR_INT, RuleSyncPayload::severityLevel,
            ::RuleSyncPayload,
        )
    }
}
```
