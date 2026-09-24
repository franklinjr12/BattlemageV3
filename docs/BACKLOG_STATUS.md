# Backlog implementation status

Status definitions: **Implemented** means a working system is present, with relevant automated or visual checks. **Provisional** means implementation exists but its experiential acceptance criteria need human playtesting. **Pending human validation** cannot honestly be completed by an automated coding run.

| Tasks | Status | Implementation / evidence |
|---|---|---|
| 001–006 | Implemented | Godot structure, main scene, autoload run state, typed spell/gear/enemy Resources, complete navigation. |
| 007–012 | Implemented | Identity/appearance/three packages, bounded circular arena, right-click motion, health/death, shared damage events, independent dodge charges. |
| 013–018 | Implemented | Four-slot swapping, selection/cancel, exact shared targeting shapes, click confirmation, rooted/interruptible casting, independent cooldowns. |
| 019–022 | Implemented | Swept projectiles with piercing/explosion, persistent/delayed areas, cone/line hit detection, source-aware stacking statuses. |
| 023–027 | Implemented | Four spells per school. Burn/Combustion, Freeze/Shatter, grouping/AoE, pushing into zones, controlled-target bonus. |
| 028–034 | Implemented | Combat HUD, cast/health/status bars, five creature profiles with wind-up/recovery and different speeds, ranges, and control resistance. |
| 035–040 | Implemented | Common mage AI, three loadouts, phased Champion, encounter Resources, wave lifecycle, difficulty/rewards. |
| 041–044 | Implemented | Five trials, single-application gold/XP, levels 1–5, five persistent level-bonus choices. |
| 045–052 | Implemented | Seeded three-offer shops, 20 items/4 slots, modifier hooks, build screen, hub/results, transactional versioned save/recovery. |
| 053–055 | Implemented, feel provisional | Visible shapes/wind-ups, impact/status/dodge/death feedback, hit flash, configurable shake, knockback, damage numbers. Hit-stop was not added: feedback already communicates hits without freezing input. |
| 056–059 | Implemented, art/audio provisional | Voice pool, audio buses/cues/ambience, original arena/glyph/actor art, state-driven actor motion and visual states. Public-release polish still benefits from human review. |
| 060–064 | Implemented | Pause/settings, contextual dismissible tutorial, modifier-aware tooltips, seeded encounters/offers, centralized economy. |
| 065–067 | Implemented | Debug-only tools, automated tests, runtime content validation. Release rejects debug UI and capture shortcuts. |
| 068–072 | Provisional | Initial spell, enemy, difficulty, economy, and pacing pass. Three starting packages are exercised through full combat runs. Thirty-to-sixty-minute first-run pacing has not been validated by a person. |
| 073–075 | Implemented | Persistent crown/completion, fresh-character reset, difficulty and build replayability, shake/numbers/audio/fullscreen/text-size options. |
| 076 | Implemented, target-device sample | Repeated arena stress test on Intel UHD graphics; bounded effects, cleanup, and frame timing recorded in performance.json. Broader hardware coverage remains outside this sample. |
| 077 | Implemented | Automated tests cover invalid targets, selection changes, roots, cast/dodge/death interruption, exhausted charges, pause/resume, and end cleanup. |
| 078 | Automated integration complete; manual pass pending | Real AI, cast/cooldown/damage, waves, rewards, purchases, level choices, and Champion completion exercised without debug victories in the integration bot. Human mouse-driven completion remains a release checklist item. |
| 079–080 | Pending human validation | First-time-player understanding, enjoyable builds, intentional combos, rooted-cast commitment, and repeated-session fun require observed testers. Playtest sheet is included. |
| 081–082 | Provisional | Screens rendered and inspected; icons differentiated; layouts checked including fully equipped gear. Sound cues exist and are mixed conservatively, but subjective audio polish/listening is pending. |
| 083 | Implemented test pass; continued QA expected | Import/runtime checks, all-spell exercise, invalid-save recovery, duplicate reward protection, full runs, and cleanup checks. No promise that unknown bugs cannot exist. |
| 084 | Implemented | Windows x64 release and QA presets, embedded package, application name/version/icon, user data saves, debug menu disabled. |
| 085 | Pending final human acceptance | Functional content/core loop delivered. Public-demo signoff is withheld until playtime, usability, fun, and final polish have been evaluated by humans. |

The optional sound-track variations, hit-stop, additional resolutions, and physical scene transitions were not expanded beyond what this demo needs. Menus are reusable Controls under a navigation coordinator; arena actors and spell effects are independent scenes.
