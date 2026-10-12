# Battlemage Arena — Agent Instructions

## Current enemy and menu assets (updated 2026-10-12)

This section supersedes any older dimensions or regeneration notes below. New canonical Aseprite enemy sources are in art/source/enemy_revamp, and menu/gear sources are in art/source/menu_revamp. Regenerate only runtime exports through tools/export_enemy_sources.lua and tools/export_menu_sources.lua; never run older refactor/import/bootstrap scripts over refined hand-authored Aseprite files. Validate the 100 manifest entries with python tools/validate_visual_assets.py and all nine timeline tag ranges with tools/validate_enemy_sources.lua. See docs/revamp_validation/README.md.

The player still uses a 64x64 four-column legacy atlas. Ordinary enemies now have 64x64 cells, and golem/Aurel 96x96, in seven-column sheets with actor-specific clips. The champion includes phase/barrier. scripts/effects/fighter_sprite.gd reads art/source/enemy_revamp JSON metadata. Spell FX use their current 48px cells. Combat rules and save data stay authoritative.


These instructions apply to the entire repository. Keep changes scoped to the requested work and use the actual Godot project as the source of truth for implemented functionality.

## Implementation status and regeneration

Before claiming the visual refactor is complete, read `docs/VISUAL_REFACTOR_IMPLEMENTATION.md`; it documents what has been integrated and what still does **not** meet the final art targets. The current Aseprite sources can be regenerated through the four `tools/refactor_*_assets.lua` scripts using the IGH Aseprite capability. Regeneration overwrites current generated assets; do not run it after manually editing those sources without reviewing the consequences. Validate with `python tools/validate_visual_assets.py`.

## Read first

1. `README.md` — current controls, gameplay, engine setup, architecture, and verification commands.
2. `docs/Battlemage_Arena_Art_Style_Guide.md` — **required art-direction and asset-production specification** for any work on sprites, animation, spell VFX, tiles, camera presentation, HUD, menus, icons, typography, or environmental art. Read the relevant complete sections, not just its overview.
3. `docs/Battlemage_Arena_Reference_Spritesheet.png` — **required visual reference** for the desired artistic quality and motifs when making or reviewing visual changes.
4. Existing `scripts/`, `resources/`, `scenes/`, and `project.godot` — authoritative for **current** IDs, gameplay rules, input handling, hit geometry, and engine constraints.

The new art documents describe the **target direction**, not a claim that the current game has already implemented it. Before changing artwork or related code, compare the target requirements against the running game and relevant scripts.

## Source-of-truth and conflict rules

- **Visual design:** the written art style guide is authoritative; the reference image illustrates intent and must not override the written requirements.
- **Gameplay:** code and typed Godot Resources are authoritative for existing mechanics. Do not change rules, spell IDs, equipment, combat timing, hit areas, enemy behavior, or encounter structure to imitate a concept image unless that change is explicitly requested.
- **Reference image limitations:** the PNG is a **moodboard/reference atlas, not a production spritesheet or slicing grid**. It may contain exploratory school colors, UI text, directions, or resource bars that do not exist in the game. Do not crop it into shipping sprite assets, use its mock text in UI, or treat depicted content as a feature request. Produce independently authored, transparent, correctly aligned sources and exports.
- The five external games named in the guide are inspirations for principles, never sources for copied sprites, effects, logos, fonts, or UI artwork.
- Do not quietly modify either reference file. If requirements conflict, flag the conflict and follow the written guide's stated hierarchy.

## Locked art and UI decisions

- Modern **top-down 2D pixel art**; retain readable pixel clusters, consistent art scale, stable feet/pivots, crisp nearest-neighbor sprites, and restrained floor contrast.
- The playable circular arena must become **much larger than the viewport** with a **player-following Camera2D**. Do not zoom out to fit the entire arena. Preserve obstacle-free gameplay unless the task explicitly changes that constraint.
- During combat, **player name, level, HP, dodge charges/recharge, and casting name/progress belong together at the top-left** as screen-space UI, unaffected by camera movement.
- Keep the four **Q/W/E/R spell slots bottom-center**, with clear icons, selection state, and cooldowns.
- **No mana mechanic or mana bar.** Do not add a permanent combat guide or put the game title on the combat screen.
- The current playable elemental schools are **Fire, Ice, Earth, Air**. The atlas may show other colors/schools as exploratory decoration; do not introduce more gameplay schools from it.
- **Spell visual quality is a priority:** elemental silhouettes, clean casting anticipation, responsive release and impact, staged animation, pixel particles, selective glow/lighting, and legible collision/telegraph boundaries.
- Enemy warnings and real targeting geometry always take precedence over decorative effects. Reuse `scripts/combat/spell_geometry.gd` and the active Resource values for precise ranges and shapes.

## Art-production workflow (Aseprite + Godot)

- Read the guide's technical standards, full spell/actor roster, animation tables, export conventions, HUD rules, and QA scenarios before producing assets.
- Store editable layered `.ase`/`.aseprite` sources and transparent PNG exports with clear animation tags/pivots; add JSON metadata or manifests where needed. Use one documented frame grid per export rather than guessing from the reference board.
- The **current** actor atlases are 48×48 cells and spell FX atlases are 32×32 cells. The guide proposes **larger future targets**, which require updating consuming scripts, frame grids, pivots, and tests rather than merely swapping textures. Do not confuse target sizes with current asset formats.
- For changes to gameplay art, inspect `scripts/effects/fighter_sprite.gd`, `scripts/effects/spell_visual.gd`, `scripts/effects/arena_art.gd`, `scripts/combat/arena.gd`, and the relevant Resource definitions before implementation.
- For visual UI changes, inspect `scripts/ui/main.gd` and `scripts/ui/ui.gd`. Use Godot UI controls, anchors, containers, themes, and nine-slice sprites; do not bake changing text into backgrounds.
- Never overwrite hand-authored work by casually rerunning `tools/generate_content.py`, `tools/create_glyphs.py`, or `tools/generate_combat_art.lua`. Review generated outputs and downstream references before any regeneration.
- Keep performance and accessibility in mind: avoid unlimited particles, large overlapping additive effects, unreadable text, camera shimmer, and expensive per-frame tile drawing. Offer reduced VFX intensity when warranted.

## Implementation and validation expectations

- Follow the ordered agent work packages and acceptance criteria in **Section 13 of the art guide** when asked to implement the visual redesign. Reference documents alone do not mark those tasks as implemented.
- Maintain original controls: right-click movement, Q/W/E/R selection, left-click confirmation, Space dodge, and Escape cancel/pause.
- Keep the distinction between screen-space pointer input and world-space targeting correct when adding a moving camera.
- Check all current enemy types, spell IDs, status effects, and screens through their Resources; never generate only the examples pictured in the atlas.
- Validate art in actual Godot combat, not only in Aseprite or a generated illustration. Check normal creature encounters, rival mage duels, the champion fight, crowded elemental effects, arena traversal, and the relocated HUD.
- Preserve automated tests and release behavior. The commands and export notes in `README.md` are the starting point; run appropriate tests for each change and record what could not be tested.
- Do not claim visual quality, performance, or human playtest acceptance based solely on passing automated tests. See `docs/VALIDATION.md` and `docs/PLAYTEST.md`.

## Useful paths

| Location | Why it matters |
| --- | --- |
| `docs/Battlemage_Arena_Art_Style_Guide.md` | Full, normative art style + asset instructions and acceptance criteria |
| `docs/Battlemage_Arena_Reference_Spritesheet.png` | Visual-only appearance, animation, VFX, UI, and environment references |
| `docs/screenshots/` | Captures of the **current implementation**, not the final art target |
| `scripts/combat/` | Arena bounds, casts, targeting, collision, impact and statuses |
| `scripts/effects/` | Actor sprites, procedural arena, spell and impact presentation |
| `scripts/ui/` | HUD/menu construction and theme |
| `resources/` and `data/content_index.json` | Actual spell, enemy, encounter, and gear registries |
| `tests/` | Deterministic functional and performance checks |

When completing an art-related task, report which guide sections were applied, which source/export files were created or updated, how the result appears in Godot, what was tested, and any deviations from the approved art direction.
