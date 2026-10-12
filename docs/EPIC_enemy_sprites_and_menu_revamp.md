# Epic: Production-Quality Enemy Sprites and Menu UI — Battlemage Arena

## Context

### Purpose
The prior Battlemage Arena visual refactor is committed. Its arena/camera, spell presentation and combat HUD form a baseline, but the nine enemy sprites and non-combat menus still fall significantly short of the approved visual reference. This epic is a focused art and UI production pass, not a gameplay redesign. Implement with Godot 4.x, Aseprite and IGH; produce real editable assets, integrate them, playtest, and capture actual game footage.

### Source of truth, in priority order
1. docs/Battlemage_Arena_Art_Style_Guide.md — binding visual rules (especially sections 1, 3–5, 8–10, 11, 13–15).
2. Existing typed Godot Resources, Content registry and scripts — binding mechanics, enemy IDs, attack timing, controls, stats and navigation flows.
3. docs/Battlemage_Arena_Reference_Spritesheet.png — visual inspiration for silhouettes, value clusters, effects and menu material language, NOT a slicing-ready sprite sheet.
4. docs/VISUAL_REFACTOR_IMPLEMENTATION.md, docs/screenshots/ and live Godot captures — current baseline and known unfinished areas.
5. AGENTS.md — repository agent requirements and safe asset-generation instructions.

### Verified current implementation
- Runtime enemy roster: hound, skitter, spitter, wisp, golem, pyromancer, cryomancer, battlemage, champion (Aurel). Enemy IDs and encounter definitions are authoritative in resources/enemies, resources/encounters and Content.
- Current actor exports are art/sprites/actors/*.png, 256×320 atlases made from 64×64 cells in a 4-column × 5-row grid. scripts/effects/fighter_sprite.gd hardcodes four frames for idle/move/cast/hurt/death. Hurt currently loops; death does not. Most visuals share block-like simplified construction and insufficiently distinct poses.
- Current Aseprite generator tools/refactor_actor_assets.lua imports older 48px bodies and decorates/pads them. Simple re-export, upscaling or recoloring will not achieve the target: this epic requires original redraws and animation key poses.
- The presentation is largely constructed inside scripts/ui/main.gd (~614 lines) with fixed Rect2 panel layouts; scripts/ui/ui.gd (~117 lines) supplies a minimal shared theme. art/sprites/ui currently contains six simple button states, not a complete production menu skin.
- Current visual baselines: docs/screenshots/{combat,populated,champion,title,creation,hub,shop,build,settings}.png. New validation screenshots must be captured from running Godot, not synthesized from the reference image.
- Existing project reference resolution: 1280×800. Maintain pixel clarity, keyboard/mouse support, responsive anchors, and existing UI-scale setting.

### Art direction
Modern, crafted three-quarter top-down pixel fantasy. Reference principles: Astral Ascent animation expressiveness, Wizard of Legend readability, Children of Morta magical responsiveness and Stoneshard weathered materials. Use controlled pixel clusters, coherent upper-left painted lighting, material-aware near-black contours, readable silhouette, subdued arena ground, selective glow and limited ornamental antique-gold accents. Fire / Ice / Earth / Air retain their existing semantic palettes. Enemies must differ by physical anatomy and behavior, not only tint. Interface = dark ink/navy, weathered stone/slate, delicate runic/gold trim, legible runtime text, polished interactive states; no generic web-dashboard styling, oversized panels or rasterized mockup labels.

### Enemy visual briefs
| Enemy ID | Required visual identity | Animation and anticipation identity |
| --- | --- | --- |
| hound | Low agile beast; muzzle, shoulders, large directional paws and flowing back | Coiled pounce, stretched leap, distinct landing/claw response |
| skitter | Angular many-legged arthropod; no wolf/canine silhouette | Rapid alternating legs, jerk/twitch, abrupt stops |
| spitter | Squat ranged creature; obvious mouth or inflated venom sac | Sac inflation / aimed mouth cue, recoil on release |
| wisp | Floating core; translucent-ish distinct outer tendrils, no tiny featureless dot | Floating squash/pulse, ribbon motion and tiny motes |
| golem | Heavy asymmetric stone slab assembly; enormous fists, rough material facets | Weighted steps, compressed wind-up, stone dust at impact |
| pyromancer | Fiery rival mage; flame-edged mantle and orange/crimson casting focus | Ember gathering, arm extension, flame after-motion |
| cryomancer | Ice-blue caster; angular crystalline trim and different outline from pyromancer | Sharp frost gathering, poised release and fragments |
| battlemage | Veteran multi-school caster; neutral gear, clearly legible focus silhouette | Mixed-school focus/rune reaction; not permanently one-color |
| champion | Aurel, ceremonial boss; unique crown/ornate mantle/barrier design | Powerful staged casts, shield activation, distinct phase transition |

### Locked limits
- Do NOT change enemy AI, HP, damage, attack IDs, attack cadence, hitboxes, spell timing, encounter composition, existing combat controls or save data merely to accommodate visuals. Keep world collision sizes unchanged even when visual sprite sizes increase.
- Do NOT rewrite the arena, player sprites, spell catalog or combat HUD. Shared-theme integration may touch the HUD only to prevent regressions. Keep player name/level/HP/dodge/cast top-left and Q/W/E/R bottom-center. No mana, permanent combat guide or combat title watermark.
- Do NOT crop the visual reference sheet, copy assets from commercial games, replace fine art with resized old sprites, or pass off generic rectangles and palette swaps as complete enemy designs.
- For every asset: retain an editable layered Aseprite source, reproducible PNG + frame/animation metadata, stable pivot, registry entry, and live runtime comparison.
- Favor careful craft over asset volume. Do not declare this epic complete after passing only import and unit tests.

### Delivery strategy
Proceed through two visual approval gates: (A) a full-size hound and pyromancer art/animation vertical slice against the reference, plus champion scale study; (B) title and spell-shop sample panels using final shared controls. Once those are convincingly integrated in running Godot, propagate the approved methods across the roster and menus. Tasks that can run in parallel must not modify the same generator, shared theme, or authoritative scene without coordination.

## TASK-001 — Audit and Freeze Visual Acceptance Baselines

### Goal
Establish an honest, reproducible before-state and precise visual gap list for the two requested areas.

### Requirements
- Read all authoritative sources listed above; inventory the nine enemy source/PNG pairs, their animation states, pivots, scaling and runtime usage.
- Capture the active combat, crowded encounter, rival duel and champion at native 1280×800; capture title, creation, hub, spell shop, gear shop, loadout, encounter selection, level choice, reward, completion, pause and settings.
- For each screenshot, compare to the relevant enemy, character, button or menu section of the companion reference atlas and record specific problems with silhouette, pose, scale, spacing, typography, hierarchy, composition, button clarity and readability.
- Document where existing flows use fixed Rect2 coordinates, reset scroll/selection state, or hide unavailable choices.
- Define deterministic capture scenarios, filenames and acceptance rubrics (pixel density, native-scale recognition, readable labels, state visibility, animation clarity).
- Preserve the original screenshots for before/after comparison and record the current git revision.

### Acceptance Criteria
- [ ] An enemy-by-enemy and screen-by-screen baseline matrix exists.
- [ ] All current gameplay data IDs and UI actions are inventoried; no screen or enemy is silently omitted.
- [ ] Current screenshots and animation clips are reproducible in Godot without altering gameplay data.

## TASK-002 — Build a Non-Destructive Production Asset Pipeline

### Goal
Make it possible for autonomous Aseprite agents to author genuinely polished artwork without losing edits during regeneration.

### Requirements
- Audit tools/refactor_actor_assets.lua, tools/refactor_ui_assets.lua and art/asset_manifest.json; do not run destructive regeneration over refined assets.
- Give each enemy a canonical editable, layered .aseprite file with named construction/base/shadow/material/highlight/FX layers where useful, plus timeline tags for idle/move/cast/hurt/death and special boss phases.
- Export transparent runtime spritesheets and JSON frame metadata (animation tag, frame rectangle/duration, facing, foot or center pivot, logical source dimensions); preserve tags, alpha and timing across imports.
- Update the asset manifest and generator strategy to distinguish production originals from deprecated block-art prototypes. Keep existing paths valid until consumers are migrated safely.
- Provide image contact sheets at 1× gameplay pixel scale, 2× nearest-neighbor inspection and neutral arena-floor backing; short GIF/APNG/video for animation.
- Add automated checks for missing files, IDs, nontransparent backgrounds, dimensions, tags, pivots, damaged transparency and frame counts.

### Acceptance Criteria
- [ ] Re-export is reproducible without flattening or overwriting hand-authored layers and animations.
- [ ] Every existing enemy ID maps unambiguously to source, spritesheet, metadata and runtime consumer.
- [ ] Validation fails on an incomplete animation, wrong frame layout, missing pivot or broken PNG reference.

## TASK-003 — Produce the Enemy Art Quality Vertical Slice

### Goal
Prove an art/animation standard substantially closer to the reference before committing to the whole roster.

### Requirements
- Fully redraw the hound and pyromancer, not just color accents or enlarged versions of their current sprites; create a champion scale/construction study.
- Use a shared material-aware contour treatment, consistent palette lighting, believable dimensional forms, readable body anatomy and deliberate multi-frame silhouettes.
- Prepare idle, move, cast/attack anticipation, hurt and death previews for both finished examples; prove that frames change posture and weight rather than only flashing pixels.
- Compare against the atlas' enemy silhouette section and the actual in-game arena at native resolution, half-resolution preview, grayscale, in motion and with active spell FX.
- Verify that the hound cannot be mistaken for a skitter and that pyromancer costume/anatomy differs from cryomancer and player before mass production.
- Create an approved mini-style sheet documenting torso/head scale, material clusters, contour width, painted lighting, palette budget, pose exaggeration and FX separation.

### Acceptance Criteria
- [ ] Hound and pyromancer animations have distinct key poses across all required states and visually read without names.
- [ ] Champion scale/pivot study shows visual authority without changing collider sizes.
- [ ] Representative live Godot screenshots/short recordings show a material improvement over the original; art findings are documented before roster production.

## TASK-004 — Redraw Small and Agile Enemy Families

### Goal
Replace the crude hound, skitter, spitter and wisp with four recognizable creatures that have different physical and movement identities.

### Requirements
- Apply the approved quality bar and visual briefs to all four enemies; hound from TASK-003 becomes the finalized reference.
- Hound: canine anatomy, compress/stretch pounce, distinct paws and muzzle, grounded contact shadows.
- Skitter: segmented body and many legs with sharp directional motion; silhouette stays readable beneath particles.
- Spitter: visible inflation of mouth/venom sac, projectile origin aligned to visible anatomy and brief recoil.
- Wisp: bright contained core, asymmetrical translucent-looking tendrils, floating pulse, restrained motes; avoid overglow that erases its body.
- Complete authored idle/move/attack/hit/death sequences per applicable runtime states, with honest pivots/metadata. Directional mirroring must not introduce visually incorrect limbs/foci.
- Check 1× camera-scale legibility, movement animation timing and enemy-specific impact/death response during actual encounters.

### Acceptance Criteria
- [ ] Each of the four enemies can be identified by silhouette in grayscale at the game's normal scale.
- [ ] Their movement and attack anticipations are distinguishable without tooltip or nameplate.
- [ ] No old block-art sprites remain active for these enemies; animations are reproducible from Aseprite sources.

## TASK-005 — Redraw the Golem as a Distinct Heavy Threat

### Goal
Make the golem feel large, constructed from stone, and physically dangerous without altering AI or combat geometry.

### Requirements
- Design a bespoke rocky body with asymmetric slabs, weighted torso, massive forearms and clear head/core; avoid a simple enlarged rectangular humanoid.
- Author idle settling, heavy step, wind-up, release/slam, recoil/hurt and broken-collapse/death with dust and stone chips as separate non-colliding effects.
- Choose 96×96 or 128×128 cells if validated against camera scale; preserve the logical ground/contact anchor and existing gameplay body radius.
- Synchronize any dust/impact accents to existing slam timing; do not generate misleading hazard boundaries.
- Test golem with the player and hound in the same frame and under large AoE spells.

### Acceptance Criteria
- [ ] Golem is visually heavier and larger than ordinary enemies but its collision behavior is unchanged.
- [ ] Wind-up and attack release read before and at the actual gameplay event.
- [ ] Runtime scale, foot contact and death animation do not float, jitter or obscure critical ground telegraphs.

## TASK-006 — Redraw the Three Rival Mage Archetypes

### Goal
Differentiate pyromancer, cryomancer and battlemage through costume design, magical focuses, casting silhouettes and school identity.

### Requirements
- Produce genuinely separate robe shapes, shoulder silhouettes, trim geometry, hair/hood treatment and focus/staff design for each rival.
- Pyromancer: ember/crimson, angled flame mantle, energetic casting; cryomancer: cool blue, faceted crystal trim, precise motion; battlemage: balanced mixed-school veteran, neutral costume with focus-driven color changes.
- Author clear casting hand/focus release frames and idle/move/hurt/death animation. Match the cast launch origin to the drawn hand or staff.
- Do not simply repaint the same base mage with different palettes. Use consistent proportions and pixel density despite distinct silhouette and FX.
- Test duel captures against matching elemental player spells, including overlapping enemy warnings.

### Acceptance Criteria
- [ ] Rivals are recognizable without nameplates or color alone.
- [ ] All three have distinct authored poses and readable cast anticipation synchronized with existing spell events.
- [ ] Rival art remains crisp and consistent with player, creatures and arena; no additional spell schools or mechanics are introduced.

## TASK-007 — Give Aurel the Champion a Bespoke Boss-Quality Sprite Set

### Goal
Make the champion instantly look and animate like the final named encounter rather than an enlarged standard mage.

### Requirements
- Create Aurel's ceremonial mantle/crown, layered cloth/armor, imposing proportions, decorated focus and signature barrier motif.
- Author prominent idle, movement, cast build-up/release, hurt, defeat, barrier activation and phase-transition animations; make anticipation and recovery visibly different.
- Drive barrier/phase visuals from existing champion state transitions in scripts/enemies/enemy.gd, not a separate cosmetic state machine with invented timing.
- Add restrained non-colliding pixel particles and temporary localized lighting for barrier activation and phase shift, while preserving telegraph and player visibility.
- Confirm boss UI remains outside combat center and does not overlap the top-left player HUD or bottom-center spell bar.

### Acceptance Criteria
- [ ] Aurel is unmistakable at native viewport scale and is not a larger palette-swapped rival.
- [ ] Barrier and second phase have visually distinct start/active/finish behavior.
- [ ] All original champion abilities, stats, phase thresholds and hit geometry are unchanged.

## TASK-008 — Integrate Frame Metadata and Correct Enemy Animation Playback

### Goal
Replace the current shared hardcoded 4×5 playback assumptions with frame-accurate, maintainable enemy animation presentation.

### Requirements
- Refactor scripts/effects/fighter_sprite.gd to consume asset-specific frame/timing/pivot metadata or corresponding SpriteFrames resources, supporting small 64px and large 96/128px sources without slicing mismatches.
- Honor tagged frame durations and clip looping: idle/movement loop; hurt and death are one-shot with explicit return/finish; cast animation waits/holds/releases based on authoritative cast lifecycle.
- Map existing Fighter/EnemyFighter visual states to the correct clips; add boss phase/barrier state transitions without modifying game logic.
- Verify left/right flipped views, collision-to-feet alignment, animation transitions, death cleanup, freeze and hit-flash material layering.
- Handle missing animation/tag gracefully with a logged asset error and visible safe fallback rather than invisible enemies.
- Avoid heavy per-frame texture recreation, animation node leaks and expensive redundant loads.

### Acceptance Criteria
- [ ] No actor is forced through four placeholder frames when its asset metadata defines a different length.
- [ ] Hurt animation does not loop indefinitely; death plays once and cleans up with existing lifecycle.
- [ ] Release and impact frames are consistent with actual enemy combat events.
- [ ] Existing AI, cooldown, combat status and collision tests still pass.

## TASK-009 — Validate Enemy Readability and Feedback in Combat

### Goal
Make the new enemies visually excellent in active combat, not only in isolated sprite previews.

### Requirements
- Add restrained contact shadows, body hit-flash/recoil, launch sparks, footsteps/stone dust or floating motes where appropriate; these are cosmetic and optional for VFX-intensity settings.
- Check silhouette separation from fire/ice/earth/air spells, team identification, telegraph outlines, status icons and damage numbers in crowded Menagerie and rival/champion encounters.
- Ensure hostile warning effects remain visible over enemy sprites and decorative light, and maintain correct screen-space target feedback.
- Preserve all live animation and spell event associations during performance stress, including simultaneous enemies and boss effects.
- Generate side-by-side old/new native-scale captures and clips for every enemy; make a corrections pass on any asset that fails legibility.

### Acceptance Criteria
- [ ] All nine enemies remain individually recognizable in live gameplay with strong and weak VFX settings.
- [ ] Enemy casts/attacks visibly anticipate before they become dangerous; no misleading telegraph remains.
- [ ] No new collision obstacles, combat balance changes or unbounded FX-node growth.

## TASK-010 — Build the Production Menu Theme, UI Assets and Component System

### Goal
Replace the thin generic menu skin with an authored, reusable dark-fantasy pixel UI system matching the reference board.

### Requirements
- Develop a visually tested art kit: 9-slice panel surfaces, modal/tooltip/portrait frames, gold/cold-stone corner details, selected tabs, button states normal/hover/pressed/selected/disabled/focus, input fields, scrollbars, toggles, sliders, checkbox and key prompts.
- Create genuine Aseprite UI image sources and transparent exports. Use Godot Theme/StyleBoxTexture/NinePatchRect and independent runtime text; never bake dynamic strings or screenshot fragments into buttons.
- Choose one licensed, redistributable readable menu font family (optional complementary display font) and include license/source documentation. Use approved typography hierarchy (titles ~24–30 px, headings 17–21, body 14–17, minor 12–14 at 1280×800).
- Centralize semantic colors: ink/navy panels, slate/stone borders, antique gold for selection/rare rewards, crimson for danger, school accent for magic. All controls get clear focus, disabled and hover states, including keyboard focus.
- Refactor scripts/ui/ui.gd from generic helper-only widgets to reusable reusable Control scenes/compositions and a consistent theme resource; allow existing menus to migrate one screen at a time.
- Implement common layouts that use anchors, responsive containers, appropriate 9-slice scaling and remembered selection/scroll where applicable.
- Build and capture a small title card and spell-shop example before applying the system to the rest of the menu family.

### Acceptance Criteria
- [ ] Buttons, panels, tools, tabs and input controls have a consistent polished material language at native scale.
- [ ] No default Godot control skin or unreadable tiny text appears on any rewritten sample.
- [ ] Keyboard and mouse states are visibly and functionally distinct.
- [ ] Theme/template sample captures compare favorably to the UI section of the companion art reference.

## TASK-011 — Redesign Title Screen and Character Creation

### Goal
Make first impressions immediately communicate premium pixel-fantasy art and meaningful player choice.

### Requirements
- Title: compose a cinematic but non-distracting cropped view of the arena or original spell-duel pixel illustration, with a refined wordmark and strong primary Create / Continue, secondary Settings / Quit controls; logo is allowed here.
- Creation: present an actual authored mage portrait or animated preview with four mantle-color variants and a spacious side-by-side identity / starter-magic layout.
- Show selected starter packages (Emberweaver, Winter Warden, Stormcaller) with school-themed icons and descriptions without turning text into a huge generic vertical list.
- Keep name field, package choice, mantle choice, save-overwrite confirmation and navigation behaviors intact.
- Ensure pointer, keyboard/focus, controller-independent fallback and responsive viewport compositions remain usable.

### Acceptance Criteria
- [ ] Title is visually distinctive and has clear primary-action hierarchy.
- [ ] Creation screen communicates appearance and magic selection visually before reading descriptions.
- [ ] Original save/continue and all starter package choices remain functional.

## TASK-012 — Redesign Antechamber and Encounter Selection

### Goal
Turn progression navigation and trial selection into readable, appealing fantasy interfaces.

### Requirements
- Hub: create a legible five-trial journey/progression panel and a visually featured next-trial card, keeping level, gold, spell/gear, bonus choice and Save & Return controls.
- Encounter selection: distinct cards for three existing difficulty tiers showing challenge, enemy health/damage multipliers, waves, gold and XP rewards; add relevant enemy/arena illustrative thumbnails without changing encounter data.
- Preserve the exact five-stage sequence: Trial of Embers, First Duel, Menagerie, Fourfold Trial, Crown of Ash.
- Use authored ornaments and iconography only where they aid hierarchy; avoid giant text-dense panels.
- Never remove existing unlock states, tooltips, back navigation or action availability.

### Acceptance Criteria
- [ ] Players can identify current stage, next trial, difficulty, rewards and start action at a glance.
- [ ] No change to encounter mechanics, unlocks or reward calculations.
- [ ] Hub and difficulty screens share component styles and remain readable at target resolutions.

## TASK-013 — Redesign Spell and Gear Shops

### Goal
Make shopping about understanding and comparing magical items rather than reading generic panels.

### Requirements
- Spell shop: preserve current three-offer-per-visit behavior; redesign offer cards with 48px spell icons, school color/motif, name, tooltip-friendly stats (damage, cooldown, cast time, targeting/range), price and Owned/Unavailable/Purchase states.
- Gear shop: author proper transparent 32/48px silhouettes for every existing gear Resource; avoid substituting generic colored SVG geometric placeholders. Show equipment slot, effect, price, ownership and equipped status.
- Add stronger selected-card/detail hierarchy; the user should visually compare cards without long cramped text columns.
- Display insufficient gold and already-owned reasons explicitly; purchase feedback should be clear but not distractingly animated.
- Do not alter shop stock rerolls, prices, ownership tracking or persistence.

### Acceptance Criteria
- [ ] Every actual spell and gear item referenced by shop data has an appropriate icon.
- [ ] All three offers and all buy/disabled cases remain legible and usable.
- [ ] Purchases, gold balance, ownership and equipped states continue to behave as before.

## TASK-014 — Redesign Character Build and Loadout

### Goal
Give spell and equipment configuration a dedicated polished composition.

### Requirements
- Present an authored mage portrait, core statistics, four large Q/W/E/R equipped skill slots, four gear slots and owned item/spell listings within a balanced layout.
- Spell slots must use existing 48px icons, keyboard labels, school accents and selected/hover/equipped states; never imply mana costs.
- Preserve current select-a-slot then equip workflow including swapping an already-equipped spell between slots; keep equip/unequip logic and statistics authoritative.
- Tabs, lists, detail panels and tooltips should retain selection and scroll where sensible instead of rebuilding a confusing generic list after each click.
- Add readable empty-slot and no-owned-gear states.

### Acceptance Criteria
- [ ] The equipped four spells and gear are recognizable without expanding text lists.
- [ ] All original equipping, swapping, removal and calculation flows pass.
- [ ] The loadout layout fits 1280×800 without overlapping stats or selected item content.

## TASK-015 — Redesign Rewards, Level Choices and Completion

### Goal
Make progression milestones emotionally and visually meaningful while keeping the information practical.

### Requirements
- Victory: display trial crest, reward totals (gold/XP), earned milestone, next action and any available bonus choice with restrained particle accents.
- Defeat: clear retry/return options and reassurance of actual retained progress, without falsely indicating lost resources.
- Level choices: design distinct benefit cards for current bonuses (Vitality, Potency, Rhythm, Agility, Control), showing real effects and clear chosen state.
- Completion: create a special original crown/ceremonial illustration, character name and achievement framing with restrained runes/gold accents; do not add future arena mechanics.
- Use shared button/typography styles and preserve return, restart, save and choice-count behavior.

### Acceptance Criteria
- [ ] Victory, defeat, level-up and final completion look distinct and polished.
- [ ] All quantities and rewards are read from actual GameState, not hardcoded art mockup values.
- [ ] Every choice and navigation path works and respects existing persistence.

## TASK-016 — Redesign Pause, Settings and Confirmation Modals

### Goal
Replace default-looking overlays with accessible, consistent menus that feel designed.

### Requirements
- Create focused modal backplates, title/body hierarchy, context-aware primary/destructive controls, and a restrained backdrop dim over combat.
- Style current master/music/SFX sliders, screen shake, UI/text scale, Spell VFX intensity, damage-number and fullscreen toggles.
- Provide visible keyboard focus and hover/selected/disabled states; maintain safe Esc close/cancel behavior, pause/resume and settings save.
- Confirmation dialogs must distinguish irreversible or save-overwrite actions from benign ones with appropriate emphasis.
- Validate legibility over bright spells, dark arena corners and different window sizes; avoid effects that hide underlying critical information during pause transitions.

### Acceptance Criteria
- [ ] All existing setting options remain persisted and operate exactly as before.
- [ ] Modals do not overflow, trap input or leave gameplay unintentionally paused/unpaused.
- [ ] Pause/settings visuals match the rest of the redesigned screen family.

## TASK-017 — Complete Cross-Screen Integration, Regression and Visual QA

### Goal
Release the enemy-and-menu pass only after proof in Godot that both match the art guide and remain functional.

### Requirements
- Capture native 1280×800 final comparisons for all nine enemies (idle/action/hurt/death as appropriate), crowded Menagerie, pyromancer/cryomancer duels and Aurel's phase/barrier; also title, creation, hub, encounter, both shops, build, rewards, level choices, completion, pause and settings.
- Recheck layouts at 1600×900 and 1920×1080 (or representative widescreen). Test text scaling, keyboard focus, mouse control, long strings and all button states.
- Validate Aseprite sources/tags/exports/manifest via tools/validate_visual_assets.py plus added checks; verify correct nearest-neighbor sampling, alpha, file references, frame timing, pivots, readable silhouettes and no accidental smoothing.
- Run existing gameplay test suite and performance tests. Verify all original enemy profiles, attacks, status reactions, content IDs, encounters, shops, loadout and save/restore behavior.
- Exercise the original 1280×800 game with worst-case enemy and spell density; compare performance against recorded local baseline without claiming hardware-independent FPS guarantees.
- Record a short real-time montage of representative enemy attack/hurt/death animations and menu navigation. Use actual Godot captures for final art review rather than reference renders.
- Update docs/VISUAL_REFACTOR_IMPLEMENTATION.md and docs/VALIDATION.md with files changed, remaining gaps, tests run, screenshots and honest visual-quality assessment. Keep the visual guide and reference image unchanged.
- Reject visually crude placeholder rectangles, re-colored identical rivals, barely animated poses, tiny unreadable text, inconsistent panel skins, improperly clipped menus and any regression to combat input/geometry.

### Acceptance Criteria
- [ ] Each of the nine enemies has a polished source, reproducible export, correct animation integration and validated live screenshot/clip.
- [ ] Every existing non-combat menu and modal uses the new shared component/theme system with complete functional behavior.
- [ ] Before/after comparisons at native scale show meaningful improvements in silhouette, craftsmanship, animation and menu layout.
- [ ] All relevant Godot tests and asset validators pass; any environment-specific exceptions are documented.
- [ ] No existing gameplay mechanic, save schema, player HUD arrangement, spell definitions or arena camera behavior was unintentionally changed.
- [ ] Final documentation contains screenshot/video evidence and no unverified claim that reference-level quality has been achieved.

### Definition of Done
This epic is complete only when all enemies and menu flows are visually reviewed inside running Godot; hand-authored pixel sources and exports are reproducible; the menu family behaves cohesively; combat and progression tests still pass; and the unfinished areas identified in docs/VISUAL_REFACTOR_IMPLEMENTATION.md for enemy sprites and menus have been explicitly closed or documented as remaining differences.
