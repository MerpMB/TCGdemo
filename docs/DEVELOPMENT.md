# Development Guide

How to work on TCG Framework locally. For architecture details see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Requirements

- [Godot 4.4+](https://godotengine.org/download) — project targets **Godot 4.6**
- Git

---

## Setup

```bash
git clone https://github.com/MerpMB/TCGdemo.git
cd TCGdemo
```

1. Open `project.godot` in Godot 4.6.
2. Let Godot import assets on first focus (or run a headless import).
3. Press **F5** to run.
4. Press **F1** to open the Developer Panel.

The project runs in portrait mode (720×1280) with canvas-item stretch and expand aspect.

---

## Project Layout

```
autoload/           GameManager, CardDatabase, PackDatabase, CollectionManager, SaveManager
scripts/data/       CardData, PackConfig
scripts/systems/    PackGenerator
scripts/ui/         Scene controllers and CardScene/PackOpening helpers
scenes/             .tscn files
resources/cards/    CardData .tres (auto-scanned)
resources/packs/    PackConfig .tres (auto-scanned)
assets/             Visual media (frames, backs, card art)
docs/               Documentation
```

---

## Adding Content (No Code)

Full pipeline reference: [ASSET_PIPELINE.md](ASSET_PIPELINE.md)

### New card (convention path — recommended)

1. Drop `assets/cards/<folder>/<card_id>.png` (folder = rarity or `event` / `developer` for those sets).
2. Create `resources/cards/<set>/<card_id>.tres` with matching `card_id`, `rarity`, `card_set`, `tags`.
3. Launch — artwork resolves via `CardVisualLibrary.resolve_artwork()`; no `artwork` field required.

### New card (explicit artwork)

1. Drop artwork PNG under `assets/cards/`.
2. Create `CardData.tres` and assign the `artwork` texture in the inspector.
3. Launch — `CardDatabase` registers it automatically.

### New pack

1. Create `resources/packs/my_pack.tres` as a `PackConfig` resource.
2. Set `pack_id`, weights, and pool filters (`allowed_sets`, `allowed_tags`, `excluded_tags`).
3. Launch — `PackDatabase` registers it automatically.
4. Select it via `GameManager.set_selected_pack("my_pack")` or the Developer Panel.

### New frame, card back, variant overlay, or glow

1. Drop PNG into the matching folder (see [ASSET_PIPELINE.md](ASSET_PIPELINE.md)).
2. No script changes — `CardVisualLibrary` loads on demand with caching and fallbacks.

---

## Key Systems Quick Reference

### CardScene modules

| Module | File | Responsibility |
|--------|------|----------------|
| Orchestrator | `card_scene.gd` | Mode setup, signal wiring |
| Renderer | `card_renderer.gd` | Art, frame, back, variants |
| Animation | `card_animation.gd` | Motion and reveal tweens |
| Interaction | `card_interaction.gd` | Gallery input |
| Layer guard | `card_layer_guard.gd` | Debug drift detection |
| Visual library | `card_visual_library.gd` | Asset loading |

### Pack opening modules

| Module | File | Responsibility |
|--------|------|----------------|
| Orchestrator | `pack_opening.gd` | Flow state machine |
| Layout | `pack_layout.gd` | Grid math |
| Animation | `pack_animation.gd` | Pack sequence FX |

### Pack generation pipeline

```
PackConfig → CardDatabase.get_cards_for_pack() → PackGenerator → Array[CardData]
```

---

## Coding Rules

- **Data** (`scripts/data/`) — resources only, no scene references.
- **Systems** (`scripts/systems/`) — pure logic, no UI nodes.
- **UI** (`scripts/ui/`) — presentation; call managers and generators.
- **Autoloads** — global services only.
- **Asset paths** — only in `CardVisualLibrary`, never in `CardScene` or `CardRenderer`.
- **Pack pool filtering** — only in `CardDatabase.get_cards_for_pack()`, never in `PackGenerator`.

---

## Testing Flows

| Flow | Steps |
|------|-------|
| Pack open | Main Menu → Open Pack → reveal/skip → Continue |
| Collection | Main Menu → Collection → verify grid and `×N` badges |
| Card Viewer | Collection → tap card → verify dimmer and close |
| Developer | F1 → grant cards, generate packs, clear collection |
| Pack isolation | Open developer/event packs; verify pool matches `PackConfig` filters |

---

## Debug Tools

- **F1** — Developer Panel
- **CardLayerGuard** — `push_error` in debug builds if protected layers drift during animation
- Console — `CardDatabase` and `PackDatabase` print load summaries on startup

---

## Common Pitfalls

| Mistake | Correct approach |
|---------|-------------------|
| Animating `FlipPivot.position` for reveal lift | Animate Card root `position.y` |
| Hardcoding frame paths in UI | Use `CardVisualLibrary.get_frame_texture()` |
| Filtering pack pools in `PackGenerator` | Use `CardDatabase.get_cards_for_pack()` |
| Merging duplicates in `CollectionManager` | Stack only in `collection_view.gd` |
| Adding autoloads for UI helpers | Use `RefCounted` modules bound by orchestrators |

---

*See also: [ARCHITECTURE.md](ARCHITECTURE.md) · [ASSET_PIPELINE.md](ASSET_PIPELINE.md) · [TODO.md](../TODO.md) · [CONTRIBUTING.md](../CONTRIBUTING.md)*
