# Project TODO

Active work items only. Completed features are tracked in [docs/ROADMAP.md](docs/ROADMAP.md).

---

## High Priority

- [x] **Save System (Phase 6)** — Versioned `SaveManager` persistence for collection, inventory, and selected pack
- [x] **Collection persistence** — Load on startup; save after pack open / meaningful events

## Medium Priority

- [x] **Pack selection UI** — Pack Hub exposes the four class packs and claims the selected pack
- [ ] **Collection filters** — Wire `_apply_view_filters()` in `collection_view.gd` (search, rarity, variant)
- [ ] **Screenshots** — Capture and add images to `docs/images/` for README
- [ ] **Defer visual warmup** — Stage rare variant shader compile for faster boot (Issue #19)
- [ ] **Pack pool validation** — Startup checks that every weight key has pool cards (Issue #21)

## Low Priority / Future

- [ ] **Shop (Phase 7)** — Currency and pack purchase flow
- [ ] **Variant texture pipeline** — Load `assets/variants/` and `assets/glows/` in renderer
- [ ] **CardViewer metadata** — Optional description, artist, flavor overlays
- [ ] **Deck builder navigation** — Re-expose deck builder from main menu if needed (Issue #15)
- [ ] **Game integrations (Phase 8)** — Blackjack, Poker export API
- [ ] **Crafting / trading / multiplayer** — See ROADMAP future considerations

---

*Last updated: 2026-07-20*
