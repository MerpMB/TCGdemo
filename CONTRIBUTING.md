# Contributing to TCG Framework

Thank you for your interest in contributing. This project is a modular Godot 4 framework — please keep changes focused and respect the existing separation between data, logic, and UI.

## Before You Start

1. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to understand system boundaries.
2. Read [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for local setup and coding rules.
3. Check [docs/ROADMAP.md](docs/ROADMAP.md) and [TODO.md](TODO.md) for planned work.
4. Open an issue or discussion for large changes before opening a pull request.

## Development Setup

1. Install [Godot 4.4+](https://godotengine.org/download) (4.6 recommended).
2. Clone the repository.
3. Open `project.godot` in Godot.
4. Press **F5** to run the project.

## Coding Style

### GDScript

- Use Godot 4 GDScript conventions (typed variables where practical, `class_name` for shared types).
- Prefer `##` doc comments on classes and public methods.
- Use `snake_case` for functions and variables; `PascalCase` for class names and enums.
- Use `@onready` and `%UniqueNodeNames` for scene references.
- Keep files focused — one primary responsibility per script.

### Architecture Rules

- **Data** (`scripts/data/`) — resources and plain data types only.
- **Systems** (`scripts/systems/`) — pure logic with no scene or UI dependencies.
- **UI** (`scripts/ui/`) — presentation and input; requests data through managers.
- **Autoloads** (`autoload/`) — global services (managers, databases).
- **Visual assets** — load only through `CardVisualLibrary`; no paths in `CardScene` or `CardRenderer`.
- **Pack pools** — filter only in `CardDatabase.get_cards_for_pack()`; `PackGenerator` draws from the returned pool.

### CardScene module boundaries

| Module | May touch |
|--------|-----------|
| `card_scene.gd` | Orchestration, mode setup, signals |
| `card_renderer.gd` | Visual node properties via `CardVisualLibrary` |
| `card_animation.gd` | Card root motion, FlipPivot scale.x, FX opacity/sweep |
| `card_interaction.gd` | Gallery input only |
| `card_layer_guard.gd` | Debug assertions only |

### Do Not

- Put pack generation or pool filtering logic inside UI scenes.
- Let UI mutate `CollectionManager` internal state directly.
- Hardcode references between unrelated UI scenes — use `GameManager` and signals.
- Animate protected render layers (`ArtTexture`, `FrameTexture`, etc.) for card motion.
- Couple the framework to a specific game ruleset (e.g. Blackjack logic).

## Folder Organization

| Path | Purpose |
|------|---------|
| `autoload/` | Singleton managers and databases |
| `scripts/data/` | `CardData`, `PackConfig` resources |
| `scripts/systems/` | `PackGenerator` and future pure logic |
| `scripts/ui/` | Scene controllers and UI helpers |
| `scenes/` | Godot scene files (`.tscn`) |
| `resources/cards/` | `CardData` `.tres` definitions |
| `resources/packs/` | `PackConfig` `.tres` definitions |
| `assets/` | Art and visual media |
| `docs/` | Architecture, roadmap, and development docs |

## Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Scripts | `snake_case.gd` | `pack_opening.gd` |
| Scenes | `PascalCase.tscn` | `PackOpening.tscn` |
| Signals | past tense or state change | `collection_changed` |
| Autoloads | `PascalCase` | `CollectionManager` |

## Pull Request Guidelines

1. **Scope** — One feature or fix per PR when possible.
2. **Description** — Explain what changed and why.
3. **Testing** — Confirm the project runs (F5) and the affected flow still works.
4. **No drive-by refactors** — Avoid unrelated formatting or architecture changes.
5. **Documentation** — Update `CHANGELOG.md` and relevant `docs/` files for user-facing changes.

## Reporting Bugs

Include:

- Godot version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or console output if applicable

## Questions

For design questions, refer to [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) or open a GitHub discussion.
