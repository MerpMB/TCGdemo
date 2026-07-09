# TCG Framework Roadmap

This document outlines planned development phases. Completed phases are marked with ✅.

---

## Phase 1 — Framework ✅

**Goal:** Establish core data and generation systems independent of any game rules.

- [x] `CardData` resource (ID, name, rarity, variant)
- [x] `CardDatabase` catalog autoload
- [x] `PackGenerator` weighted generation
- [x] Basic `CardScene` and `PackOpeningScene`
- [x] Face-down click-to-reveal flow

---

## Phase 2 — Playable Prototype ✅

**Goal:** Turn the framework into a visual testing application.

- [x] Main menu and scene navigation (`GameManager`)
- [x] Runtime `CollectionManager`
- [x] Collection gallery and card inspector
- [x] Deck builder (10-card limit)
- [x] Developer panel (F1)
- [x] `SaveManager` placeholder API

---

## Phase 3 — Pack Presentation ✅

**Goal:** Polish pack opening into a satisfying TCG-style experience.

- [x] Reusable `Pack` scene (shake, open, explode)
- [x] Swappable pack visual profiles
- [x] Card fly-out and grid layout
- [x] Rarity and variant presentation
- [x] Pack results summary and skip reveal
- [x] Card frame and card back visual library
- [x] Placeholder audio hooks

---

## Phase 4 — Card Resource Pipeline

**Goal:** Move card definitions from code registration to editable resources.

- [ ] `.tres` card definition resources in `resources/cards/`
- [ ] Card set grouping and metadata
- [ ] Editor-friendly import workflow
- [ ] Remove hardcoded placeholder catalog generation

---

## Phase 5 — PackConfig

**Goal:** Data-driven pack types without changing generation architecture.

- [ ] `PackConfig` resources in `resources/packs/`
- [ ] Per-pack slot counts, rarity tables, and variant tables
- [ ] Pack type selection from menu or shop hooks
- [ ] Integration with existing `PackGenerator` API

---

## Phase 6 — Save System

**Goal:** Persist player collection and decks across sessions.

- [ ] Implement `SaveManager.save_game()` / `load_game()` / `delete_save()`
- [ ] Serialize collection instance IDs and deck order
- [ ] Load on startup, save on meaningful events
- [ ] Migration strategy for save format changes

---

## Phase 7 — Shop

**Goal:** Acquire packs and cards through a framework-level economy layer.

- [ ] Currency model (framework-agnostic)
- [ ] Shop UI and pack purchase flow
- [ ] Integration with `PackConfig` and `CollectionManager`
- [ ] Daily rewards and mission hooks (optional)

---

## Phase 8 — Game Integrations

**Goal:** Consume player decks from external games.

- [ ] Export API for collection and deck data
- [ ] **Blackjack** integration prototype
- [ ] **Poker** integration exploration
- [ ] Documentation for third-party game embedding

---

## Future Considerations

These are not yet scheduled but align with the long-term vision:

| Feature | Notes |
|---------|-------|
| **Crafting** | Duplicate cards → resources → targeted cards |
| **Trading** | Player-to-player card exchange |
| **Multiplayer** | Synced pack seeds, collection validation |
| **Seasonal Events** | Limited card sets and pack visuals |
| **Duplicate Protection** | Pity timers, set completion bonuses |
| **Missions** | Daily/weekly objectives |
| **Advanced Shaders** | Replace placeholder foil/diamond effects |

---

## Version Targets

| Version | Target |
|---------|--------|
| v0.1.0 | Phases 1–3 (current) |
| v0.2.0 | Phase 4 — Card Resource Pipeline |
| v0.3.0 | Phase 5–6 — PackConfig + Save System |
| v0.4.0 | Phase 7 — Shop |
| v1.0.0 | Phase 8 — Game Integrations + stable API |

---

*Last updated: 2026-07-08*
