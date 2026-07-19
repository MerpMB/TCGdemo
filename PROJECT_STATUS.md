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
| Production asset pipeline (`docs/ASSET_PIPELINE.md`) | ✓ |
| Variant Material System (Foil production stack) | ✓ |
| Gold Variant Material (production stack) | — (enum is `SYNTH`; gold shaders unused) |
| Synth Variant Material (production stack) | ✓ |
| Variant shader polish (Diamond, Negative legacy) | ✓ |
| Duplicate stacking (gallery view-only) | ✓ |
| Owned-count badges (`×N`) | ✓ |
| Card Viewer (full-screen, art-only) | ✓ |
| Layer leak prevention (`CardLayerGuard`) | ✓ |
| UI module split (CardScene / PackOpening helpers) | ✓ |
| Pack pool isolation (`allowed_sets`, tags) | ✓ |
| Deck builder (framework feature, not in main loop) | ✓ |
| Developer panel (F1) | ✓ |
| Save persistence | ✓ versioned `SaveManager` (`user://tcg_save.json`) |
| Pack selection UI | ✓ Pack Hub (four class packs) |
| Collection search / filters | ✗ hook exists, not wired |

**Content loaded today:** 53 cards · 4 class packs (Knight / Mage / Priest / Rogue)

---

# Architecture Snapshot

Gameplay, generation, and rendering are strictly separated.

```
Managers (autoload)
    GameManager · CardDatabase · PackDatabase · CollectionManager
    PackInventoryManager · OpenPackService · SaveManager

Logic (RefCounted / systems)
    PackGenerator  →  queries  →  CardDatabase.get_cards_for_pack()

UI orchestrators
    PackHub · PackOpening · Collection · CardViewer · CardInspection · MainMenu
```

### CardScene (orchestrator only)

```
CardScene
    ├── CardRenderer        — applies CardData visuals to node refs
    ├── VariantRenderer     — generic layered material stack (via RenderLayerContainer)
    ├── CardAnimation       — arrival, reveal, variant idle FX
    ├── CardInteraction     — gallery tap / hover
    ├── CardLayerGuard      — debug protected-layer drift checks
    └── CardVisualLibrary   — layer blueprints, shaders, frames, backs, timing constants
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

Full reference: [docs/ASSET_PIPELINE.md](docs/ASSET_PIPELINE.md)

```
assets/
    cards/
        common/ · rare/ · epic/ · legendary/
        event/ · developer/
    frames/         common.png, rare.png, epic.png, legendary.png
    backs/          default.png
    variants/       foil/ · gold/ · diamond/ · negative/  (PNG optional)
    glows/          common/ · rare/ · epic/ · legendary/    (PNG optional)
    shaders/        procedural variant FX fallback
```

**Loading flow:** `CardData` → `CardRenderer` → `VariantRenderer` + `CardVisualLibrary` → textures / shaders / StyleBox fallbacks.

**Convention:** `assets/cards/<folder>/<card_id>.png` auto-resolves when `CardData.artwork` is null.

`CardVisualLibrary` is the **only** class with `res://assets/...` paths. Missing required assets warn once; optional PNGs fail silently to shader/color fallbacks.

---

---

# Variant Material System

**Status: Production Ready** (Foil validated through Phase 2.5)

| Phase | Scope | Status |
|-------|-------|--------|
| 2.1 | Premium Foil material prototype (layer blueprints) | ✓ Complete |
| 2.2 | Material depth & idle parallax | ✓ Complete |
| 2.3 | Per-layer quiet tuning | ✓ Complete |
| 2.4 | Layer cohesion (`material_response`) | ✓ Complete |
| 2.5 | Final foil polish & validation | ✓ Complete |

### Foil layer stack (artwork → frame)

```
Artwork
    ↓
Micro Grain      (TEXTURE, MUL, depth 0.02)
    ↓
Rainbow          (SHADER foil_rainbow, depth 0.08)
    ↓
Shine            (SHADER foil_soft_shine, depth 0.15)
    ↓
Glitter          (TEXTURE scroll, depth 0.25)
    ↓
Sparkles         (TEXTURE pulse, depth 0.35)
    ↓
Frame
```

One global idle driver moves layers by `depth × material_response`. Visual priority: **artwork → frame → foil material**.

### Gold Variant

**Status: Production Ready** (validated through Phase 3.5)

| Phase | Scope | Status |
|-------|-------|--------|
| 3.1 | Gold material prototype (stamped metallic stack) | ✓ Complete |
| 3.2 | Material depth & motion | ✓ Complete |
| 3.3 | Layer tuning (review-mode visibility) | ✓ Complete |
| 3.4 | Material cohesion (`material_response`) | ✓ Complete |
| 3.5 | Final gold polish & validation | ✓ Complete |

```
Artwork
    ↓
Brushed Metal Grain     (TEXTURE, MUL, depth 0.02)
    ↓
Warm Metallic Reflection (SHADER gold_warm_reflection, depth 0.07)
    ↓
Gold Mirror Shine       (SHADER gold_mirror_shine, depth 0.16)  ← dominant cue
    ↓
Metal Flakes            (TEXTURE scroll, depth 0.20)
    ↓
Tiny Specular           (TEXTURE pulse, depth 0.24)
    ↓
Frame
```

Gold uses **reflection** (warm champagne/amber/bronze), not foil **diffraction**. Mirror shine is the strongest cue. Depth × `material_response` keeps Gold heavier and slower than Foil.

**Gold is production-ready.** Future work should tune values only — no renderer redesign.

### Frozen renderer architecture

`VariantRenderer`, `VariantLayer`, `CardRenderer`, and `CardVisualLibrary` are considered **stable**. Future variant work should author content through **VariantLayer blueprints** and assets under `assets/variants/` — not redesign the renderer unless a real limitation is discovered.

**Diamond and Negative** still use legacy `LegacyVariantFx` shader paths until migrated.

---

# Current Variant Support

Variants defined in `CardData.Variant`. Foil uses `RenderLayerContainer`; others use legacy overlay nodes until migrated.

| Variant | Enum | Visual treatment |
|---------|------|------------------|
| **Normal** | `NORMAL` | No effects |
| **Foil** | `FOIL` | Production layered material (grain, rainbow, shine, glitter, sparkles) |
| **Negative** | `NEGATIVE` | Inverted artwork + subtle chromatic edge pulse (legacy) |
| **Alternate Art** | `ALTERNATIVE_ART` | No overlay FX — artwork is the variant |
| **Diamond** | `DIAMOND` | Cool white/blue crystal glow + point twinkles (legacy) |
| **Synth** | `SYNTH` | Production layered PCB / fiber material (`SynthMaterials`) |

**Future variants:** author via `CardVisualLibrary.VARIANT_LAYER_BLUEPRINTS`, not renderer changes.

---

# Current Pack Support

Four `PackConfig` resources in `resources/packs/`:

| Pack ID | Display Name | Pool filter |
|---------|--------------|-------------|
| `knight_pack` | Knight Class Pack | `allowed_sets`: Knight Deck |
| `mage_pack` | Mage Class Pack | `allowed_sets`: Mage Deck |
| `priest_pack` | Priest Class Pack | `allowed_sets`: Priest Deck |
| `rogue_pack` | Rogue Class Pack | `allowed_sets`: Rogue Deck |
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

**Note:** Pack Hub exposes all four class packs; claim the currently selected pack before opening it.

---

# Current Issues

Active GitHub issues only ([MerpMB/TCGdemo](https://github.com/MerpMB/TCGdemo)):

| # | Title | Notes |
|---|-------|-------|
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
| ✓ Variant Material System — Foil production stack (Phases 2.1–2.5) | — |
| ✓ Gold Variant Material — production stack (Phases 3.1–3.5) | — |
| ✓ Variant Visual Polish (shader FX pass) | #11 (local) |
| ✓ Production Asset Pipeline | #5 / Issue #6 |

**Also shipped (no open issue):** PackConfig + PackDatabase · pack pool isolation · duplicate stacking · owned badges · card back pipeline · UI module split · mobile portrait layout · `card_id` artwork convention

---

# Upcoming Priorities

Recommended order for next development sessions:

1. **Content Pipeline** — more cards, sets, artwork, pack definitions
2. **Collection Filters** — wire `_apply_view_filters()` in collection gallery
3. **Warmup staging** — defer rare variant shader compile for faster boot (#19)
4. **Pack pool validation** — startup checks that every weight key has pool cards (#21)

---

# Known Technical Debt

Real remaining debt only — not shipped work.

| Item | Impact |
|------|--------|
| No pack purchase / shop currency | Players claim packs via Pack Hub for now |
| Variant/glow PNG folders empty | Shaders used; drop `overlay.png` / `glow.png` when art is ready |
| 31 of 44 cards lack artwork | Placeholders use rarity color bodies |
| Collection filter hook is a pass-through | Search / rarity / variant filters not implemented |
| `CHANGELOG` still at v0.1.0 | v0.2.0 work unreleased / undocumented in changelog |
| Deck builder not linked from main menu | Framework feature exists but hidden |
| CardViewer has no metadata overlays | By design for now; hooks are empty stubs |
| README screenshots are placeholders | `docs/images/` not populated |

---

# Future Content

Near-term work should emphasize **content**, not architecture rewrites:

- More **cards** and **artwork** under `resources/cards/` and `assets/cards/`
- Additional **packs** and set/tag combinations via `PackConfig`
- **Variant** distribution tuning through `variant_weights`
- **Progression** hooks (save, collection filters, pack shop) built on existing managers

The renderer and module split are considered **stable**. Prefer data-driven additions (cards, packs, variant layer blueprints) over new autoloads or scene hierarchy changes.

---

# Development Notes

- **Gameplay loop comes first.** If a feature does not improve open-pack → collect → repeat, defer it.
- **Do not over-engineer.** Small, focused diffs; no speculative abstractions.
- **Keep CardScene lightweight.** New card behavior → `CardRenderer`, `CardAnimation`, or `CardVisualLibrary`.
- **CardVisualLibrary owns all visual assets.** Never hardcode `res://assets/...` in UI scripts. Variant FX factories live in sibling modules (`FoilMaterials`, etc.); CVL remains the public facade.
- **Data layer stays presentation-free.** `CardData` / `CardDatabase` store plain frame and card_back strings; parsing and asset validation live in `CardVisualLibrary` / the renderer only.
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
| **Renderer** | 96% | Full-art, frames, backs, foil + gold production stacks; Diamond/Negative legacy |
| **Asset Pipeline** | 95% | Full folder tree, convention paths, `ASSET_PIPELINE.md` |
| **Mobile** | 95% | Portrait, responsive grids, touch-first |
| **Collection** | 80% | Gallery, stacking, viewer; no filters/save |
| **Content** | 35% | 44 cards, 4 packs — room to grow |
| **Polish** | 75% | Pack FX, variant shaders; audio/screenshots thin |
| **Overall** | **~80%** | Playable loop complete; persistence & content scale remain |

---

*Related docs: [README.md](README.md) · [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · [docs/ASSET_PIPELINE.md](docs/ASSET_PIPELINE.md) · [docs/ROADMAP.md](docs/ROADMAP.md) · [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) · [TODO.md](TODO.md)*
