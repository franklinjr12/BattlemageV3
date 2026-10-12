# Battlemage Arena — Visual Refactor Implementation Status

> **2026-10-12 follow-up:** A new enemy-and-menu production pass has now been applied. The older status table below describes the *previous* baseline and is kept as history. For current sprite/menu source paths, test results, real screenshots and candid remaining art-quality differences, read [Enemy and Menu Revamp Validation](revamp_validation/README.md). The complete implementation task definitions are in [the epic](EPIC_enemy_sprites_and_menu_revamp.md).


**Date:** 2026-10-12  
**Scope:** Current, partial implementation of the approved visual refactor epic.  
**Authoritative design:** [Art Style Guide](Battlemage_Arena_Art_Style_Guide.md) and [Visual Reference Spritesheet](Battlemage_Arena_Reference_Spritesheet.png).  
**Status:** **IN PROGRESS**. Do not treat this document or generated Aseprite assets as certification that the full art-direction epic is finished.

## Working changes

| Epic area | Current implementation | Completion assessment |
|---|---|---|
| Art production | Three repeatable Aseprite Lua generation scripts, PNG exports, editable `.aseprite` files, manifest validator | **Partial**: sources exist, but advanced animation tags/layers/metadata still needed |
| Rendering | Crisp nearest-pixel sprite import, 64×64 actor sheets, 48×48 spell sheets, elemental FX and localized `PointLight2D` | **Partial**: further art direction and lighting polish required |
| Arena / camera | Radius 1,400 world units; player-following Camera2D; world-space targeting; boundary visual tested | **Implemented baseline** |
| Environment | Aseprite floor atlas, cached tiled floor image, rune motifs, rim architecture, 8 Aseprite prop families | **Partial**: elaborate scene composition and themed arenas need more art |
| Characters | 10 revised actor Aseprite sheets (player + current enemy roster) with original silhouette details | **Partial**: more detailed, genuinely bespoke per-character animation needed |
| Spell effects | 21 revised Aseprite spell sheets (16 player + 5 enemy-only), 16 UI-linked player icons, new overlay details | **Partial**: distinct staged animation, timing metadata, shader/material art needs refinement |
| Combat HUD | Name, level, HP, dodge, cast, statuses all top-left; 4 spell icons Q/W/E/R bottom-center; right guide removed | **Implemented baseline** |
| UI / menus | Aseprite button skins, six states, status icons, shared themed Godot styleboxes; existing menu flows preserved | **Partial**: menu composition, portraits, licensed pixel font, gear icon overhaul unfinished |
| VFX accessibility | Persisted Spell VFX intensity slider; effect light/particle amounts adjustable | **Implemented baseline**, additional reduced-effects QA warranted |
| Validation | PNG dimensions/source manifest validator, Godot gameplay suite, packed QA export, performance benchmark, real screenshots | **Implemented baseline**, human aesthetic review still necessary |

## Authored and exported assets

All generated assets are original revisions and **must not** be replaced with cropped portions of the reference spritesheet.

- **10 actor sheets**, 64×64 cells × 4 columns × 5 rows, generated from Aseprite and imported by `FighterSprite`.
- **21 spell sheets**, 48×48 cells × 4 frames, generated from Aseprite and imported by `SpellVisual`.
- **21 corresponding icons**, 48×48; **16 player spell Resources** point to the new PNG skill icons.
- **8 stone-floor tiles**, 64×64, assembled into a large cached floor texture.
- **8 arena props** (column, broken column, brazier, crystal, banners for Fire/Ice/Earth/Air).
- **6 button states** and **8 status icons**, wired to their relevant HUD/UI presentation.
- **75 source/export asset pairs** listed in `art/asset_manifest.json`.

Editable source files: `art/source/visual_refactor/*.aseprite`. Runtime PNGs: `art/sprites/` and `art/icons/spells/`.

### Regeneration on the configured Aseprite installation

Run these from the project root using Aseprite 1.3.x batch mode, with `root` set to the absolute project directory (or use the IGH `aseprite.headless.lua` capability):

```text
aseprite -b --script-param root=<ABSOLUTE_PROJECT_ROOT> --script tools/refactor_visual_assets.lua
aseprite -b --script-param root=<ABSOLUTE_PROJECT_ROOT> --script tools/refactor_actor_assets.lua
aseprite -b --script-param root=<ABSOLUTE_PROJECT_ROOT> --script tools/refactor_ui_assets.lua
aseprite -b --script-param root=<ABSOLUTE_PROJECT_ROOT> --script tools/refactor_environment_props.lua
python tools/validate_visual_assets.py
```

These scripts regenerate their corresponding outputs and **overwrite them**. Inspect any authored changes before rerunning.

### Recorded verification

- Godot editor headless import: **success**.
- Godot simulated gameplay suite: **160 checks / 0 failures** (including expanded arena/camera assertions).
- Windows QA export: **success**.
- Exported Windows QA executable: **161 checks / 0 failures**.
- Aseprite export/manifest validation: **75 source/PNG pairs pass**.
- Stress benchmark (Intel UHD Graphics): mean frame approximately **16.88 ms**, peak effects **23**, peak nodes **150**, retained nodes after cleanup **18**. This is machine-specific and not a universal performance guarantee.
- Screenshots generated from real Godot runs:
  - `docs/screenshots/combat.png`
  - `docs/screenshots/magic.png` (simultaneous four-school FX)
  - `docs/screenshots/arena_edge.png` (large arena boundary and camera)
  - `docs/screenshots/title.png` (shared menu styling)

## Remaining work to complete the original epic

1. **Production-quality character illustration and animation:** fully redraw or enhance all actor animation states with deliberate frame tags, direction/pivot metadata, unique action timing, and layered Aseprite sources. Current 64×64 sprites adapt the previous silhouettes rather than fully matching reference quality.
2. **Spell-specific animation and effects:** replace four-frame generic loops with genuinely authored anticipate/release/impact/end sequences, accurate duration/event metadata, more interesting hit reactions, and individually tuned lighting/particles. Current effects are distinguishable, but not yet at Astral Ascent-level spectacle.
3. **Arena composition:** expand the prop and tile library, introduce more designed floor areas, details, rim variety, subtle environmental illumination, and cohesive foreground architecture, while preserving collision-free gameplay.
4. **Full UI art and typography:** restyle individual menu compositions, build player portraits and gear icon families, select and include a properly licensed pixel-readable font, and confirm keyboard focus and UI scale on all screens.
5. **Shared asset pipeline:** add layered Aseprite source discipline, animation tags, exported JSON timing/pivot metadata, per-asset documentation, and deeper manifest consistency checks for linked Godot Resources.
6. **Visual QA and accessibility:** review all five real encounters in motion (not only fixed screenshots), inspect high-VFX and low-VFX readability, verify color-blind hazard distinction and multi-resolution layouts, capture short recordings, and obtain human art-direction approval.

**Next recommended milestone:** Create one genuinely polished vertical slice in running Godot (player, hound, Fireball, Ice Spike, a representative arena section, and HUD) that closely matches the visual guide; approve its sprite detail, scale, animation and glow before applying the refined workflow across the entire asset catalog.

## Implementation constraints

Do not introduce a mana mechanic, new playable elements, gameplay collisions inside the arena, or changes to spell damage/AI solely to align with concept imagery. Follow `AGENTS.md` and the art guide. The original reference spritesheet is **not** production slicing data.
