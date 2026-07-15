# Documentation Audit Report — F2

**Date:** 2026-07-15  
**Scope:** Documentation-only update after Phases 4.5–5 and architecture refactors  
**Constraint:** No gameplay, scene, script, asset, or project-setting changes

---

## 1. Audit Findings (Before Update)

### README.md

| Issue | Severity |
|-------|----------|
| Listed "Card Inspector" — replaced by Card Viewer | High |
| Missing PackDatabase, PackConfig, modular CardScene/PackOpening | High |
| Project structure outdated (no pack/card resources, no UI modules) | High |
| Roadmap showed Phase 4 as upcoming; Phases 4–5 are complete | High |
| Frame docs said "procedural by default" — PNG frames are primary path | Medium |
| `assets/placeholder/` only folder listed; actual `frames/`, `backs/`, `cards/` missing | Medium |
| Clone URL pointed to `admiralshiboo/TCGdemo` | Low |
| Deck builder in features but not in documented game loop | Low |

### docs/ARCHITECTURE.md

| Issue | Severity |
|-------|----------|
| Referenced "Inspector" overlay — now CardViewer | High |
| CardScene described as monolithic visual owner | High |
| CardVisualLibrary described as "placeholder styles" | High |
| Missing PackDatabase, PackConfig, pack pool filtering | High |
| Missing CardRenderer/Animation/Interaction/LayerGuard split | High |
| Missing PackLayout/PackAnimation split | High |
| `PackGenerator.generate_pack(CardDatabase)` — outdated API (needs PackConfig) | High |
| CardData field `card_name` — actual field is `display_name` | Medium |
| No collection stacking / CardViewer documentation | Medium |
| No rendering layer order or asset pipeline docs | Medium |

### docs/ROADMAP.md

| Issue | Severity |
|-------|----------|
| Phases 4–5 marked incomplete | High |
| No record of visual systems, Card Viewer, module split | High |
| Version targets stale (v0.1.0 = current) | Medium |
| Last updated 2026-07-08 | Low |

### TODO.md / DEVELOPMENT.md

| Issue | Severity |
|-------|----------|
| Files did not exist | High |

### CONTRIBUTING.md

| Issue | Severity |
|-------|----------|
| Missing CardVisualLibrary / pack pool rules | Medium |
| `resources/` still described as "future" | Medium |

### CHANGELOG.md

| Issue | Severity |
|-------|----------|
| Stops at v0.1.0 / Phase 3 | Medium (not updated — doc task did not request version bump) |

---

## 2. Files Updated

| File | Action |
|------|--------|
| `README.md` | Rewritten — features, game loop, architecture, structure, pipeline |
| `docs/ARCHITECTURE.md` | Rewritten — modular systems, rendering, pack/collection docs |
| `docs/ROADMAP.md` | Rewritten — Completed / Upcoming sections |
| `docs/DEVELOPMENT.md` | **Created** — setup, content workflow, coding rules |
| `TODO.md` | **Created** — active work items only |
| `CONTRIBUTING.md` | Updated — module boundaries, folder table, new doc links |
| `docs/DOCUMENTATION_REPORT.md` | **Created** — this report |

---

## 3. Outdated Documentation Removed

References eliminated or rewritten across all docs:

- Card Inspector (replaced by Card Viewer)
- Monolithic CardScene responsibilities
- "Placeholder labels" / text-based card faces as primary rendering
- Procedural frames as default (now PNG-primary with StyleBox fallback)
- Desktop-first UI assumptions
- Old animation flow (FlipPivot position lift)
- `PackGenerator.generate_pack(CardDatabase)` without PackConfig
- Hardcoded catalog / "future .tres" for cards and packs
- Phase 4–5 as upcoming work
- CardVisualLibrary as temporary placeholder-only system

---

## 4. New Diagrams Added

### ARCHITECTURE.md

- System overview (UI → Manager → Logic → Data)
- Primary game loop flow
- CardScene module tree
- PackOpening module tree
- Collection architecture (storage vs presentation)
- Front-face rendering layer order
- Back-face rendering layer order
- Pack generation pipeline
- Asset folder layout

### README.md

- Game loop (text flow)
- CardScene module tree
- PackOpening module tree
- Pack generation pipeline
- Rendering order summary

---

## 5. Remaining TODOs

Tracked in [TODO.md](../TODO.md):

| Priority | Item |
|----------|------|
| High | Save System (Phase 6) |
| Medium | Pack selection UI on main menu |
| Medium | Collection search/filter hooks |
| Medium | README screenshots |
| Low | Shop, variant texture pipeline, CardViewer metadata, game integrations |

---

## 6. Documentation Coverage Status

| Area | Status |
|------|--------|
| Architecture (modular CardScene / PackOpening) | ✅ Complete |
| Implemented features list | ✅ Complete |
| Game loop | ✅ Complete |
| Asset pipeline / CardVisualLibrary | ✅ Complete |
| Pack system (PackConfig → filter → generate) | ✅ Complete |
| Collection (storage vs stacking) | ✅ Complete |
| Card rendering order | ✅ Complete |
| Roadmap (Completed / Upcoming) | ✅ Complete |
| Development setup guide | ✅ Complete |
| Active TODO tracking | ✅ Complete |
| Screenshots | ⚠️ Placeholder paths only (no images captured) |
| CHANGELOG for v0.2.0 | ⚠️ Not updated (out of scope unless requested) |
| `assets/variants/` and `assets/glows/` folders | ⚠️ Documented as future-ready; folders not created (code-only paths in CardVisualLibrary) |

---

## 7. Success Criteria Checklist

| Criterion | Met |
|-----------|-----|
| Documentation matches current repository | ✅ |
| No stale architecture diagrams remain | ✅ |
| No references to removed systems | ✅ |
| README accurately represents the project | ✅ |
| ROADMAP reflects completed work | ✅ |
| ARCHITECTURE reflects modular CardScene and PackOpening | ✅ |
| Zero gameplay or code behavior modifications | ✅ |

---

*Report generated as part of Issue F2 — Documentation Behind Code.*
