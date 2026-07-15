# TCG Framework

**A modular Trading Card Game framework built with Godot 4.**

TCG Framework is a standalone, game-agnostic card engine — not a finished game. It provides reusable systems for card catalogs, pack opening, collection management, and deck building, designed so multiple games (Blackjack, Poker, future card games) can import player decks without rewriting core infrastructure.

## Project Goals

- **Modular architecture** — Data, logic, and UI are strictly separated
- **Data-driven card system** — `CardData` resources as the single card model
- **Reusable pack opening** — Presentation layer independent of generation logic
- **Collection management** — Runtime ownership with signal-driven UI updates
- **Deck building** — Framework-level deck assembly for downstream games
- **Multi-game integration** — Built for embedding, not coupling to one ruleset

## Current Features

- ✅ **Mobile-first portrait UI** — 720×1280 with responsive stretch
- ✅ **Pack Opening** — Full presentation flow: pack animations, card fly-out, tap-to-reveal, skip, legendary flash
- ✅ **Full-art card renderer** — Artwork fills the card; frame and variant FX as overlays
- ✅ **Frame & card back assets** — PNG pipeline via `CardVisualLibrary` with procedural fallbacks
- ✅ **Collection Gallery** — Responsive grid with duplicate stacking and `×N` owned badges
- ✅ **Card Viewer** — Full-screen card appreciation (art-only, tap-outside close)
- ✅ **Pack isolation** — `PackConfig` filters pools by set and tags; rarity weights unchanged
- ✅ **Modular CardScene** — Split into `CardRenderer`, `CardAnimation`, `CardInteraction`, `CardLayerGuard`
- ✅ **Content pipeline** — Add cards and packs via `.tres` resources; no script edits required
- ✅ **Developer Panel** — F1 testing tools (give cards, clear collection, generate packs)
- ✅ **Deck Builder** — Split-view collection → deck with 10-card limit (framework feature)
- ✅ **Runtime Collection Manager** — In-memory collection and deck with change signals

## Game Loop

```
Main Menu → Open Pack → Reveal 7 Cards → Cards Added to Collection
    → Collection Gallery → Card Viewer → Repeat
```

## Architecture Overview

| System | Role |
|--------|------|
| **CardDatabase** | Catalog of all card definitions — auto-loads `resources/cards/` |
| **PackDatabase** | Registry of `PackConfig` resources from `resources/packs/` |
| **PackGenerator** | Weighted pack generation from filtered pools — pure logic, no UI |
| **CollectionManager** | Player-owned cards (individual copies) and active deck |
| **GameManager** | Scene navigation, CardViewer overlay, developer panel |
| **CardVisualLibrary** | Single entry point for frame, back, and variant visual assets |
| **SaveManager** | Persistence API placeholder for future disk saves |

```
CardDatabase  ◄──  PackGenerator  ◄──  PackConfig
      ▲                                    ▲
      │                              PackDatabase
CollectionManager  ◄──  UI Scenes
      ▲
      │
 SaveManager (placeholder)
```

### CardScene modules

```
CardScene
    ├── CardRenderer
    ├── CardAnimation
    ├── CardInteraction
    ├── CardLayerGuard
    └── CardVisualLibrary
```

### PackOpening modules

```
PackOpening
    ├── PackLayout
    ├── PackAnimation
    └── CardScene
```

For full details, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Project Structure

```
TCGdemo/
├── autoload/                  # Singleton managers
│   ├── card_database.gd
│   ├── pack_database.gd
│   ├── collection_manager.gd
│   ├── game_manager.gd
│   └── save_manager.gd
├── assets/
│   ├── cards/                 # Card artwork PNGs
│   ├── frames/                # Rarity frame PNGs
│   ├── backs/                 # Card back PNGs
│   ├── variants/              # Future variant overlay textures
│   ├── glows/                 # Future glow textures
│   └── placeholder/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   ├── DEVELOPMENT.md
│   └── images/
├── resources/
│   ├── cards/                 # CardData .tres (auto-scanned)
│   └── packs/                 # PackConfig .tres (auto-scanned)
├── scenes/
│   ├── Card.tscn
│   ├── CardViewer.tscn
│   ├── Collection.tscn
│   ├── DeckBuilder.tscn
│   ├── DeveloperPanel.tscn
│   ├── MainMenu.tscn
│   ├── Pack.tscn
│   ├── PackOpening.tscn
│   └── Settings.tscn
├── scripts/
│   ├── data/
│   │   ├── card_data.gd
│   │   └── pack_config.gd
│   ├── systems/
│   │   └── pack_generator.gd
│   └── ui/
│       ├── card_scene.gd          # Orchestrator
│       ├── card_renderer.gd
│       ├── card_animation.gd
│       ├── card_interaction.gd
│       ├── card_layer_guard.gd
│       ├── card_visual_library.gd
│       ├── card_viewer.gd
│       ├── collection_view.gd
│       ├── pack_opening.gd        # Orchestrator
│       ├── pack_layout.gd
│       ├── pack_animation.gd
│       ├── pack_scene.gd
│       ├── deck_builder.gd
│       ├── developer_panel.gd
│       ├── main_menu.gd
│       ├── menu_button.gd
│       └── settings_view.gd
├── CHANGELOG.md
├── CONTRIBUTING.md
├── TODO.md
├── LICENSE
├── project.godot
└── icon.svg
```

## Screenshots

> Add screenshots to `docs/images/` and replace the placeholders below when publishing.

| Main Menu | Pack Opening |
|-----------|--------------|
| ![Main Menu](docs/images/main_menu.png) | ![Pack Opening](docs/images/pack_opening.png) |

| Collection | Card Viewer |
|------------|-------------|
| ![Collection](docs/images/collection.png) | ![Card Viewer](docs/images/card_viewer.png) |

*Placeholder paths — capture screenshots from the running project and save them to `docs/images/`.*

## Getting Started

### Requirements

- [Godot 4.4+](https://godotengine.org/download) (project tested with **4.6**)

### How to Run

```bash
git clone https://github.com/MerpMB/TCGdemo.git
cd TCGdemo
```

1. Open `project.godot` in Godot.
2. Press **F5** (or click Play).
3. Use the main menu to open packs and browse your collection.
4. Tap a card in the gallery to open the Card Viewer.
5. Press **F1** at any time to open the Developer Panel.

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the full development guide.

## Content Pipeline (No Code Required)

`CardDatabase` recursively auto-scans `res://resources/cards/` on startup.
`PackDatabase` loads all `PackConfig` files from `res://resources/packs/`.
**Adding a card or pack never requires editing scripts.**

### Asset folders

```
assets/
    cards/          — card artwork (referenced by CardData.tres)
    frames/         — frame PNGs keyed by rarity or CardData.frame
    backs/          — card back PNGs (default.png, etc.)
    variants/       — future variant overlay textures
    glows/          — future rarity glow textures
```

`CardVisualLibrary` is the **single entry point** for loading visual assets.
`CardScene` and `CardRenderer` contain no asset paths.

### Add a new card

1. Drop artwork PNG under `assets/` (e.g. `assets/cards/rare/my-card.png`).
2. Create a `CardData` `.tres` under `resources/cards/`:
   - Set `card_id`, `display_name`, `rarity`, `card_set`, and optional `tags`.
   - Assign the imported texture to `artwork`.
   - Optionally set `frame` and `card_back`.
3. Launch the game — the card registers and renders full-bleed automatically.

### Add a new pack

1. Create a `PackConfig` `.tres` under `resources/packs/`.
2. Set weights and pool filters (`allowed_sets`, `allowed_tags`, `excluded_tags`).
3. Launch — the pack is available via `PackDatabase` and the Developer Panel.

### Rendering order (front face)

```
ArtTexture → FrameTexture → VariantOverlay → LegendarySpark → Interaction
```

Frame PNGs live in `assets/frames/<key>.png`. Missing frames fall back to a procedural `StyleBoxFlat` border — cards always render.

### Pack generation pipeline

```
PackConfig → CardDatabase.get_cards_for_pack() → filtered pool → PackGenerator → pack
```

Rarity and variant weights are unchanged. Packs are isolated by `allowed_sets` and tags.

### Collection behavior

- Every owned copy is stored individually in `CollectionManager` with a unique `instance_id`.
- The gallery stacks exact duplicates (`card_id` + `variant`) for display only.
- The `×N` badge shows owned count. Different variants remain separate entries.

## Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1–3 | ✅ | Framework, prototype, pack presentation |
| Phase 4–5 | ✅ | Card resources, PackConfig, visual systems, collection UX |
| Phase 6 | Upcoming | Save System |
| Phase 7 | Upcoming | Shop |
| Phase 8 | Upcoming | Game Integrations |

See the full [Roadmap](docs/ROADMAP.md) for completed features and upcoming work.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) before opening a pull request.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

Built with [Godot Engine](https://godotengine.org/).

TCG Framework — a reusable card engine for Godot 4.
