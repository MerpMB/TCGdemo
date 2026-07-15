# Visual Assets

All card visuals are loaded through `CardVisualLibrary` — never reference these paths from UI scripts.

See [docs/ASSET_PIPELINE.md](../docs/ASSET_PIPELINE.md) for naming rules and workflow.

## Layout

```
assets/
    cards/          Card artwork (by rarity or set folder)
    frames/         Rarity frame PNGs
    backs/          Card back PNGs
    variants/       Optional variant overlay textures
    glows/          Optional rarity glow textures
    shaders/        Procedural variant FX (fallback when PNGs absent)
```

Drop PNGs into the appropriate folder and assign or rely on `{card_id}.png` convention in `CardData`.
