# Validation record — 2026-09-24

Environment: Godot 4.7.2 stable, Windows x64, OpenGL Compatibility, Intel UHD Graphics. Distribution version: 0.1.0.

## Automated systems and packaged runtime

The system suite contains 157 checks in the editor runtime and 158 in the release runtime (the extra release check verifies that the debug menu cannot open). It covers content references, all 16 player spells, status combinations, targeting, cast cancellation, dodge timing, bounds, health/death, item transactions, modifier stacking, seeded offers, XP/difficulty/rewards, duplicate reward prevention, save serialization and disk replacement, backup recovery, invalid data, scene construction, pause/resume, and complete encounter progression.

The Windows QA export uses the same release compiler/runtime and game code as the distribution build. It retains test scenes and selects them with a QA feature; the distribution excludes them. Latest release runs:

| Scenario | Result | Simulated combat time | Champion HP remaining (player) |
|---|---|---:|---:|
| Winter Warden, Normal, seed 9901 | 158 checks, 0 failures; 5/5 wins | 476.6 s | 22.1 |
| Emberweaver, Normal, seed 9901 | 158 checks, 0 failures; 5/5 wins | 424.4 s | 95.6 |
| Stormcaller, Normal, seed 9901 | 158 checks, 0 failures; 5/5 wins | 322.8 s | 0.3 |

These are scripted test scenarios, not human playtests. The driver uses real movement, ordinary spell requests, cooldowns, damage, enemy AI, legal purchases, and level choices. It does not grant victory, invulnerability, or extra gold in the full-run scenarios. Its defensive policy differs for the slower Winter Warden and mobile builds. It advances simulation in fixed steps and does not measure real-world first-run duration. Alternative dodge policies lost at the Champion; the very close Stormcaller finish reinforces that human balance testing is still necessary.

See `release-tests.log`, `release-tests-Winter-Warden.log`, `release-tests-Emberweaver.log`, and `release-tests-Stormcaller.log`; corresponding latest error logs are empty. The final distribution also receives a standalone startup smoke check. The normal save file is not modified by these checks.

## Export issues fixed

1. Folder enumeration did not discover resources after Godot's export remapping. Content now uses `data/content_index.json` with explicit resource paths.
2. In this installed exporter, binary-converted Resources lost packed-array data, including tags and enemy lineups. Text Resource conversion is disabled in the export configuration. Release checks verify the actual arrays and exercise full combat.
3. Immediate shutdown could leave active audio playback references. Normal app exits stop audio and allow the audio thread to drain. Headless runs skip playback entirely.

## Rendering and cleanup

The 12-second graphical stress scene ran three arena cycles with six opponents and rapidly generated projectiles/persistent areas. On the local Intel UHD Graphics device:

- 661 measured frames after warm-up; mean and p95 frame delta approximately 16.67 ms (about 60 FPS).
- Peak concurrent spell effects: 15; peak scene nodes: 43.
- Nodes after arena cleanup: 18, including autoload/audio/test infrastructure.
- Static memory: about 33.70 MB initially and 34.85 MB at the end, including warmed resources. This short sample does not establish zero growth over long sessions.
- No runtime errors in the latest graphical performance or combat-capture run.

Raw metrics are in `performance.json`. Screenshots were rendered and visually inspected for title, character creation, hub, shops, empty/fully equipped builds, settings, creature combat, and Champion combat. The HUD was adjusted so all four distinct spell glyphs and labels fit.

## Open release gates

- Observe unfamiliar people using the actual mouse/keyboard interface from launch to completion.
- Validate and, if needed, retune the 30–60 minute first-run target. Current automated combat totals are approximately 5–8 minutes of highly efficient simulated combat, excluding menus, experimentation, retries, and human decision time; they do not prove that target.
- Evaluate rooted casts, difficulty, pure-school versus mixed builds, meaningful upgrades, and repeated-session fun.
- Conduct subjective visual/audio polish and longer hardware/stability testing.

`PLAYTEST.md` is the recording checklist. `BACKLOG_STATUS.md` maps every backlog range to its implementation/acceptance status. No human acceptance result is inferred from the automated runs.
