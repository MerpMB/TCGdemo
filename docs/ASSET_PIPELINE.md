# Asset Pipeline

Production workflow for all card visual assets. **Every load path goes through `CardVisualLibrary`** — UI scripts and `CardScene` never contain `res://assets/...` strings.

---

## Directory Structure

```
assets/
    cards/
        common/         Core Set common-rarity artwork
        rare/
        epic/
        legendary/
        event/            Event Set artwork
        developer/        Developer Set artwork

    frames/
        common.png
        rare.png
        epic.png
        legendary.png

    backs/
        default.png
        <name>.png        Optional named backs (event, developer, …)

    variants/
        foil/             Optional PNG overlays (overlay.png)
        gold/             Reserved for future Gold variant
        diamond/
        negative/

    glows/
        common/           Optional rarity glow textures (glow.png)
        rare/
        epic/
        legendary/

    shaders/              Procedural variant FX (used when PNG overlays absent)
```

Empty folders are tracked via `.gitkeep`. Drop PNGs in place — no code changes required.

---

## Naming Convention

| Rule | Example |
|------|---------|
| Lowercase only | `common_001.png` |
| Underscores, no spaces | `rare_fire_mage_001.png` |
| Match `card_id` when using convention lookup | `common_005.tres` → `common/common_005.png` |
| Frame keys match rarity or `CardData.frame` | `frames/rare.png` |
| Card backs match `CardData.card_back` | `backs/default.png` |
| Variant overlay default filename | `variants/foil/overlay.png` |
| Glow default filename | `glows/rare/glow.png` |

Legacy artwork filenames (e.g. `01-rookie-fire-mage.png`) remain valid when assigned explicitly in `CardData.tres`. New cards should prefer `{card_id}.png`.

---

## Asset Responsibilities

| Asset type | Location | Loaded by | Fallback |
|------------|----------|-----------|----------|
| **Artwork** | `assets/cards/<folder>/` | `resolve_artwork()` | Rarity color `CardBody` |
| **Frames** | `assets/frames/<key>.png` | `get_frame_texture()` | `StyleBoxFlat` border |
| **Card backs** | `assets/backs/<name>.png` | `get_card_back_texture()` | `default.png` → StyleBox |
| **Variant overlays** | `assets/variants/<variant>/` | `get_variant_overlay_texture()` | Procedural shaders |
| **Glow effects** | `assets/glows/<rarity>/` | `get_glow_texture_for_rarity()` | `ColorRect` alpha |
| **Variant shaders** | `assets/shaders/` | `create_*_material()` | None (warn once) |

### Artwork folder selection

1. `Event Set` → `cards/event/`
2. `Developer Set` → `cards/developer/`
3. Otherwise → rarity folder (`common`, `rare`, `epic`, `legendary`)

---

## Loading Flow

```
CardData (.tres)
    ↓
CardRenderer.apply()
    ↓
CardVisualLibrary
    ├── resolve_artwork(card)           explicit artwork field, then <card_id>.png
    ├── get_frame_texture(frame_key)
    ├── get_card_back_texture(card_back)
    ├── get_variant_overlay_texture()   optional PNG (future)
    └── create_*_material()             shader fallback for variants
    ↓
CardScene nodes (textures / materials applied)
```

On startup, `CardDatabase` registers each card and calls `CardVisualLibrary.validate_card_assets()` (non-fatal).

---

## Adding a New Card (No Code)

### Option A — Convention path (recommended)

1. Drop `assets/cards/<folder>/<card_id>.png`
2. Create `resources/cards/.../<card_id>.tres` with matching `card_id`
3. Done — artwork resolves automatically at render time

### Option B — Explicit assignment

1. Drop PNG anywhere under `assets/cards/`
2. Create `CardData.tres` and assign the `artwork` texture in the inspector
3. Done

Frames, backs, and pack eligibility are configured on the same `CardData` resource. Pack inclusion is controlled by `PackConfig` filters — not by scripts.

---

## Missing Asset Behavior

| Situation | Behavior |
|-----------|----------|
| Missing frame PNG | Warn once → procedural `StyleBoxFlat` frame |
| Missing named back | Warn once → `default.png` → StyleBox |
| Missing artwork | Silent → rarity color card body (placeholder cards) |
| Missing variant PNG | Silent → procedural shader FX |
| Missing glow PNG | Silent → `ColorRect` rarity glow |

The game never crashes on missing visuals.

---

## CardData Audit (Current)

| Metric | Count |
|--------|-------|
| Total cards | 44 |
| With explicit artwork | 13 |
| Placeholder (null artwork) | 31 |

Placeholder cards are valid — they render with rarity-colored bodies until artwork is added via convention path or `.tres` assignment.

---

## Future Expansion

- **Gold variant folder** (`assets/variants/gold/`) is reserved; no `CardData.Variant.GOLD` enum yet.
- **PNG variant overlays** can replace shaders by dropping `overlay.png` — no renderer rewrite required.
- **PNG glow textures** can enhance reveal FX when added under `assets/glows/`.
- Hundreds/thousands of cards scale by adding `.tres` + PNG files only.

---

*See also: [DEVELOPMENT.md](DEVELOPMENT.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [assets/README.md](../assets/README.md)*
