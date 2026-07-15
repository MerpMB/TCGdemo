# TCG Framework Roadmap

This document tracks shipped work and planned features. Phases 4–5 and the architecture refactors are complete.

---

## Completed

### Phase 1 — Framework Foundation

- [x] `CardData` resource (ID, name, rarity, variant, set, tags)
- [x] `CardDatabase` autoload with recursive `.tres` scanning
- [x] `PackGenerator` weighted generation
- [x] `CardScene` and `PackOpening` with face-down reveal flow

### Phase 2 — Playable Prototype

- [x] Main menu and scene navigation (`GameManager`)
- [x] Runtime `CollectionManager` with change signals
- [x] Deck builder (10-card limit)
- [x] Developer panel (F1)
- [x] `SaveManager` placeholder API

### Phase 3 — Pack Presentation

- [x] Reusable `Pack` scene (shake, open, explode)
- [x] Swappable pack visual profiles
- [x] Card fly-out and responsive grid layout
- [x] Rarity and variant presentation
- [x] Skip reveal and pack results summary
- [x] Placeholder audio hooks

### Phase 4 — Card Resource Pipeline

- [x] `.tres` card definitions in `resources/cards/`
- [x] Card set grouping and metadata (`card_set`, `tags`)
- [x] Recursive auto-scan on startup — no script edits to add cards
- [x] Artwork assigned per-card via `CardData.artwork`

### Phase 4.5 — Visual Systems

- [x] Mobile-first portrait UI (720×1280)
- [x] Responsive layouts (collection grid, pack grid, CardViewer scaling)
- [x] Full-art card renderer (art fills card; frame as overlay)
- [x] Card back system (`assets/backs/`, `BackTexture` + fallback)
- [x] Frame asset system (`assets/frames/`, PNG + StyleBox fallback)
- [x] `CardVisualLibrary` as single visual asset entry point
- [x] Layer leak prevention (`CardLayerGuard`, root-only reveal lift)
- [x] Animation hierarchy fix (FlipPivot scale-only flip)

### Phase 5 — PackConfig & Collection UX

- [x] `PackConfig` resources in `resources/packs/`
- [x] `PackDatabase` autoload
- [x] Per-pack slot counts, rarity tables, and variant tables
- [x] Pack pool isolation (`allowed_sets`, `allowed_tags`, `excluded_tags`)
- [x] `CardDatabase.get_cards_for_pack()` filtering
- [x] Collection gallery with duplicate stacking (view-only)
- [x] Owned count badges (`×N`)
- [x] Card Viewer (full-screen, art-only, tap-outside close)

### Architecture Refactor

- [x] `CardScene` split: `CardRenderer`, `CardAnimation`, `CardInteraction`, `CardLayerGuard`
- [x] `PackOpening` split: `PackLayout`, `PackAnimation`
- [x] Modular CardScene orchestration (~160 lines)
- [x] Asset pipeline documented (no-code content workflow)

---

## Upcoming

### Phase 6 — Save System

- [ ] Implement `SaveManager.save_game()` / `load_game()` / `delete_save()`
- [ ] Serialize collection instance IDs and deck order
- [ ] Load on startup, save on meaningful events
- [ ] Migration strategy for save format changes

### Phase 7 — Shop

- [ ] Currency model (framework-agnostic)
- [ ] Shop UI and pack purchase flow
- [ ] Pack type selection from menu or shop hooks
- [ ] Daily rewards and mission hooks (optional)

### Phase 8 — Game Integrations

- [ ] Export API for collection and deck data
- [ ] **Blackjack** integration prototype
- [ ] **Poker** integration exploration
- [ ] Documentation for third-party game embedding

### Future Considerations

| Feature | Notes |
|---------|-------|
| **Crafting** | Duplicate cards → resources → targeted cards |
| **Trading** | Player-to-player card exchange |
| **Multiplayer** | Synced pack seeds, collection validation |
| **Seasonal Events** | Limited card sets and pack visuals |
| **Duplicate Protection** | Pity timers, set completion bonuses |
| **Missions** | Daily/weekly objectives |
| **Advanced Shaders** | Replace procedural foil/diamond effects with `assets/variants/` textures |
| **Collection Filters** | Search, rarity/variant/favorite filters in gallery |
| **CardViewer Metadata** | Optional description, artist, flavor overlays |
| **Variant Texture Pipeline** | Wire `assets/variants/` and `assets/glows/` into renderer |

---

## Version Targets

| Version | Scope |
|---------|-------|
| v0.1.0 | Phases 1–3 |
| v0.2.0 | Phases 4–5, visual systems, architecture refactor (current) |
| v0.3.0 | Phase 6 — Save System |
| v0.4.0 | Phase 7 — Shop |
| v1.0.0 | Phase 8 — Game Integrations + stable API |

---

*Last updated: 2026-07-15*
