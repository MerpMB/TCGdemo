# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-08

### Added

- Initial public release of the TCG Framework showcase.
- **Phase 1 — Framework foundation**
  - `CardData` resource with rarity, variant, and catalog fields.
  - `CardDatabase` autoload for card definitions.
  - `PackGenerator` for weighted pack and card generation.
  - `CardScene` and `PackOpeningScene` with face-down reveal flow.
- **Phase 2 — Playable prototype**
  - Main menu with scene navigation (`GameManager`).
  - Runtime `CollectionManager` with signals for collection and deck changes.
  - Collection gallery with scrollable grid and card inspector popup.
  - Deck builder with 10-card deck limit.
  - Developer panel (F1) for rapid testing.
  - `SaveManager` placeholder API for future persistence.
- **Phase 3 — Pack presentation**
  - Reusable `Pack` scene with shake, open, and explode animations.
  - Swappable pack visual profiles.
  - Card fly-out, grid layout, rarity/variant presentation, and pack results summary.
  - Skip reveal, placeholder audio hooks, and card frame/back visual library.

### Fixed

- Renamed `CardData.set_name` to `card_set` to avoid shadowing `Resource.set_name()`.
- Corrected `CardScene` node type annotations (`Control` vs `Panel`) for runtime compatibility.

[0.1.0]: https://github.com/admiralshiboo/TCGdemo/releases/tag/v0.1.0
