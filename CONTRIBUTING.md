# Contributing to TCG Framework

Thank you for your interest in contributing. This project is a modular Godot 4 framework — please keep changes focused and respect the existing separation between data, logic, and UI.

## Before You Start

1. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to understand system boundaries.
2. Check [docs/ROADMAP.md](docs/ROADMAP.md) for planned work.
3. Open an issue or discussion for large changes before opening a pull request.

## Development Setup

1. Install [Godot 4.4+](https://godotengine.org/download).
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

### Do Not

- Put pack generation logic inside UI scenes.
- Let UI mutate `CollectionManager` internal state directly.
- Hardcode references between unrelated UI scenes — use `GameManager` and signals.
- Couple the framework to a specific game ruleset (e.g. Blackjack logic).

## Folder Organization

| Path | Purpose |
|------|---------|
| `autoload/` | Singleton managers and databases |
| `scripts/data/` | `CardData` and future data resources |
| `scripts/systems/` | `PackGenerator` and future pure logic |
| `scripts/ui/` | Scene controllers and visual helpers |
| `scenes/` | Godot scene files (`.tscn`) |
| `resources/` | Future `.tres` card and pack resources |
| `assets/` | Art, audio, and placeholder media |
| `docs/` | Architecture and roadmap documentation |

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
