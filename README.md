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

- ✅ **Pack Opening** — Full presentation flow with pack animations, card fly-out, rarity effects, and results summary
- ✅ **Collection** — Scrollable grid of owned cards with hover and click feedback
- ✅ **Deck Builder** — Split-view collection → deck with 10-card limit
- ✅ **Card Inspector** — Popup detail view for any owned card
- ✅ **Developer Panel** — F1 testing tools (give cards, clear collection, generate packs)
- ✅ **Runtime Collection Manager** — In-memory collection and deck with change signals

## Architecture Overview

| System | Role |
|--------|------|
| **CardDatabase** | Catalog of all card definitions — single source of truth |
| **PackGenerator** | Weighted pack/card generation — pure logic, no UI |
| **CollectionManager** | Player-owned cards and active deck |
| **GameManager** | Scene navigation, transitions, global overlays |
| **SaveManager** | Persistence API placeholder for future disk saves |
| **UI** | Scene controllers that request data and react to signals |

```
CardDatabase  ◄──  PackGenerator
      ▲
      │
CollectionManager  ◄──  UI Scenes
      ▲
      │
 SaveManager (placeholder)
```

For full details, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Project Structure

```
TCGdemo/
├── autoload/                  # Singleton managers
│   ├── card_database.gd
│   ├── collection_manager.gd
│   ├── game_manager.gd
│   └── save_manager.gd
├── assets/
│   └── placeholder/           # Frames, backs, future art
├── docs/
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   └── images/                # Screenshots (add your own)
├── resources/
│   ├── cards/                 # Future .tres card resources
│   └── packs/                 # Future .tres pack configs
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
│   │   └── card_data.gd
│   ├── systems/
│   │   └── pack_generator.gd
│   └── ui/
│       ├── card_scene.gd
│       ├── card_viewer.gd
│       ├── card_visual_library.gd
│       ├── collection_view.gd
│       ├── deck_builder.gd
│       ├── developer_panel.gd
│       ├── main_menu.gd
│       ├── menu_button.gd
│       ├── pack_opening.gd
│       ├── pack_scene.gd
│       └── settings_view.gd
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── project.godot
└── icon.svg
```

## Screenshots

> Add screenshots to `docs/images/` and replace the placeholders below when publishing.

| Main Menu | Pack Opening |
|-----------|--------------|
| ![Main Menu](docs/images/main_menu.png) | ![Pack Opening](docs/images/pack_opening.png) |

| Collection | Deck Builder |
|------------|--------------|
| ![Collection](docs/images/collection.png) | ![Deck Builder](docs/images/deck_builder.png) |

*Placeholder paths — capture screenshots from the running project and save them to `docs/images/`.*

## Getting Started

### Requirements

- [Godot 4.4+](https://godotengine.org/download) (project tested with 4.6)

### How to Run

```bash
git clone https://github.com/admiralshiboo/TCGdemo.git
cd TCGdemo
```

1. Open `project.godot` in Godot.
2. Press **F5** (or click Play).
3. Use the main menu to open packs, browse your collection, and build a deck.
4. Press **F1** at any time to open the Developer Panel.

## Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ | Framework foundation (data, generator, basic UI) |
| Phase 2 | ✅ | Playable prototype (menu, collection, deck builder) |
| Phase 3 | ✅ | Pack presentation polish |
| Phase 4 | Upcoming | Card Resource Pipeline |
| — | Planned | PackConfig, Save System, Collection Persistence |

See the full [Roadmap](docs/ROADMAP.md) for Phases 5–8 and future goals.

### Future Goals

- Shop and economy layer
- Crafting and duplicate handling
- Trading and multiplayer
- **Game integrations** — Blackjack, Poker, and future card games

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history. Current release: **v0.1.0**.

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

Built with [Godot Engine](https://godotengine.org/).

TCG Framework — a reusable card engine for Godot 4.
