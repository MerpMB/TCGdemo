# TCG Framework Architecture

This document describes the current systems, their responsibilities, and the design principles that keep the framework modular and game-agnostic.

---

## Design Philosophy

1. **Separation of concerns** — Data, logic, and UI live in distinct layers.
2. **Single source of truth** — `CardDatabase` owns definitions; `CollectionManager` owns player ownership; `PackDatabase` owns pack definitions.
3. **No UI in generators** — `PackGenerator` never touches scenes or nodes.
4. **No logic in UI** — UI scenes request actions through managers and react to signals.
5. **Orchestration over monoliths** — `CardScene` and `PackOpening` delegate to focused helper modules.
6. **Extend, don't rewrite** — New features plug in via resources, managers, or new UI scenes.

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                            UI Layer                                  │
│  MainMenu  PackOpening  Collection  CardViewer  DeckBuilder  ...     │
│       │          │            │          │                           │
│       └──────────┴────────────┴──────────┴───────────────────────────┘
│                          │                                           │
│                    GameManager                                       │
│         (navigation, CardViewer overlay, developer panel)            │
└──────────────────────────┬───────────────────────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────────────────┐
│                         Manager Layer                                  │
│                                                                        │
│   CollectionManager ◄──── SaveManager (placeholder)                  │
│         │                                                              │
│         ├── CardDatabase          PackDatabase                         │
└─────────┴──────────────────────────┬───────────────────────────────────┘
                                     │
┌────────────────────────────────────┴───────────────────────────────────┐
│                          Logic Layer                                 │
│                                                                      │
│   PackGenerator  ──queries pool via──►  CardDatabase                 │
│   (pure RefCounted, no UI)                                           │
└──────────────────────────┬───────────────────────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────────────────┐
│                           Data Layer                                 │
│                                                                      │
│   CardData (Resource)          PackConfig (Resource)                 │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Primary Game Loop

```
Main Menu
    ↓
Open Pack
    ↓
Reveal 7 Cards
    ↓
Cards Added to Collection
    ↓
Collection Gallery
    ↓
Card Viewer (tap a card)
    ↓
Repeat
```

The main menu is mobile-first portrait (720×1280). `GameManager` selects the active `PackConfig` (default: `starter_pack`) before navigating to pack opening.

---

## CardScene Architecture

`CardScene` is an orchestrator only. Rendering, animation, and interaction live in dedicated `RefCounted` helpers — no new autoloads.

```
CardScene (orchestrator)
    ├── CardRenderer        — applies CardData visuals to node refs
    ├── CardAnimation       — arrival, reveal, hover/click, variant idle FX
    ├── CardInteraction     — gallery tap / hover input
    ├── CardLayerGuard      — debug-only protected-layer drift detection
    └── CardVisualLibrary   — single entry point for visual asset loading
```

### Transform ownership (layer-leak rules)

| Node | Allowed transforms |
|------|-------------------|
| **Card root** | `position`, `global_position`, `rotation`, `scale`, `modulate`, `z_index` |
| **FlipPivot** | `scale.x` only (horizontal flip) |
| **Protected render layers** | None — must stay at cached rest transforms |
| **FX nodes** (FoilShine, RarityGlow, LegendarySpark) | Opacity and sweep offsets only |

Reveal lift animates the **Card root** `position.y`, not `FlipPivot.position`, so `clip_contents` on the card does not clip artwork during reveal.

### Display modes

| Mode | Use | Face | Interaction |
|------|-----|------|-------------|
| `PACK` | Pack opening grid | Face-down until revealed | Flip button / tap-to-reveal |
| `GALLERY` | Collection grid | Face-up | Tap opens CardViewer; hover on desktop |
| `PREVIEW` | CardViewer overlay | Face-up | None (viewer handles close) |

---

## PackOpening Architecture

```
PackOpening (orchestrator)
    ├── PackLayout        — responsive grid math, slot positioning
    ├── PackAnimation     — pack shake/open sequence, legendary screen flash
    └── CardScene         — spawned per card for fly-out and reveal
```

### Pack opening flow

1. `GameManager.get_selected_pack()` returns the active `PackConfig`.
2. `PackGenerator.generate_pack(CardDatabase, pack_config)` builds card data.
3. `PackScene` plays shake → open → explode.
4. `CardScene` instances fly from pack burst origin into a responsive grid.
5. Player reveals cards one-by-one (or skips).
6. On completion, `CollectionManager.add_cards()` stores each copy individually.
7. Continue returns to main menu.

---

## Collection Architecture

```
Collection (collection_view.gd)
    ├── CollectionManager   — source of truth for owned copies
    ├── duplicate stacking  — view-only presentation
    └── CardViewer          — full-screen card appreciation
```

### Storage vs presentation

- **Storage:** `CollectionManager` stores every owned copy as a separate `CardData` instance with a unique `instance_id`.
- **Gallery:** `collection_view.gd` stacks exact duplicates (`card_id` + `variant`) into one grid cell.
- **Badge:** `OwnedCountBadge` shows `×N` for stacked copies (gallery mode only).
- **Variants:** Different variants (Foil, Diamond, etc.) remain separate gallery entries.

Stacking is presentation only — it does not change collection data.

---

## Card Rendering

### Front face (bottom → top)

```
ArtTexture          — full-bleed artwork (CardBody hidden when art exists)
    ↓
FrameTexture        — PNG frame from CardVisualLibrary (or FramePanel StyleBox fallback)
    ↓
VariantOverlay      — Foil shine, Negative, Alt Art, Diamond overlays
    ↓
LegendarySpark      — legendary reveal FX
    ↓
OwnedCountBadge     — gallery duplicate count (gallery mode only)
    ↓
Interaction         — FlipButton (pack mode) / hover+tap (gallery mode)
```

### Back face

```
BackTexture         — PNG from assets/backs/<name>.png
    ↓
BackPanel           — StyleBox fallback when texture is missing
```

`CardRenderer` resolves all textures through `CardVisualLibrary`. It contains no hardcoded asset paths.

---

## Visual Asset Pipeline

`CardVisualLibrary` is the **single entry point** for loading card visual assets. `CardScene` and `CardRenderer` never contain asset paths.

```
assets/
    cards/          — card artwork PNGs (referenced by CardData.tres)
    frames/         — rarity/frame PNGs (common, rare, epic, legendary)
    backs/          — card back PNGs (default.png, etc.)
    variants/       — future variant overlay textures
    glows/          — future rarity glow textures
    placeholder/    — reserved for dev placeholders
```

### Loading behavior

| Asset | Path pattern | Fallback |
|-------|-------------|----------|
| Frame | `assets/frames/<key>.png` | `StyleBoxFlat` procedural border via `get_frame_overlay_style()` |
| Card back | `assets/backs/<name>.png` | `default.png`, then `StyleBoxFlat` via `get_card_back_style()` |
| Variant | `assets/variants/<name>.png` | Procedural `ColorRect` overlays in `CardRenderer` |
| Glow | `assets/glows/<rarity>.png` | `RarityGlow` ColorRect alpha animation |

Textures are cached per session. Missing assets warn once and fall back gracefully — cards always render.

---

## Pack System

```
PackConfig (.tres)
    ↓
CardDatabase.get_cards_for_pack(pack_config)
    ↓
Filtered candidate pool
    ↓
PackGenerator (weighted rarity + variant rolls)
    ↓
Array[CardData] pack contents
```

### PackConfig fields

| Field | Role |
|-------|------|
| `pack_id` / `display_name` | Identity |
| `cards_per_pack` | Slot count (default 7) |
| `rarity_weights` | Weighted rarity table (unchanged algorithm) |
| `variant_weights` | Weighted variant table |
| `allowed_sets` | If non-empty, only cards in these sets are eligible |
| `allowed_tags` | If non-empty, card must have at least one tag |
| `excluded_tags` | Cards with any of these tags are never eligible |
| `pack_scene` / colors | Pack opening presentation |

`PackGenerator` never inspects sets or tags directly — it always requests the filtered pool from `CardDatabase`.

### Pack types (current)

| Pack | Set filter | Notes |
|------|-----------|-------|
| `starter_pack` | Core Set | Default main-menu pack |
| `premium_pack` | Core Set | Higher rarity weights |
| `event_pack` | Event Set | Event-tagged cards |
| `developer_pack` | Developer Set | Debug / dev cards |

---

## Manager Reference

### GameManager

**Path:** `autoload/game_manager.gd`

- Scene navigation with fade transitions
- Global `CardViewer` overlay (`show_card_viewer()`)
- Developer panel toggle (F1)
- Selected pack ID for pack opening

### CardDatabase

**Path:** `autoload/card_database.gd`

- Recursively loads all `CardData` `.tres` files from `resources/cards/`
- Indexes by ID, rarity, set, and tag
- `get_cards_for_pack(pack_config)` owns all pack pool filtering

### PackDatabase

**Path:** `autoload/pack_database.gd`

- Loads all `PackConfig` `.tres` files from `resources/packs/`
- Serves packs by `pack_id`

### CollectionManager

**Path:** `autoload/collection_manager.gd`

- Stores owned cards (each copy gets a unique `instance_id`)
- Manages active deck (10-card limit)
- Emits `collection_changed` and `deck_changed`

### SaveManager

**Path:** `autoload/save_manager.gd`

- Placeholder stubs for future persistence (`save_game`, `load_game`, `delete_save`)

---

## UI Module Reference

| Script | Role |
|--------|------|
| `card_scene.gd` | Card orchestration, mode setup, signal wiring |
| `card_renderer.gd` | Apply art, frame, back, variant overlays |
| `card_animation.gd` | Arrival, reveal, hover/click, foil sweep |
| `card_interaction.gd` | Gallery input handling |
| `card_layer_guard.gd` | Debug protected-layer assertions |
| `card_visual_library.gd` | Visual asset loading and fallbacks |
| `card_viewer.gd` | Full-screen card viewer overlay |
| `collection_view.gd` | Gallery grid with duplicate stacking |
| `pack_opening.gd` | Pack opening flow orchestration |
| `pack_layout.gd` | Responsive card grid math |
| `pack_animation.gd` | Pack sequence and legendary flash |
| `pack_scene.gd` | Pack shake/open/explode visuals |
| `main_menu.gd` | Open Pack, Collection, Exit |
| `deck_builder.gd` | Deck assembly (framework feature, not in main loop) |
| `developer_panel.gd` | F1 testing tools |

---

## Data Reference

### CardData

**Path:** `scripts/data/card_data.gd` — loaded from `resources/cards/**/*.tres`

| Field | Type | Description |
|-------|------|-------------|
| `card_id` | `String` | Unique catalog identifier |
| `display_name` | `String` | Display name |
| `card_set` | `String` | Set name (e.g. "Core Set") |
| `rarity` | `enum` | Common, Rare, Epic, Legendary |
| `variant` | `enum` | Normal, Foil, Negative, Alt Art, Diamond |
| `frame` | `String` | Optional frame key override |
| `card_back` | `String` | Back texture key (default: `"default"`) |
| `artwork` | `Texture2D` | Full-art texture |
| `tags` | `PackedStringArray` | Used by pack pool filters |
| `instance_id` | `String` | Assigned by `CollectionManager` for owned copies |

### PackConfig

**Path:** `scripts/data/pack_config.gd` — loaded from `resources/packs/*.tres`

See [Pack System](#pack-system) above.

---

## Communication Patterns

### UI → Manager

```gdscript
CollectionManager.add_cards(pack_cards)
GameManager.show_card_viewer(card_data)
GameManager.go_to_collection()
```

### UI → Logic

```gdscript
var pack_config := GameManager.get_selected_pack()
var cards := PackGenerator.generate_pack(CardDatabase, pack_config)
```

### Manager → UI

```gdscript
CollectionManager.collection_changed.connect(_refresh_collection)
```

### Anti-patterns

```gdscript
# Wrong: UI mutates internal manager state
CollectionManager._collection.append(card)

# Wrong: PackGenerator inspects sets/tags directly
# Use CardDatabase.get_cards_for_pack() instead

# Wrong: Hardcoded asset paths in CardScene
load("res://assets/frames/rare.png")  # Use CardVisualLibrary
```

---

## Folder Structure

```
autoload/              # Singleton managers
scripts/data/          # CardData, PackConfig resources
scripts/systems/       # PackGenerator (pure logic)
scripts/ui/            # Scene controllers and UI helpers
scenes/                # Godot scene files
resources/cards/       # CardData .tres definitions (auto-scanned)
resources/packs/       # PackConfig .tres definitions (auto-scanned)
assets/                # Art and visual media
docs/                  # Documentation
```

---

## Future Integration Points

| System | Integration |
|--------|-------------|
| **Blackjack / Poker** | Import `CollectionManager.get_deck()`; no framework rule logic |
| **Shop** | Purchase → `PackConfig` → `PackOpening` → `CollectionManager` |
| **Save** | `CollectionManager` serializes to `SaveManager` |
| **Multiplayer** | Sync seeds + instance IDs; validate against `CardDatabase` |

---

*See also: [ROADMAP.md](ROADMAP.md) · [DEVELOPMENT.md](DEVELOPMENT.md) · [CONTRIBUTING.md](../CONTRIBUTING.md)*
