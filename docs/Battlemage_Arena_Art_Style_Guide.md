# Battlemage Arena — Art Style & Asset Production Guide

**Version:** 1.0 (proposed art direction, October 2026)  
**Status:** Art-direction specification for autonomous Godot/Aseprite agents; not an assertion that the repository already contains these assets.  
**Project:** [BattlemageV3](https://github.com/franklinjr12/BattlemageV3), branch `master` at time of research.  
**Companion:** `Battlemage_Arena_Reference_Spritesheet.png` — a *visual mood/reference atlas*, **not** a slicing-ready sprite sheet.  
**Authoritative gameplay source:** Existing Godot scripts and Resources. Do not rewrite combat behavior merely to match reference imagery.

> **Art-direction sentence:** Battlemage Arena is a modern, highly readable top-down pixel-art fantasy where expressive battlemages exchange spectacular, geometrically distinctive elemental spells across expansive, weathered, mysteriously luminous arenas. The environment provides rich atmosphere; **magic owns the visual spotlight**.

---

## 1. Goals, Constraints, and Nonnegotiable Decisions

### 1.1 Desired player experience

The game should be instantly recognizable in an uncaptioned gameplay screenshot: a small-but-expressive battlemage, visually distinct opponents, ancient arena stonework, brightly differentiated spells, and crisp UI. Magic should look *crafted, physical, colorful, and powerful* rather than like blurred glowing circles. Even heavy combat should remain easy to parse.

The style combines **Astral Ascent** (expressive frame animation, layered elemental spectacle, vibrant accents), **Wizard of Legend** (top-down combat readability, geometric spell identities, disciplined foreground/background contrast), **Children of Morta** (responsive magical lighting and satisfying attack impacts), **Stoneshard** (believable weathered materials and architecture), and selectively **Hero Siege** (large AoE scale). Inspiration is structural, never direct duplication of copyrighted sprites, characters, UI, or distinctive spell artwork.

### 1.2 Locked user decisions

1. **Top-down 2D pixel art.** Keep the Godot game's current mouse-directed combat perspective, not isometric camera, sidescroller, or faux 3D.
2. **The arena is much larger than the screen.** Use a following camera; never zoom out to frame the entire circular arena during ordinary play. Its boundary is discovered by moving across the world.
3. **Combat HUD top-left:** player **name, level, health, dodge charges/recharge, and casting name/progress** share one coherent panel, anchored to the viewport.
4. **Four skill slots Q / W / E / R** remain at **bottom-center**, visually close to the previous concepts: individual square magical icons, distinct school accents, obvious selection and cooldown feedback.
5. **No permanent combat guide** or right-side tutorial panel. Teaching appears contextually, transiently, or in a pause/help screen only when intentionally requested.
6. **No game-name watermark or wordmark during gameplay.** The title/logo belongs on title/menu/marketing screens; a small encounter label is allowed during battle.
7. **No mana bar.** The current demo has no mana mechanic. Do not add mana gauges or imply mana costs. Current HP, dodge charges, spell cooldowns and cast progress are authoritative.
8. **Spectacular spells are high priority.** Fire, Ice, Earth, Air all deserve convincing silhouettes, staged animations, glows, particles, readable impact, and elemental personality.
9. **Player combat area is obstacle-free** in the current game. Architecture, pillars, banners, vegetation and decorative statues belong at the arena perimeter or non-collidable dressing areas unless gameplay scope explicitly changes.
10. **These are art targets, not mandatory gameplay redesigns.** Preserve existing encounters, statuses, range geometry and enemy behavior unless separately approved.

### 1.3 Five measurable style pillars

| Pillar | What an agent must deliver | Failure condition |
|---|---|---|
| Spell-first spectacle | Each spell visually communicates element, shape, power, timing and impact | Effects are uniform tinted blobs or hard to distinguish |
| Combat legibility | At native gameplay scale, player, enemies, hit areas and cooldown state read immediately | Background and FX hide active hazards or characters |
| Modern pixel craft | Clean clusters, clear silhouettes, controlled values, consistent edge shading | Random noise, inconsistent pixel density, blurry scaling |
| Atmospheric arenas | Handcrafted-looking stones, ruins, ritual motifs and believable materials | Repetitive generic floor or busy center clutter |
| Physical game feel | Cast anticipation, release, target reaction and dissipation have purposeful timing | FX lag gameplay events or lack hit confirmation |

---

## 2. Rendering Model, Camera, Scale and Layering

### 2.1 Current implementation (verified in repository)

- Godot **4.x** project (`project.godot` currently declares 4.7/GL Compatibility); viewport **1280×800**, `canvas_items` stretch, nearest filtering, 2D transform pixel snapping.
- Current stage logic: `scripts/combat/arena.gd`, `CENTER = Vector2(640,399)`, `RADIUS = 293`. **That small radius is a legacy demo value and must be changed** for the agreed enlarged arena.
- Arena art is currently procedurally drawn by `scripts/effects/arena_art.gd`, with a central sigil, paving, rings, lamps, four-school banners and surrounding stonework.
- Existing actors use `AnimatedSprite2D`: **48×48 cells**, four columns, five animation rows (idle, move, cast, hurt, death); see `scripts/effects/fighter_sprite.gd`.
- Existing spell FX use **32×32 cells** and four animation frames; see `scripts/effects/spell_visual.gd`.
- Combat HUD currently spreads across left / right / bottom; **new design consolidates player status on top-left and eliminates right-side guide**; see `scripts/ui/main.gd`.
- Target previews and actual hit tests are shared through `scripts/combat/spell_geometry.gd`; preserve that relationship.

**Important:** The new sizes below are recommended *migration targets* and are not current atlas dimensions. Update consuming scripts and automated tests when adopting them.

### 2.2 Proposed world scale

- **Gameplay viewport:** keep 1280×800 reference frame initially; support other aspect ratios through screen-space anchors and containers.
- **Arena:** circular playable world, proposed **radius 1,200–1,600 Godot world units** (prototype at 1,400); physical diameter **2,400–3,200**, materially larger than viewport. Final radius must be validated against traversal speed, spell reach, and encounter pacing.
- **Camera:** `Camera2D` follows player; do not fit entire arena. Player stays near central gameplay region, optionally with **small, capped cursor-direction look-ahead** (0–90 world units after playtesting). Smooth movement gently without producing blurry subpixel sprites; choose snapped camera offsets or appropriate integer rasterization.
- **Camera/world origin:** favor a logical world-space center (for example `Vector2.ZERO`) in the migration, but do not silently alter encounter spawn arrangements. Transform all spawn positions and bounds coherently.
- **Boundary:** visible only near the arena's edge. Give the boundary an unmistakable rim and a visually distinct non-walkable outside, but never allow it to fill the full camera by default.
- **Content outside boundary:** atmospheric facades, lamps, spectator tiers, columns, decorations and void/background continue past the rim so a camera near the edge never reveals unpainted space.
- **Rendering:** prefer `TileMapLayer` and/or batched static chunks for repeated ground; use separate layers for animated props and FX. Use `y_sort_enabled` where actor/object overlap needs sorting.

### 2.3 Z-order convention (visual, not hardcoded engine indices)

1. Distant atmosphere / void beneath arena.
2. Large distant ruins, cliff/arena perimeter, static back props.
3. Playable ground tiles, stains, cracks, engravings, embedded rune designs.
4. Ground-anchored telegraphs and persistent area hazards (below character feet where possible).
5. Soft contact shadows, dropped ground particles.
6. Actors, enemies, tall nearby props (Y-sort where applicable).
7. Projectiles, spell bodies, hit sparks, aerial particles.
8. Brief bloom/light overlays and impact flashes, **never covering critical telegraph boundaries**.
9. Floating combat numbers/status markers.
10. Screen-space HUD; pause, tooltips and modal UI above it.

**Rule:** Decorative FX may be additive; collision/target information must be opaque enough and drawn at a reliably visible depth.

---

## 3. Pixel Art Technical Standard

### 3.1 Pixel language

Use deliberate clusters (2–6 px masses at source scale), simplified highlights and controlled contour shading. Prioritize big shape → mid-level construction → tiny signature detail. Make edge colors relate to the material, not universal pitch-black outlines; nearly black separation is acceptable in darkest areas. Avoid random 1-pixel speckling, indiscriminate checkerboard dithering, over-detailed textures and smoothing filters on the pixel layers.

- Pixel edges **nearest-neighbor**; no bilinear/bicubic interpolation on source sprites.
- Pure authored sprite layers should generally have **binary or artist-controlled alpha**, without unintended antialias halos. Soft alpha is allowed on separate lighting/VFX overlay layers.
- Match a consistent notional world pixel density at runtime. Avoid one actor using huge 8-pixel blocks beside another with ultra-fine 1-pixel details.
- Use one coherent **top-down three-quarter character construction**: top of head, torso, lower legs and feet visible; no isometric diamond floor geometry.
- For assets, use a consistent **upper-left/front light direction** for painted highlights; dynamic spell light may override it briefly.
- For each sprite test at **100% gameplay scale**, not only at zoomed Aseprite editor magnification.

### 3.2 Recommended source canvas sizes (targets)

| Asset | Suggested source cell/canvas | Visible drawing | Export rule |
|---|---|---|---|
| Standard player / rival mage | **64×64 px** per animation frame | ~34–46 px body height, enough empty perimeter for motion | Uniform 64×64 frames, stable foot anchor |
| Small creature (skitter, wisp, spitter) | 48×48 or 64×64 | ~24–40 px | Use 64×64 when consistency is easier |
| Medium creature (hound) | 64×64 or 80×80 | ~34–52 px | Height can differ; preserve world scale |
| Golem, champion and large elite | **96×96** or **128×128** | ~65–90 px | Consistent pivot and collision alignment |
| Base projectile artwork | 32×32, 48×48 or 64×64 | clear center + trail silhouette | Particle trails managed separately |
| Effect animation clip | 64×64 / 128×128 / 192×192 | dependent on actual spell range | Frames fit visual, not damage radius |
| Skill icon | **48×48** art in **56×56** slot (can export 48×48) | strong icon motif | Icon and key label are separate elements |
| Status icon | 16×16 or 24×24 | clear symbolic silhouette | Keep readable at 16–20 on HUD |
| Inventory/gear icon | 32×32 or 48×48 | single centered item | Transparent background |
| Small environment tile | **32×32** | muted surface detail | Repeatable seamless seams where needed |
| Large modular tile / decorative prop | 64×64 / 128×128+ | high detail outside active floor | Transparent sprites or tile chunks |
| Nine-slice UI panels | modular, e.g. 32×32 corner source | 4–8px corner/border regions | Prefer Godot `NinePatchRect` / Theme |
| Portrait / class selection | 96×96 or 128×128 | expressive higher-resolution head/shoulders | Same materials/outfit as game sprite |

These sizes are guidance, not an instruction to upscale the current 48×48 and 32×32 sheets with interpolation. **Redraw at target pixel density** if migrating. A first-pass style validation may intentionally keep existing dimensions until game feel is established.

### 3.3 Pivots, grids, and files

- Every actor frame must share the same canvas and **feet anchor** (bottom-center, consistent logical offset). Move hair/capes through animation, not the sprite's origin.
- For directional animation: current project horizontally flips a sprite. Ship a visually coherent left/right solution first; add front/back directions only if clearly needed and explicitly approved. If building 4-direction sets, keep names and frame order uniform.
- Export actor sequences as either separate state PNG strips (`actor_player_idle.png`) or one documented sprite sheet plus generated frame metadata; never make an agent infer slicing positions from a moodboard.
- Source formats: layered `.ase`/`.aseprite` with tags; exported `.png` plus Aseprite `.json` frame/tags metadata. Keep one canonical editable source per asset.
- Naming: `actor_player_*`, `enemy_hound_*`, `spell_fireball_*`, `icon_spell_fireball`, `ui_skill_slot_*`, `tile_arena_*`, `prop_*`, `fx_hit_fire_*`.

---

## 4. Palette and Color Semantics

### 4.1 Base palette (proposal; adjust against actual scene)

| Token | Proposed HEX | Usage |
|---|---|---|
| `ink_900` | `#0A111C` | Deepest outlines, void, UI backing |
| `ink_800` | `#101C2B` | UI panels, outside-arena darkness |
| `slate_700` | `#273644` | Floor recess, cold shadow |
| `slate_600` | `#344956` | Main blue-stone arena floor |
| `slate_500` | `#526674` | Tile midlights, carved edge highlights |
| `stone_warm` | `#877961` | Worn sandstone accents, border masonry |
| `sand_light` | `#BAA681` | Sparing upper-edge light |
| `antique_gold` | `#D9BC80` | Ritual ornaments, focus borders, rare rewards |
| `text_main` | `#E9E9E1` | Legible UI text |
| `text_muted` | `#A2B1BF` | Secondary labels |
| `danger_ui` | `#EF7778` | Enemy danger, invalid targeting, HP damage |
| `healing_ui` | `#75D7A1` | Health/recovery when present |

### 4.2 Elemental ramps

Keep the repository's existing color families as **semantic anchors**: Fire `#F59A63`, Ice `#83D5F5`, Earth `#D4BA7A`, Air `#9DE3C5`. Gradients below are *separate pixel ramp colors* (not blurry interpolated overlays).

| School | Shadow / body / highlight / hot core | Shape | Motion |
|---|---|---|---|
| **Fire** | `#9C382D` / `#E96B3F` / `#F59A63` / `#FFE6A0` | fractured flames, jagged tongues, embers | expanding, aggressive, turbulent |
| **Ice** | `#286D9B` / `#4DABDD` / `#83D5F5` / `#ECFAFF` | crystals, lances, sixfold cracks | precise, angular, briefly suspended |
| **Earth** | `#584C44` / `#897154` / `#D4BA7A` / `#FFF0C0` | cubes, shards, slabs, dusty fractures | weighted, ascending, crumbling |
| **Air** | `#287D7B` / `#55B7AE` / `#9DE3C5` / `#E4FFF0` | sweeps, ribbons, crescent blades, spirals | flowing, fast, circular |

The **core/silhouette**, not color alone, must distinguish spells. Test school identification in grayscale. Avoid five unrelated visual languages within one school. Reserve unusual purples/golds for arena runes, boss mechanics or rare modifiers; **they are not additional playable schools** in the current roster.

### 4.3 Value and saturation discipline

- Playable floor: medium-low value contrast, subdued saturation, repetitive accents reduced.
- Actors/enemies: distinct mid-high local contrast, saturated costume accents at focus areas.
- Ordinary spells: saturated body, small near-white cores; occasional highlights.
- Ultimate/boss spells: more screen coverage, increased local contrast and particle density, but clear negative space around actors/telegraphs.
- HUD: dark semi-opaque backing, readable text, restrained gold. Health color and enemy warning color must not be interchangeable.
- Show combat in grayscale, at 50% preview size, against both floor and perimeter; essentials remain readable.

---

## 5. Characters, Actors and Enemies

### 5.1 Battlemage player

A recognizable **wand/staff-and-mantle caster** with charming stylization, slightly exaggerated head/hair/hood silhouette, sturdy readable boots and hands, visible cast pose. Not ultra-chibi; not realistic adult anatomical proportions. In a 64×64 cell, avoid more than 2–3 costume accents and 3–4 major cloth planes. Default outfit may be stone-blue/ink with a customizable mantle accent; **appearance tint must survive existing `GameState.run.appearance` selections** (Moonstone blue, Ember orange, Sunworn gold, Verdant green). Spell school is not permanently tied to the robe's color because the player equips any school's spells.

Key silhouette: broad or distinctive mantle shoulders, narrow waist, readable sleeves/hands extended in cast, lightweight staff or focus, one emblematic metallic clasp. In action, body should visually face/aim at opponent; spells emerge from the active casting hand/focus, not a random center-of-body point. Avoid huge cape/hat that obscures enemies or targeting shapes.

### 5.2 Existing opponents — required roster

| Resource ID | Character design direction | Motion/FX identity |
|---|---|---|
| `hound` | low, agile magical beast with pointed muzzle, forward shoulders, bold legs | pounce anticipation, claw trails, dust |
| `skitter` | small angular many-legged creature; instantly distinct from hound | sharp start/stop locomotion, quick twitch |
| `spitter` | squat ranged creature, visibly enlarged mouth/sac and projecting attack origin | swell and recoil before projectile |
| `wisp` | floating core in thin, asymmetrical airy tendrils | hover/pulse, subtle small motes |
| `golem` | bulky stacked stone masses, chunky arms, readable heavy weight | body compression, slab shake, dust |
| `pyromancer` | rival battle caster in warm orange/crimson with flame-shaped mantle edges | ember buildup, obvious casting arm |
| `cryomancer` | rival battle caster in icy blue with crystalline trim and sharp silhouette | crisp frost shimmer before cast |
| `battlemage` | experienced multi-school opponent; balanced neutral gear + luminous focus | multi-school runic flashes; no single school locked |
| `champion` | Aurel, named boss; taller ornate silhouette, crowned/ceremonial mantle and magical barrier motifs | spectacular but legible cast, barrier and phase transition |

Sprites and animations should express **threat/role independent of enemy nameplates**. Boss scale should feel special without inflating collision gameplay arbitrarily. Give each enemy a memorable movement trait; reserve maximum animation complexity for player, rival mages, champion and visually prominent attacks.

### 5.3 Minimum animation contracts

| Clip | Suggested frames | Intent |
|---|---:|---|
| Idle | 4–6 | Slow breathable movement, very low amplitude |
| Move | 6–8 | Clear alternating weight or float rhythm; grounded foot contact |
| Cast anticipation/channel | 4–8 | Hand/focus motion synced to cast-time and release |
| Hit reaction | 2–4 | Immediate recoil, readable flash, quick recovery |
| Dodge/dash | 4–6 | Strong directional smear/trailing cloth; gameplay collision unchanged |
| Death | 6–10 | Recognizable defeat with dissolve or collapse, no distracting screen flash |
| Boss-only: barrier/phase | 4–8 each | Clearly warn change, then settle into combat |

Sprite animation and Godot tween/particle layering may share responsibility. Recommended efficient technique: authored core pixel sprite + runtime positional squash, rotation, few secondary pixel fragments and limited shader flash. **The exact hit frame and release frame must follow gameplay events.** Preserve animation tags in source export. At least one mirrored movement and cast direction must pass visual QA.

### 5.4 Actor readiness at camera scale

Test simultaneously with: a small skitter behind a projectile, a hound beneath a large AoE, a golem during cast wind-up, two rival casters, and player next to the arena wall. If actor silhouettes merge into effects, adjust dark contours, contact shadows, saturation or peak glow, **not** simply player character size.

---

## 6. Spell Visual Language — Full Current Player Catalog

**Authoritative spell IDs, effects and target types are the Resources under `resources/spells/`.** Preserve damage areas and timing through `SpellGeometry`; artwork may extend visually but must not imply a false hitbox. Each spell has **(A) anticipation / preview, (B) primary action, (C) impact or sustain, (D) dissipate**. Projectiles also have a trailing path. Basic spell art is visible without shader glow.

### 6.1 Fire school

| ID | Existing targeting | Distinct visual signature | Impact / sustain |
|---|---|---|---|
| `fireball` | Projectile | Compact ragged orange-yellow core with a bright front and two asymmetrical flame tongues; short detached ember trail | Radial flame burst and outward sparks on hit; red-orange burn specks |
| `flame_lash` | Cone | One whip-like sweeping tongue with forked branches, widening from hand to range end | Fast sideways sweep, curling embers, momentary scorched edge |
| `burning_ground` | Ground / persistent | Ring of heated cracks and inner fire pools rather than an opaque disk | Flickering local flames, embers; clean unmistakable active boundary |
| `combustion` | Ground AoE | Tight implosive orange rune, then jagged outward blast with nearly white flash | Controlled detonation, 2-layer shockwave; visually emphasize consuming Burn stacks |

### 6.2 Ice school

| ID | Existing targeting | Distinct visual signature | Impact / sustain |
|---|---|---|---|
| `ice_spike` | Projectile / pierce | Long pointed crystal lance with faceted core, tiny frost streaks | Narrow splitting shard burst, shards continue to signal pierce |
| `frost_nova` | Self-centered AoE | Hexagonal snow sigil expanding into six broad frost lines | Clear circular freezing perimeter, outward radial ice splinters |
| `ice_barrier` | Self / protective | Half-transparent blue crystalline shells circling the wearer | Stable recognizable shield outline with gentle facet pulse; break shards at expiry |
| `icicle_rain` | Delayed ground / persistent | Ground rune plus descending icicle silhouettes with individual shadows | Staggered needle-like impacts at target circle; preserve tell through the rain |

### 6.3 Earth school

| ID | Existing targeting | Distinct visual signature | Impact / sustain |
|---|---|---|---|
| `stone_fist` | Cone | Heavy block-fist rushing up or forward from the floor | Strong hit frame, dust and fragments; read as close-range heavy punch |
| `stone_guard` | Self / protective | Flat angular slate fragments orbiting torso like plate armor | Stable ochre/stone perimeter; dust flecks when absorbing impact |
| `earth_pillar` | Delayed ground | Tight fissure and rising geometric stone spire | Clear warning before rise; then large slab chunks, falling pebbles |
| `tremor` | Self-centered AoE | Expanding jagged concentric fracture arcs centered on caster | Low dust ring, stone shake, distinct terrain impulse without covering floor |

### 6.4 Air school

| ID | Existing targeting | Distinct visual signature | Impact / sustain |
|---|---|---|---|
| `wind_blade` | Directional line | Thin fast crescent or paired crescent edges with negative-space center | Swift trailing cuts, slender impact burst; precise width |
| `gust` | Cone | Broad ribbon wave with layered curved streamlines and detached leaves/dust | Controlled outward fan, light knockback streaks |
| `vortex` | Ground / persistent / pulls | Concentric spiral bands and rotating sparse motes, leaving central actors legible | Persistent clear circular boundary; radial inward flows communicate pull |
| `wind_dash` | Directional / movement | Compressed turquoise swish, afterimage and narrow crescent streak behind player | Short dash trail fades immediately; no illusion of teleport beyond actual movement |

### 6.5 Other existing enemy spell visuals

Existing enemy attacks include `claw`, `hex`, `pounce`, `slam`, and `spit` (see `resources/spells/`). Build them in the same pipeline; do **not** accidentally replace them with elemental player abilities. `hex` may use a sparing violet accent as enemy-specific magic; the presence of violet does not create another playable school.

### 6.6 VFX intensity and timing system

| Tier | Uses | Core effect | Suggested duration envelope |
|---|---|---|---|
| T0: interface | ready/selected, minor status tick | 1–3 subtle glints | 0.08–0.20s |
| T1: normal | fireball, wind blade, basic projectiles | recognizable body + 4–12 particles | 0.15–0.40s impact tail |
| T2: signature | frost nova, vortex, stone fist, flame lash | animated core + 1–2 ring/trail layers + 8–24 particles | 0.3–0.7s release/impact |
| T3: major | combustion, earth pillar, icicle rain, champion | 2–4 distinct staged layers, temporary localized lighting, camera impulse | 0.4–1.2s sequence excluding persistence |

Do not bake game rules or exact duration constants from this artistic table; `SpellData`'s cast/delay/duration is authoritative. Release animation must coincide with `Fighter.execute_spell()`; delayed impact must coincide with effect activation. Early warning begins before damage when `delay` is positive. A full attack sequence uses authored sprite frames plus runtime shaders/particles/tweens, **not** only sprite scale growth.

### 6.7 Hit reactions and combat feedback

- Hit spark color follows attacking element, with a crisp white or pale nucleus and 2–6 directional flecks.
- Damage number rises ~20–32 screen pixels while fading; prioritize readability over large floating text. Critical and heavy hits use increased scale plus a distinct shape, not color alone.
- `burn`: brief orange ember markers / icon; `chill`: frosty flecks / icon; `freeze`: crystalline lock and break effect; `stagger`: short heavy star/fracture; `airborne`: windlift accents; `barrier` / `guard`: shell and shield motifs.
- **Combustion + Burn** receives a short distinctive detonation cue; **heavy + Freeze** receives a visibly different shattering burst. Keep reactions short enough to avoid stacking visual clutter.
- Dodge: crisp directional afterimage, subtle invulnerable shimmer, two HUD charge pips; no mana-like gauge.

### 6.8 Targeting and telegraph clarity

For all target types (`projectile`, `ground`, `cone`, `self_area`, `directional`, `self`):

1. **Player targeting preview:** semi-transparent muted elemental interior with **solid sharp boundary**. Show range-limit ring only when useful, faint enough to avoid covering scene. Aim does not obscure opponents.
2. **Enemy warning:** shape must read as hostile even when cast element is Ice/Air — add **coral warning outline, segmented rhythm, distinct pulse** or warning glyph. Do not recolor the physical spell body entirely red.
3. **Actual damage phase:** brighter inside, readable geometry held through contact. Gameplay hit tests and visual geometry come from the same `SpellGeometry` metrics and `area_scale`.
4. **Sustained hazard:** reduced brightness after initial impact, repeated gentle boundary highlight, no continuous full-opacity blast.
5. **Invalid targeting:** explicit red/coral boundary and UI feedback; valid range remains distinguishable in color-blind view via shape/animation.

Do not use decorative rune diameters as misleading larger-than-hitbox warning areas. Rune ornaments sit inside the actual hit boundary or are clearly noninteractive.

---

## 7. Arenas, Environment, Props and World Atmosphere

### 7.1 World identity

Ancient arenas built by a magical civilization: carved stone, elaborate but restrained celestial/ritual geometry, aged brass, weathered walls, subtle moss and mystical energy embedded beneath seams. Atmospheric without becoming horror/grimdark. Each stage can reuse the same combat floor system with perimeter palettes/themes; biome variations are **optional art expansion, not a request to add levels or obstacles**.

### 7.2 Ground and ring design

- Main combat floor **relatively low-contrast**: bluish slate/charcoal with irregular grout, 32×32 modular stones, occasional 64×64 repairs. Large readable stones, not dense checkerboard noise.
- Distinctive **ritual circles** at limited authored points: low-alpha concentric engravings, hex/triangle marks, four-element cardinal emblems. These must be less visually dominant than spell telegraphs.
- Interior paving variation: 70–80% calm tiles, 15–25% altered/repaired/cracked tiles, ≤5% accent/runic fragments (guideline only, not a random-per-tile law).
- Border: broad masonry rim, clear collision perimeter silhouette, rune insets and torches/banners, modular repetition hidden through alternating props and broken segments.
- Outside edge: distant galleries, archways, banners, floating masonry, roots/lichen, spectator shapes if desired. **No gameplay blockers inside** unless mechanics change.
- Player collision, not art sprite edges, defines traversable area. Decorative stone height must not change targeting validation.

### 7.3 Prop visual library

Required reusable props: floor stones (clean/worn/cracked/mossy), rune circle segments, border inner/outer/curved corners, four school banners, torch pedestal (unlit/lit), stone columns (whole/broken), arch fragment, stone rubble, chained brazier, arcane crystal pedestal, spectator seats/tiers, optional vegetation accents. Provide Y-sorted vertical prop bodies and explicit collision flags. Foreground arches shouldn't hide players; fade or refrain from overlapping play space.

### 7.4 Lighting rules

- Neutral ambient light cool and restrained; tiles remain distinguishable without FX.
- Subtle warm torches and sparse colored ritual lights at perimeter; do not overlight floor.
- Moving spells may emit **short-range transient `PointLight2D`**, with strength proportional to spell size; limit simultaneous dynamic lights using a pool/budget.
- Spell glows use separate additive layers or compatible `CanvasItemMaterial`, with controllable alpha. Pixel core stays crisp under bloom.
- No large screen-wide washes for ordinary actions. Camera shake used only on meaningful heavy impacts, accessibility-adjustable; retain current settings integration.
- Beware Godot GL Compatibility lighting differences; verify using the actual renderer and export presets, not screenshots from another pipeline.

---

## 8. Combat HUD: Final Placement and Information Hierarchy

### 8.1 Reference screen at 1280×800

| Region | Contents | Rule |
|---|---|---|
| **Top-left** (suggested `x=20,y=16`, width **300–350**) | Small portrait/school-neutral crest; **player name + Lv** on line 1; **HP bar + numeric value** on line 2; **two dodge charge pips** + recharge states on line 3; **casting spell name and cast progress bar** on line 4 when casting (or short `READY` neutral state) | All core player status is here; no separate left-middle cast box |
| **Top-center** | Small trial name + wave/phase; during duel/champion add opponent name and health as compact boss bar below | Avoid persistent oversized header; never show game name |
| **Bottom-center** (safe from edge) | Four square/slightly rectangular icon slots **Q W E R**, school accent, selection frame, cooldown dim and time | Visually inspired by prior concepts, not the old expanded text guide |
| **Optional near actor** | Small statuses / enemy health when gameplay benefits | Avoid duplicate player status HUD blocks |
| **Top-right / right** | **Nothing permanent** by default | No combat guide or debug key instructions |
| **Modals/overlays** | Pause / settings and encounter end | Freeze HUD appropriately; modal receives inputs |

**Compact HUD layout example (not literal text baked into artwork):**

```text
┌─────────────────────────────────┐                 [TRIAL OF EMBERS · WAVE 2/2]
│ [portrait] ASH            LV 4 │
│ ███████████░░ 142 / 180 HP     │
│ DODGE ◆ ◆  (charge timers)     │
│ CASTING · EARTH PILLAR ███░░░  │
└─────────────────────────────────┘



                    [ Q Fireball ][ W Ice Spike ][ E Stone Fist ][ R Wind Dash ]
```

Casting progress appears in the **same top-left HUD**; if no cast is active, either collapse the line or show small `READY` without creating a second overlay. A dodge charge on recharge is hollow/dim, optionally with a small radial sweep; do not swap it for a mana indicator.

### 8.2 Skill slot design

Each button contains (1) a distinct crisp 48×48 icon, (2) 1-character keyboard tag, (3) elemental border accent, (4) dark backing, (5) state animation, (6) cooldown timer when relevant. Place the key in a small bottom-left tab, not over the central icon; put text for spell names into tooltips or short companion labels only when readability permits. Selected state uses crisp gold outline and slight glow; unavailable state dims icon **without removing silhouette**. Preserve clickable interaction and button accessibility.

### 8.3 UI component system

- Panels: dark/navy interior, 1–2 px pixel border, aged-gold corners only on major cards, padding 10–16 px.
- Button states: normal (dark stone/navy), hover (blue-slate + fine gold edge), pressed (depressed/few pixels downward), selected/primary (stronger gold edge), disabled (reduced contrast but readable).
- Tooltip: wide enough for spell name, school, description, key numbers, cooldown, cast time, status; no text cramped inside icon texture.
- HP bar: warm crimson/red with clear pale numeric text and dark backing. Dodge charge pips: icy/neutral diamond pips, no elemental school implication.
- Boss bar: readable from distance, with phase change feedback; can use ceremonial accent but not huge ornate overlay.
- Settings sliders, toggles, dropdowns, checkboxes, scrollbars, dialog close icons and focus rings use a single pixel language.
- UI layout in **Godot `Control` / `Theme` / `NinePatchRect`**, not rasterized screenshot panels with fixed text. All positioning must be responsive, anchored and screen-space.

### 8.4 Font / text treatment

Use licensed redistributable pixel-compatible font(s) as source assets, with clear uppercase headings and a readable sentence-case body face; one family with two sizes/weights is acceptable. **Text in the reference image is concept demonstration only**. Render actual dynamic strings as Godot `Label` / `RichTextLabel` and keep fonts separate from button textures.

Suggested base sizes at 1280×800: 24–30 px title/encounter popup; 17–21 px section/subhead; 14–17 px body; 12–14 px small HUD key/cooldown. Do not rely on 8px text for essential information. Preserve pixel-snap/integer sizing; avoid non-integer viewport transformations that blur text. Use readable contrast in both bright/dark arena zones and with alpha panels.

No permanent gameplay logo; title screen can feature the Battlemage Arena wordmark, but UI component reference atlas need not contain a logo.

---

## 9. Menus and Complete UI Screen Family

The present project has title, creation, antechamber/hub, spell/gear shopping, build/loadout, encounters, combat, reward, level bonuses, completion and pause/settings flows (driven by `scripts/ui/main.gd`). Reskin them as a coherent UI system, retaining functional controls and information hierarchy.

| Screen | Proposed visual composition | Required elements |
|---|---|---|
| Title | dramatic cropped arena environment or spell duel illustration; reserved content panel | Logo **here only**, New / Continue / Settings / Quit |
| Character creation | left visual portrait/model; right readable identity and starter magic choices | name, mantle tint, starter package, confirm |
| Hub / antechamber | restrained background architecture; centered navigation cards | current progression, spell/gear access, next encounter |
| Spell shop | icon grid by school, large selected info panel | ownership, cost, damage/cooldown/cast/range descriptions |
| Gear shop | themed item silhouettes and rarity hints | item price, effects, equipped status |
| Character & spell loadout | 4 equipped skill slots / gear slots / stats | drag/select interaction, current values, preview |
| Encounter selector | trial cards with art thumbnails, progression and difficulty | Trial of Embers, First Duel, Menagerie, Fourfold Trial, Crown of Ash |
| Combat | clean arena + top-left status + bottom-center skill bar | no combat guide, no game logo, high-contrast telegraphs |
| Reward / level choice | deliberate celebratory gold/rune accents, uncluttered choice cards | XP, gold, bonus choices, confirmation |
| Pause/settings | frosted/dark navy pixel-compatible modal over paused fight | resume, volume, screen, accessibility settings as implemented |
| Completion | distinctive ceremonial visual framing | earned crown, progression outcome, next action |

Keep panels smaller than the available field of view; do not use large opaque decorative images that conceal necessary UI. For each menu, define keyboard/mouse focus, hover, pressed and disabled state assets.

---

## 10. Asset Registry and Visual Sheet Coverage

The companion reference sheet illustrates the **target rendering quality, motif families, materials and visual vocabulary**. It is **not** an exact pixel-grid atlas and may show exploratory variants/extra motifs; production agents must follow the **current content IDs below** rather than adding new elements, mana or encounters seen in an illustration.

### 10.1 Required actor sources

`actor_player`; `enemy_hound`; `enemy_skitter`; `enemy_spitter`; `enemy_wisp`; `enemy_golem`; `enemy_pyromancer`; `enemy_cryomancer`; `enemy_battlemage`; `enemy_champion`.

For each: idle/move/cast/hurt/death; player additionally dodge; for champion barrier/phase where appropriate. Match collision/sprite pivots to `Fighter` setup. Maintain 4 mantle appearance choices for player.

### 10.2 Required spell visuals and UI icons

Exactly 16 player spell IDs (art sprite, 48px icon, release/impact animation, relevant particles, targeting preview and status cue):

```text
Fire:  fireball, flame_lash, burning_ground, combustion
Ice:   ice_spike, frost_nova, ice_barrier, icicle_rain
Earth: stone_fist, stone_guard, earth_pillar, tremor
Air:   wind_blade, gust, vortex, wind_dash
```

Enemy-only spells also need bespoke visuals: `claw`, `hex`, `pounce`, `slam`, `spit`. Use exact registry names for loading and icons. This guide does not replace the full `Content` registry.

### 10.3 Required UI asset families

- `ui_panel_small`, `ui_panel_large`, `ui_modal_frame`, `ui_tooltip_frame`, `ui_portrait_frame` — 9-slice/safe scaling where possible.
- `ui_button_normal`, `_hover`, `_pressed`, `_selected`, `_disabled`, `_focus` — consistent sizes/corners and input feedback.
- `ui_skill_slot_normal`, `_hover`, `_selected`, `_cooldown`, `_unavailable`, `ui_keycap_q/w/e/r` — images should not include spell-specific text.
- `ui_hp_track`, `ui_hp_fill`, `ui_cast_track`, `ui_cast_fill`, `ui_boss_track`, `ui_boss_fill`, `ui_dodge_full`, `ui_dodge_empty`, `ui_dodge_recharging`.
- `ui_checkbox_on/off`, `ui_slider_track/knob`, `ui_toggle_on/off`, `ui_tab_active/inactive`, `ui_scrollbar`, `ui_close`, `ui_pause`, `ui_back`.
- `icon_status_burn`, `_chill`, `_freeze`, `_stagger`, `_airborne`, `_barrier`, `_guard`, `_invulnerable`; `icon_gold`, `icon_xp`, `icon_level`, `icon_health`.
- `icon_gear_*` for each `resources/gear/*.tres`, plus category placeholders if needed.
- Font `.ttf`/`.otf` with redistributable license; all actual numbers, names, labels, and tooltips remain **runtime text**.

### 10.4 Required environment families

- `tile_arena_floor_*`, `tile_floor_crack_*`, `tile_floor_moss_*`, `tile_ritual_*`, `tile_rim_*`, `tile_outside_*`.
- `prop_column_*`, `prop_ruin_*`, `prop_torch_*`, `prop_banner_fire/ice/earth/air`, `prop_crystal_*`, `prop_brazier_*`, `prop_gallery_*`, `prop_rubble_*`.
- `fx_fire_*`, `fx_ice_*`, `fx_earth_*`, `fx_air_*`, `fx_warning_*`, `fx_hit_*`, `fx_dodge_*`, `fx_status_*`.

### 10.5 Machine-readable asset manifest pattern

Add `art/asset_manifest.json` (recommended) or an equivalent structured registry. Example *schema shape*; agents must fill entries per asset rather than assuming the illustration yields importable coordinates:

```json
{
  "schema_version": 1,
  "art_direction_version": "1.0",
  "assets": [
    {
      "id": "actor_player",
      "kind": "actor",
      "source": "art/source/actors/actor_player.aseprite",
      "export": "art/sprites/actors/player.png",
      "frame_size_px": [64, 64],
      "pivot": "feet_center",
      "frame_metadata": "art/sprites/actors/player.json",
      "animations": ["idle", "move", "cast", "hurt", "death", "dodge"],
      "status": "target_not_yet_implemented"
    },
    {
      "id": "spell_fireball",
      "kind": "spell_vfx",
      "source": "art/source/spells/spell_fireball.aseprite",
      "export": "art/sprites/spells/fireball.png",
      "frame_size_px": [64, 64],
      "frame_metadata": "art/sprites/spells/fireball.json",
      "status": "target_not_yet_implemented"
    }
  ]
}
```

This is a **proposal**, not a truthful description of existing sheet dimensions. If migrating to new dimensions, update `FighterSprite.FRAME_SIZE`/`ANIMATIONS`, `SpellVisual.FRAME_SIZE`/`FRAME_COUNT`, and the loaders to use exported metadata; keep game resources loading robust in release builds.

---

## 11. Aseprite Asset Production Workflow

1. Create a layered source file at correct cell size and pixel ratio; set indexed or controlled RGBA palette for pixel body; transparent background for sprites/icons.
2. Layers typically: `construction` (hidden), `shadow/contact`, `base_shapes`, `material_shading`, `highlights`, `details`, `separate_fx` (if authored), `pivot_markers` (metadata/hidden). Use descriptive layer names.
3. Define timeline tags: `idle`, `move`, `cast`, `hurt`, `death`, `dodge`; spell tags may be `anticipate`, `release`, `impact`, `loop`, `end`.
4. Export PNG sheets and frame metadata via Aseprite CLI (`--batch ... --sheet ... --data ... --format json-array` as appropriate to local Aseprite version). Do not assume a generated concept board can be cut into frames.
5. Preserve frame timing. Import/export must retain directions, pivot and tag information. Use structured or explicit frame ordering to avoid silent animation mismatch.
6. Produce character preview contact sheets (transparent and neutral-floor variants) and animated GIF/APNG previews for human review. Do not embed preview textures in the shipped runtime unless needed.
7. Compare source/exports pixel-for-pixel to catch flattened alpha, accidental smoothing, off-grid sprites or color drift.

**Avoid:** using AI-generated infographic words as a production bitmap font. Pixel lettering in concept art is often inconsistent. Choose a proper licensed font, test glyph coverage and use it through Godot's font system.

### 11.1 Suggested source tree

```text
art/
  source/
    actors/         (*.aseprite)
    spells/         (*.aseprite)
    icons/          (*.aseprite)
    tiles/          (*.aseprite)
    props/          (*.aseprite)
    ui/             (*.aseprite)
  sprites/
    actors/         (*.png, *.json)
    spells/         (*.png, *.json)
    icons/          (*.png)
    tiles/          (*.png)
    props/          (*.png)
    ui/             (*.png)
  fonts/            (*.ttf, *.otf; license included)
  asset_manifest.json
```

The source tree is proposed. The existing project paths must be inspected before migration; avoid breaking Godot resource references by moving files without updating references.

---

## 12. Godot Runtime Integration and Performance

### 12.1 Maintain authoritative combat logic

- Do not alter `resources/spells/*.tres` damage, range, durations or statuses just to fit an effect animation.
- Preserve `SpellGeometry` targeting / damage coordination. VFX reads those values to set boundaries; it never computes its own gameplay collision.
- Use `AnimatedSprite2D` / `SpriteFrames` for pixel layers, `GPUParticles2D` or `CPUParticles2D` as appropriate for very small pixel particles, `PointLight2D` for selective ephemeral lights, `CanvasItem`/shaders for state flashes and dissolves.
- Keep component roles split: **logic** (`Fighter`, `SpellEffect`, `SpellProjectile`, `ArenaDirector`) versus **presentation** (`FighterSprite`, `SpellVisual`, `ImpactBurst`, `ArenaArt` and new asset-driven scenes).

### 12.2 Migration of current circular arena to large scrolling world

Suggested implementation plan in engineering terms (not an instruction to silently implement gameplay changes):

1. Convert arena center/world coordinates from viewport-bound assumptions to world-space values; expand radius and spawn logic consistently.
2. Attach/follow a `Camera2D` on the player or an arena scene camera; screen-space HUD remains on a `CanvasLayer`.
3. Replace a single huge per-frame procedural `_draw()` floor where necessary with static `TileMapLayer` / chunk art and perimeter modules. Animating every floor tile every frame is unnecessary.
4. Ensure `get_global_mouse_position()`, world-space destination clamping, cone/line previews, enemy AI, projectiles, spawn formations and out-of-bounds checks work with a moving camera.
5. Prevent light/shader effects leaking beyond the world border in distracting ways; keep outside stage art continuous when camera reaches outer edge.
6. Confirm spells near the boundary reject out-of-bounds targets as before; circle boundary still authoritative in game logic.
7. Do not add collision obstacles or change the combat encounter system without a new gameplay specification.

### 12.3 VFX budgets (starting targets, tune after profiling)

- Normal impact: ~4–12 small pixel particles; signature: ~8–24; major impact: ~20–50 spread across staged subeffects.
- Limit simultaneous temporary dynamic light nodes (initially target 4–8 visible strongest spell lights; gracefully prioritize by distance/importance).
- Pool/reuse short-lived effect nodes and particles where measurements justify it, without introducing premature complexity.
- Avoid full-screen shaders for ordinary spells; keep high-cost distortion exceptionally rare and optional.
- Have a `reduced_effects`/low FX mode design possibility for lower-end GPUs and visual accessibility, even if actual option is deferred.
- Profile the official **1280×800** viewport and worst-case 5-enemy Menagerie multi-spell scene; do not claim a fixed performance target without device data.

### 12.4 Accessibility and presentation checks

- Ensure status and danger use shape + timing/line style, not only school color.
- Keep camera shake togglable (integrate current setting), avoid repeated high-luminance full-frame flashes.
- Keep meaningful text legible at native resolution and with UI scale controls.
- Do not let player glow visually merge into hostile telegraphs.
- Validate hover/click/focus feedback for mouse-only and keyboard interactions where supported.

---

## 13. Agent Work Contract: Definition of Done

Any autonomous agent touching visual assets must document **source files created, exports generated, game scenes/scripts changed, asset IDs covered, and tests run**. Agent must not claim to have implemented assets simply because a concept image was produced. Each deliverable must retain a reproducible Aseprite source and an importable Godot resource with exact dimensions.

### 13.1 Asset-level acceptance checklist

- [ ] Correct asset ID and exact slot in `Content`/resource references.
- [ ] Actual Aseprite source file exists and exported PNG/metadata is reproducible.
- [ ] Pixel edges are clean; no accidental antialias halo.
- [ ] Frame grids / tags / pivots follow source specification.
- [ ] Sprite silhouette remains distinct at native size against actual floor tiles.
- [ ] Animation event sync respects cast/delay/hit gameplay events.
- [ ] FX uses only the prescribed school language or documented enemy-specific motif.
- [ ] Telegraph boundary matches real effect area, including area modifiers.
- [ ] Full-health, low-health, cooldown, disabled and selected UI states verified where applicable.
- [ ] No right-side combat guide, no combat logo, no mana bar, no permanently zoomed-out camera.
- [ ] Acceptance screenshot and (when animated) short recording/gif captured from **running Godot**; not an imagined screenshot.
- [ ] All relevant existing tests pass, plus explicit visual review at 1280×800.

### 13.2 Automatic validation scripts to add

Asset validators should examine transparent-border contamination, dimensions, expected animation counts/tags, names/IDs against Content registry, supported formats, and missing sprite references. Run smoke renders for normal battle, rival duel and champion; take fixed-seed screenshots with character positions, three simultaneous elemental skills, a selected targeting preview, and an enemy warning visible. Include a worst-case particle/performance scenario. **Computer vision comparison is advisory**, not a substitute for author/playtester judgment.

### 13.3 Ordered autonomous-agent tasks

The following are **independent work packages**. Agents must complete acceptance criteria for a package before representing it as finished.

## TASK-001 — Establish Shared Art Infrastructure

### Goal
Create robust common source/export/manifest conventions and pixel-perfect rendering baseline.

### Requirements
- Add palette/tokens, Aseprite CLI export automation and manifest validation.
- Preserve project resource references until an explicit migration maps old → new.
- Select, verify and license a suitable pixel-readable font.

### Acceptance Criteria
- [ ] A sample actor, icon, UI component and FX import at precise sizes without blurring.
- [ ] Missing/incorrect IDs and frame grids fail validation.
- [ ] Source Aseprite files, exports and licenses are tracked.

## TASK-002 — Expand the Arena and Implement Following Camera

### Goal
Move from a whole-arena viewport to a large scrollable world while keeping combat semantics.

### Requirements
- Expand logical circle radius (prototype 1,400 world units), update placements/center assumptions coherently.
- Add player-following camera, pixel stability and world-space mouse aiming.
- Ensure edges/outside set-dressing, spawn waves and boundary checks work in large space.

### Acceptance Criteria
- [ ] Full arena does **not** fit in a normal gameplay camera.
- [ ] Movement, targeting, dodging and hostile AI still work near center and rim.
- [ ] No blank void appears when player reaches boundary; no accidental obstacles added.

## TASK-003 — Build Environment Tile and Prop Library

### Goal
Replace purely procedural placeholder appearance with coherent weathered-arcane art.

### Requirements
- Create calm tiles, rune variants, rim modules, school banners, stone architecture and lights.
- Use repeatable chunk/tile composition with consistent shadows and collision flags.
- Reserve play area for combat; dramatic props sit outside the playable ring.

### Acceptance Criteria
- [ ] Expanded arena visually tiles without obvious repeating patterns or seams.
- [ ] Gameplay center is lower contrast than actor/spell FX.
- [ ] Art does not introduce collision blockers or misleading ground hazards.

## TASK-004 — Redesign the Player and Enemy Actors

### Goal
Implement a cohesive 2D actor family with readable roles and expressive animation.

### Requirements
- Produce player mantle variations plus all nine existing opponents.
- Author required animation tags, pivots, hurt and death; player dodge; champion special visual states.
- Synchronize cast and hit visuals with runtime events.

### Acceptance Criteria
- [ ] Each actor is legible in idle, motion, cast and hurt at gameplay scale.
- [ ] Character assets import and animate without anchor drifting or blurry resampling.
- [ ] All existing combatant IDs retain functional runtime presentation.

## TASK-005 — Create All Four Schools' Spell and Status FX

### Goal
Give 16 player spells and five enemy-only spells distinct motion, silhouettes and material reactions.

### Requirements
- Deliver icons, authored animation and runtime VFX layers for every spell ID.
- Implement targeting-preview variants, hits, sustained zones, status icons, elemental combo reactions.
- Use selective dynamic lighting and sane particle budgets.

### Acceptance Criteria
- [ ] Every spell visually identifies its school and collision geometry.
- [ ] Damage areas and cast/delay timing still match Resources and `SpellGeometry`.
- [ ] Simultaneous fire/ice/earth/air actions do not hide player or enemy warnings.

## TASK-006 — Consolidate Combat HUD

### Goal
Implement agreed-screen HUD with top-left player status and bottom-center skills.

### Requirements
- Relocate name, level, HP, dodge pips, casting name/progress into top-left fixed panel.
- Keep Q/W/E/R bar bottom-center, with exact icons and selected/cooldown states.
- Remove permanent combat guide and gameplay wordmark; show concise top-center trial/boss status.

### Acceptance Criteria
- [ ] All five player-status categories are visible **together at top-left**.
- [ ] No mana bar, right combat guide or title/logo in combat.
- [ ] HUD remains correctly anchored as camera scrolls and when UI scale changes.

## TASK-007 — Implement the Menu/UI Component Kit

### Goal
Unify panels, buttons, text, tooltips, bars and current menus under the same art direction.

### Requirements
- Define Godot `Theme`/9-slice assets and all interaction states.
- Reskin title, creation, hub, shop, loadout, encounter selection, pause/settings, rewards, level bonuses and completion.
- Use actual Godot text rather than baked screenshot text.

### Acceptance Criteria
- [ ] Every current screen remains usable with legible type and responsive layouts.
- [ ] Hover, focus, pressed, selected and disabled states are distinguishable.
- [ ] Asset image borders scale cleanly without pixel distortion.

## TASK-008 — Integration, Performance and Art Consistency QA

### Goal
Validate the complete art package in the actual running game.

### Requirements
- Capture normal battle, rival mage duel, Menagerie and champion with varied simultaneous effects.
- Confirm readability in grayscale, motion, screen edges and UI scale variants.
- Run combat and export smoke tests; profile particle/light budget and optional low FX settings.

### Acceptance Criteria
- [ ] No missing resources, broken animations, camera/targeting regressions or visual blockers.
- [ ] All required source files/exports/manifest entries are present and reproducible.
- [ ] Screenshots and brief animated captures evidence actual Godot rendering and passes.

---

## 14. Detailed Visual QA Scenarios

**Capture A — Everyday Fire/Ice encounter:** player left-of-center casts Fireball; Ice Spike pierces a second enemy; hound approaches through an active Burning Ground; HUD status visible. Verify distinct spell bodies, no false collision radius and crisp player silhouette.

**Capture B — Multi-school chaos:** Earth Pillar anticipation, Wind Blade traveling, Vortex pulling two enemies, Chill/Freeze/Heavy interaction. Confirm you can read windups, character positions, charge states, damage numbers and hazard boundaries with all effects active.

**Capture C — Rival mage duel:** Pyromancer or Cryomancer telegraphs a hostile spell; player selects a cone targeting preview; enemy and player effects visually separable even with similar colors. Validate top-center foe bar where appropriate.

**Capture D — Champion:** Aurel's barrier or phase mechanic appears distinctive; boss-health area and player top-left status do not collide; T3 spell impact is impressive but short-lived; camera remains player-following.

**Capture E — Arena traversal:** travel far beyond initial camera frame to outer ring; inspect edges, props, repeated stones, camera framing and boundary; no zoom-to-fit effect; mouse aiming accurate with camera offset.

**Capture F — HUD and menu:** normal/resized viewports, HP near zero, one dodge depleted, cast in progress, spell selected/on cooldown, pause and shop menus, focus states.

---

## 15. Final Priorities and Rejection Rules

**Spend art effort in this order:** (1) spell silhouettes and impact sequences, (2) combat readability and HUD, (3) player/rival/champion animation, (4) high-quality arena flooring and edge architecture, (5) complete creature set, (6) menu polish, (7) optional ambience. Never sacrifice combat clarity for ornamental detail.

**Reject a proposed asset if:** it resembles a direct copy of the references; it introduces an unapproved magic school or mana mechanic; it contains high-frequency noise; it requires players to infer hitboxes from a misleading glow; it blocks reading damage or telegraphs; it changes game geometry without game-design approval; or it exists only as a rendered concept image with no clean Aseprite source and importable Godot export.

**Reference hierarchy:** (1) this guide for art direction; (2) existing repository Resources/scripts for actual gameplay content and mechanics; (3) companion reference sheet for imagery/motifs; (4) running Godot captures for validation. In conflicts involving gameplay IDs/mechanics, **code wins**; in conflicts involving visuals/layout, **this approved guide wins**; unapproved illustrative content is discarded.

---

## Appendix A — Handy Repository Pointers

- `README.md` — exact controls, schools, gameplay and rendering overview.
- `project.godot` — renderer, resolution, pixel filtering, scene entry.
- `scripts/combat/arena.gd` — radius, world center, spawn waves, bounds and draw calls.
- `scripts/effects/arena_art.gd` — current procedural arena floor/ring/banners.
- `scripts/effects/fighter_sprite.gd` — current 48×48 actor animation atlas.
- `scripts/effects/spell_visual.gd` — current 32×32 four-frame spell VFX, particles and additive glow.
- `scripts/combat/spell_geometry.gd` — target shapes and real hitbox math.
- `scripts/combat/fighter.gd`, `scripts/player/player.gd` — cast, movement, dodge and reactions.
- `scripts/ui/main.gd`, `scripts/ui/ui.gd` — HUD/menu composition and theme.
- `resources/spells/`, `resources/enemies/`, `resources/encounters/`, `resources/gear/` — current content roster.
- `docs/screenshots/` — real existing-game screenshot baselines (not references for final polish).

## Appendix B — Companion Image Interpretation

`Battlemage_Arena_Reference_Spritesheet.png` is an **artist-facing reference board** generated to communicate forms, shading, lighting, animation poses, icon shapes and UI component quality. It contains multiple example rows and may depict extra exploratory motifs, text treatments or HUD elements which **are not product requirements**. Always rely on Sections 1, 6, 8 and 10 for the locked four-school roster, no-mana HUD and correct top-left/bottom-center screen layout. **Agents must redraw/re-author production sprites, never attempt to crop the board blindly into shipping gameplay assets.**
