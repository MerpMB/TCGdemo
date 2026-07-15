# PROJECT STATUS

| | |
|---|---|
| **Project Name** | TCG Framework |
| **Current Version** | v0.1.0 (released) — v0.2.0 scope in active development (unreleased; see [CHANGELOG.md](CHANGELOG.md)) |
| **Engine** | Godot 4.6 |
| **Current Milestone** | Phase 5 complete — entering **Content Production Phase** |
| **Overall Status** | **Production-ready framework** with a playable core loop; content volume and persistence are the main gaps |

*Last updated: 2026-07-15*

---

# Project Pillar

The core gameplay loop is the highest priority. Every new feature should support or improve this loop — not bypass it.

```
Main Menu
    ↓
Open Pack
    ↓
Reveal 7 Cards
    ↓
Cards Added to Collection
    ↓
Collection Gallery
    ↓
Card Viewer (optional)
    ↓
Repeat
```

**Principles**

- Gameplay loop first — ship loop improvements before peripheral systems.
- Data-driven content — cards and packs via `.tres` resources, not script edits.
- Presentation separated from logic — `PackGenerator` never touches UI; UI never filters pack pools.
- Renderer stability — extend via `CardVisualLibrary` and helpers, not monolithic scene scripts.

---

# Current State

The framework prototype is fully playable on mobile-first portrait layouts.

| Area | Status |
|------|--------|
| Mobile-first architecture | ✓ |
| Portrait UI (720×1280) | ✓ |
| Responsive layouts (pack grid, collection, viewer) | ✓ |
| `CardData` resources | ✓ |
| `PackConfig` resources | ✓ |
| `CardDatabase` (auto-scan `resources/cards/`) | ✓ |
| `PackDatabase` (auto-scan `resources/packs/`) | ✓ |
| `PackGenerator` (weighted rolls from filtered pool) | ✓ |
| `CollectionManager` (runtime ownership + signals) | ✓ |
| `CardVisualLibrary` (visual asset entry point) | ✓ |
| Full-art renderer | ✓ |
| Asset-based frames (`assets/frames/`) | ✓ |
| Asset-based card backs (`assets/backs/`) | ✓ |
| Variant shader polish (Foil, Diamond, Negative) | ✓ |
| Duplicate stacking (gallery view-only) | ✓ |
| Owned-count badges (`×N`) | ✓ |
| Card Viewer (full-screen, art-only) | ✓ |
| Layer leak prevention (`CardLayerGuard`) | ✓ |
| UI module split (CardScene / PackOpening helpers) | ✓ |
| Pack pool isolation (`allowed_sets`, tags) | ✓ |
| Deck builder (framework feature, not in main loop) | ✓ |
| Developer panel (F1) | ✓ |
| Save persistence | ✗ placeholder only |
| Pack selection UI on main menu | ✗ defaults to `starter_pack` |
| Collection search / filters | ✗ hook exists, not wired |

**Content loaded today:** 44 cards · 4 pack types

---

# Architecture Snapshot

Gameplay, generation, and rendering are strictly separated.

```
Managers (autoload)
    GameManager · CardDatabase · PackDatabase · CollectionManager · SaveManager

Logic (RefCounted / systems)
    PackGenerator  →  queries  →  CardDatabase.get_cards_for_pack()

UI orchestrators
    PackOpening · Collection · CardViewer · MainMenu
```

### CardScene (orchestrator only)

```
CardScene
    ├── CardRenderer        — applies CardData visuals to node refs
    ├── CardAnimation       — arrival, reveal, variant idle FX
    ├── CardInteraction     — gallery tap / hover
    ├── CardLayerGuard      — debug protected-layer drift checks
    └── CardVisualLibrary   — shaders, frames, backs, timing constants
```

### PackOpening (orchestrator only)

```
PackOpening
    ├── PackLayout          — responsive grid math
    ├── PackAnimation       — pack sequence + legendary flash
    └── CardScene           — per-card fly-out and reveal
```

### Collection

```
Collection (collection_view.gd)
    ├── CollectionManager   — stores every owned copy individually
    ├── duplicate stacking  — presentation only (card_id + variant key)
    └── CardViewer          — via GameManager.show_card_viewer()
```

**Rule:** `CardRenderer` and `CardScene` contain **no asset paths**. All visual loading goes through `CardVisualLibrary`.

---

# Asset Pipeline

```
assets/
    cards/          — card artwork PNGs (referenced by CardData.tres)
    frames/         — rarity/frame PNGs (common, rare, epic, legendary)
    backs/          — card back PNGs (e.g. default.png)
    shaders/        — variant FX shaders (foil, diamond, negative)
    variants/       — reserved for future variant overlay textures
    glows/          — reserved for future rarity glow textures
    placeholder/    — dev placeholder slot
```

**Workflow (no code required)**

1. Drop PNGs under `assets/`.
2. Create or edit `CardData` / `PackConfig` `.tres` under `resources/`.
3. Launch — autoloads register content on startup.

`CardVisualLibrary` is the **only** class responsible for loading visual assets (textures, shaders, StyleBox fallbacks). Missing assets warn once and fall back gracefully.

---

# Current Variant Support

Variants defined in `CardData.Variant` and rendered via `VariantOverlay` (above frame).

| Variant | Enum | Visual treatment |
|---------|------|------------------|
| **Normal** | `NORMAL` | No effects |
| **Foil** | `FOIL` | Diagonal holographic shader sweep |
| **Negative** | `NEGATIVE` | Inverted artwork + subtle chromatic edge pulse |
| **Alternate Art** | `ALTERNATIVE_ART` | No overlay FX — artwork is the variant |
| **Diamond** | `DIAMOND` | Cool white/blue crystal glow + point twinkles |

**Not in codebase:** **Gold** is not present in `CardData.Variant`. Do not assume a Gold variant until the enum and renderer branch exist.

**Future variants:** not planned yet.

---

# Current Pack Support

Four `PackConfig` resources in `resources/packs/`:

| Pack ID | Display Name | Pool filter |
|---------|--------------|-------------|
| `starter_pack` | Starter Pack | `allowed_sets`: Core Set · excludes event/limited/developer/debug tags |
| `premium_pack` | Premium Pack | Core Set · higher rarity weights |
| `event_pack` | Event Pack | `allowed_sets`: Event Set · `allowed_tags`: event |
| `developer_pack` | Developer Pack | `allowed_sets`: Developer Set · `allowed_tags`: developer |

**Generation pipeline**

```
PackConfig
    ↓
CardDatabase.get_cards_for_pack()   ← allowed_sets, allowed_tags, excluded_tags
    ↓
Filtered candidate pool
    ↓
PackGenerator                       ← rarity_weights + variant_weights unchanged
    ↓
7 × CardData instances
```

Empty filter arrays mean “no restriction” on that axis. `PackGenerator` never inspects sets or tags directly.

**Note:** Main menu currently selects `starter_pack` only. Other packs are reachable via Developer Panel or `GameManager.set_selected_pack()`.

---

# Current Issues

Active GitHub issues only ([MerpMB/TCGdemo](https://github.com/MerpMB/TCGdemo)):

| # | Title | Notes |
|---|-------|-------|
| **5** | Issue #6 — Production Asset Pipeline | Partially implemented (frames, backs, library); issue still open |
| **9** | Issue #10 — Content Pipeline | Editorial workflow, content volume, import tooling |

---

# Completed Issues

| Item | GitHub |
|------|--------|
| ✓ Fix Card Animation Hierarchy / layer leaks | #1 |
| ✓ Full Art Renderer | #2 |
| ✓ Collection Gallery | #3 |
| ✓ Card Viewer | #4 |
| ✓ Replace Procedural Frames | #6 |
| ✓ CardScene Cleanup (module split) | #7 |
| ✓ Performance Audit (baseline pass) | #8 |
| ✓ Documentation behind code (F2) | — |
| ✓ Variant Visual Polish (shader FX pass) | #11 (local) |

**Also shipped (no open issue):** PackConfig + PackDatabase · pack pool isolation · duplicate stacking · owned badges · card back pipeline · UI module split · mobile portrait layout

---

# Upcoming Priorities

Recommended order for next development sessions:

1. **Content Pipeline** — more cards, sets, artwork, pack definitions (Issue #9)
2. **Production Asset Pipeline close-out** — finalize Issue #5, variant/glow texture folders
3. **Save System** — implement `SaveManager` persistence (Phase 6)
4. **Collection Filters** — wire `_apply_view_filters()` in collection gallery
5. **Pack Selection UI** — expose pack choice on main menu

---

# Known Technical Debt

Real remaining debt only — not shipped work.

| Item | Impact |
|------|--------|
| `SaveManager` is stub-only | Collection resets every session |
| No pack picker on main menu | Players cannot choose Premium/Event packs in normal flow |
| `assets/variants/` and `assets/glows/` unused | Procedural shaders used instead of texture overlays |
| Collection filter hook is a pass-through | Search / rarity / variant filters not implemented |
| `CHANGELOG` still at v0.1.0 | v0.2.0 work unreleased / undocumented in changelog |
| Deck builder not linked from main menu | Framework feature exists but hidden |
| CardViewer has no metadata overlays | By design for now; hooks are empty stubs |
| README screenshots are placeholders | `docs/images/` not populated |
| Large uncommitted local diff | Architecture refactor + assets + variant shaders not yet on `master` |

---

# Future Content

Near-term work should emphasize **content**, not architecture rewrites:

- More **cards** and **artwork** under `resources/cards/` and `assets/cards/`
- Additional **packs** and set/tag combinations via `PackConfig`
- **Variant** distribution tuning through `variant_weights`
- **Progression** hooks (save, collection filters, pack shop) built on existing managers

The renderer and module split are considered **stable**. Prefer data-driven additions over new autoloads or scene hierarchy changes.

---

# Development Notes

- **Gameplay loop comes first.** If a feature does not improve open-pack → collect → repeat, defer it.
- **Do not over-engineer.** Small, focused diffs; no speculative abstractions.
- **Keep CardScene lightweight.** New card behavior → `CardRenderer`, `CardAnimation`, or `CardVisualLibrary`.
- **CardVisualLibrary owns all visual assets.** Never hardcode `res://assets/...` in UI scripts.
- **Pack pool filtering lives in `CardDatabase.get_cards_for_pack()`** — not in `PackGenerator` or UI.
- **Duplicate stacking is view-only.** `CollectionManager` always stores individual copies with `instance_id`.
- **Protected render layers must not move.** Reveal lift animates Card root `position.y`; flip uses `FlipPivot.scale.x` only.
- **Prefer `.tres` over code** for cards, packs, weights, and tags.
- **Check this file first** at the start of every session, then [TODO.md](TODO.md) and [docs/ROADMAP.md](docs/ROADMAP.md).

---

# Progress Summary

Approximate completion (framework & showcase, not commercial content depth):

| Area | Progress | Notes |
|------|----------|-------|
| **Foundation** | 95% | Data, managers, generator, autoloads |
| **Renderer** | 90% | Full-art, frames, backs, variant shaders |
| **Asset Pipeline** | 85% | Library + folders; variant/glow PNG path unused |
| **Mobile** | 95% | Portrait, responsive grids, touch-first |
| **Collection** | 80% | Gallery, stacking, viewer; no filters/save |
| **Content** | 35% | 44 cards, 4 packs — room to grow |
| **Polish** | 75% | Pack FX, variant shaders; audio/screenshots thin |
| **Overall** | **~78%** | Playable loop complete; persistence & content scale remain |

---

*Related docs: [README.md](README.md) · [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · [docs/ROADMAP.md](docs/ROADMAP.md) · [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) · [TODO.md](TODO.md)*
