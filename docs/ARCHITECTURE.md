# TCG Framework Architecture

This document describes the major systems, their responsibilities, and the design principles that keep the framework modular and game-agnostic.

---

## Design Philosophy

1. **Separation of concerns** — Data, logic, and UI live in distinct layers.
2. **Single source of truth** — `CardDatabase` owns definitions; `CollectionManager` owns player ownership.
3. **No UI in generators** — `PackGenerator` never touches scenes or nodes.
4. **No logic in UI** — UI scenes request actions through managers and react to signals.
5. **Extend, don't rewrite** — New features plug in via resources, managers, or new UI scenes.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                            │
│  MainMenu  PackOpening  Collection  DeckBuilder  Inspector  │
│       │          │            │           │           │       │
│       └──────────┴────────────┴───────────┴───────────┘       │
│                          │                                    │
│                    GameManager                                │
│              (navigation, overlays, transitions)              │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────────┐
│                      Manager Layer                           │
│                                                              │
│   CollectionManager ◄──── SaveManager (placeholder)        │
│         │                                                    │
│         ▼                                                    │
│   CardDatabase                                               │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────────┐
│                       Logic Layer                            │
│                                                              │
│   PackGenerator  ──queries──►  CardDatabase                  │
│   (pure RefCounted, no UI)                                   │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────────┐
│                        Data Layer                            │
│                                                              │
│   CardData (Resource)                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Manager Reference

### GameManager

**Path:** `autoload/game_manager.gd`

**Responsibilities:**

- Scene navigation with fade transitions
- Global overlays (card inspector, developer panel)
- Input routing (e.g. F1 developer panel toggle)

**Does not:**

- Store card or collection data
- Generate packs

---

### CardDatabase

**Path:** `autoload/card_database.gd`

**Responsibilities:**

- Register and index all card definitions
- Serve cards by ID or rarity
- Act as the catalog source of truth

**Does not:**

- Track player ownership
- Apply variants at runtime (templates are stored; instances are created by `PackGenerator` / `CollectionManager`)

---

### CollectionManager

**Path:** `autoload/collection_manager.gd`

**Responsibilities:**

- Store owned cards (with unique `instance_id`)
- Manage the active deck (10-card limit)
- Emit `collection_changed` and `deck_changed` signals

**Does not:**

- Touch UI nodes
- Generate random cards

**Signals:**

| Signal | When |
|--------|------|
| `collection_changed` | Card added, removed, or collection cleared |
| `deck_changed` | Card added to or removed from deck |

---

### SaveManager

**Path:** `autoload/save_manager.gd`

**Responsibilities (planned):**

- `save_game()` — persist collection and deck
- `load_game()` — restore on startup
- `delete_save()` — wipe save data

**Current state:** Placeholder stubs. Other systems will call these methods when persistence is implemented in Phase 6.

---

### PackGenerator

**Path:** `scripts/systems/pack_generator.gd`

**Responsibilities:**

- Generate packs from weighted rarity and variant tables
- Generate individual cards by rarity
- Accept optional `RandomNumberGenerator` for reproducibility

**Does not:**

- Know about scenes, UI, or `CollectionManager`

---

## UI Reference

### PackOpeningScene

**Path:** `scripts/ui/pack_opening.gd` + `scenes/PackOpening.tscn`

Orchestrates the pack opening presentation:

1. Requests card data from `PackGenerator`
2. Drives `PackScene` animations via signals
3. Spawns `CardScene` instances for fly-out and reveal
4. On Continue, calls `CollectionManager.add_cards()`

### CardScene

**Path:** `scripts/ui/card_scene.gd` + `scenes/Card.tscn`

Owns card visuals: frames, backs, variant overlays, flip animations. Modes: `PACK`, `GALLERY`, `PREVIEW`.

### PackScene

**Path:** `scripts/ui/pack_scene.gd` + `scenes/Pack.tscn`

Owns pack shake, open, and explode animations. Reusable across pack visual profiles.

### CardVisualLibrary

**Path:** `scripts/ui/card_visual_library.gd`

Static placeholder styles for rarity frames, card backs, and reveal timing. Intended to be replaced by assets/shaders later.

---

## Data Reference

### CardData

**Path:** `scripts/data/card_data.gd`

| Field | Type | Description |
|-------|------|-------------|
| `card_id` | `String` | Catalog identifier |
| `card_name` | `String` | Display name |
| `rarity` | `enum` | Common, Rare, Epic, Legendary |
| `variant` | `enum` | Normal, Foil, Negative, Alt Art, Diamond |
| `card_set` | `String` | Set name (e.g. "Core Set") |
| `description` | `String` | Flavor/rules text placeholder |
| `instance_id` | `String` | Assigned by `CollectionManager` for owned copies |

---

## Communication Patterns

### UI → Manager

```gdscript
# Correct: request through manager API
CollectionManager.add_cards(pack_cards)
GameManager.go_to_collection()
```

### UI → Logic

```gdscript
# Correct: generate data, then present
var cards := PackGenerator.generate_pack(CardDatabase)
```

### Manager → UI

```gdscript
# Correct: UI listens to signals
CollectionManager.collection_changed.connect(_refresh_collection)
```

### Anti-patterns

```gdscript
# Wrong: UI mutates internal manager state
CollectionManager._collection.append(card)

# Wrong: PackGenerator creates nodes
var card_scene = CardScene.new()

# Wrong: UI scene directly changes another UI scene
get_node("/root/Collection").show()
```

---

## Folder Structure

```
autoload/           # Singleton managers
scripts/data/       # Resources and data types
scripts/systems/    # Pure logic (no UI)
scripts/ui/         # Scene controllers and visual helpers
scenes/             # Godot scene files
resources/          # Future .tres definitions
assets/             # Art, audio, placeholders
docs/               # Documentation
```

---

## Future Integration Points

| System | Integration |
|--------|-------------|
| **Blackjack / Poker** | Import `CollectionManager.get_deck()`; no framework rule logic |
| **Shop** | Purchase → `PackGenerator` → `PackOpening` → `CollectionManager` |
| **Save** | `CollectionManager` serializes to `SaveManager` |
| **Multiplayer** | Sync seeds + instance IDs; validate against `CardDatabase` |

---

*See also: [ROADMAP.md](ROADMAP.md) · [CONTRIBUTING.md](../CONTRIBUTING.md)*
