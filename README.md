# Battlemage Arena — Local Ascension

A Godot 4.7.2 desktop action demo. Open `project.godot` and press F6 on `scenes/main.tscn`, or F5 to play the project. The Windows release is `builds/BattlemageArena.exe`.

## Play

- Right mouse: move to a destination; also cancels spell selection.
- Q / W / E / R: select a spell, without casting.
- Left mouse: confirm the target.
- Space: dodge toward the cursor. Two charges recharge independently.
- Escape: cancel targeting, otherwise pause. Cast-time spells root you. Dodge cancels a cast without consuming its cooldown; normal damage does not cancel it.
- No mana. Buy spells and equipment between fights, then equip them in Character & spell loadout.
- Defeat preserves gold, build, and encounter progress. Retry with full health. New characters replace the previous run after confirmation.

Three starting packages, four schools, 16 player spells, 20 gear pieces, five creature archetypes, three rival mage archetypes, and Aurel the Arena Champion are implemented. The five trials alternate creatures and duels. Creature trials use two and three waves, with 10% maximum-health recovery between waves. Difficulty changes health, damage, AI pressure, composition, and rewards. The Champion gains a barrier and speed below half health.

## Ownership and architecture

| Location | Responsibility |
|---|---|
| `scripts/data`, `resources` | Typed spell, gear, enemy, and encounter Resources. `Content` loads and validates them. |
| `scripts/progression/game_state.gd` | Autoload owns the serializable run, seeded offers, rewards, gear totals, levels, and saves. No active actors are saved. |
| `scripts/combat/arena.gd` | Owns the active encounter, spawn waves, actors, effects, bounds, victory/defeat, and single reward transition. |
| `scripts/combat/fighter.gd` | Shared casting, cooldowns, defenses, damage reception, movement, and actor presentation. |
| `scripts/combat/vitality.gd`, `status_set.gd`, `damage_event.gd` | Composed health/status components and shared structured damage pipeline. |
| `scripts/player`, `scripts/enemies` | Mouse/keyboard intent and configurable AI intent respectively. |
| `scripts/combat/spell_geometry.gd` | Shared targeting geometry for previews and actual hit checks. |
| `scenes/spells`, `scripts/combat/projectile.gd`, `spell_effect.gd` | Reusable projectile, timed area, cone, line, self, and movement effects. |
| `scripts/ui/main.gd`, `ui.gd` | Navigation/presentation coordinator and reusable themed UI builders. Menus are generated Controls; independent combat systems communicate through signals. |
| `scripts/effects`, `art` | Original code-native pixel glyphs, animated actors, arena stonework, and combat feedback. |
| `scripts/audio`, `audio` | Twelve-voice SFX pool and a separate looping music bus. Original synthesized audio. |
| `data/economy.json`, `packages.json` | Economy, thresholds, difficulty, starting builds, and baseline player configuration. Item prices remain in item Resources. |
| `tests` | Deterministic system tests, simulated complete runs, screen construction checks, and rendering stress test. |

Collision layer names are configured as: 1 arena bounds, 2 player, 3 enemies, 4 player attacks, 5 enemy attacks. The current small demo uses explicit team filtering, swept projectile segments, radial bounds, and analytic shape tests instead of physics-body collision layers. The names reserve the same meaning for future physics-based scenes.

The viewport is 1280×800 with a preserved aspect ratio and nearest-neighbor filtering. There are no gameplay obstacles. Decorations remain outside the circular boundary. The art and audio are authored in this repository and require no third-party asset downloads.

## Combat rules

- Cooldowns start on completed execution, not on selection or interrupted wind-up. Ground targets outside spell range or arena bounds are rejected.
- Burn stacks to four and refreshes duration. Combustion consumes stacks for bonus damage. Three Chill applications cause Freeze. A heavy-tagged hit consumes Freeze and deals +60% damage. Controlled targets take +35% Icicle Rain damage.
- Stagger builds to the target's threshold, then stuns. Boss control durations are reduced. Vortex pulls; Gust displaces. Both interact naturally with persistent damage zones.
- Modifiers add by key. Percent damage is `base × (1 + global + element)`. Cooldown/dodge reductions have a 35% duration floor; cast duration has a 25% floor. Area modifiers scale radii and line widths. Removing gear recomputes from base stats.
- AI uses observed positions and cooldowns. Its target is fixed during visible wind-up. It cannot read player input. Mages reposition, sometimes dodge, and move out of persistent danger.
- Combat pauses as a subtree. Ending a fight cancels casts, clears live effects, disables actions, and applies rewards at most once.

## Saves and settings

Versioned JSON files live in `%APPDATA%/BattlemageArenaV3/` (`user://`). Writes use a temporary file, a previous-good `.bak`, and rename. Invalid content IDs, types, slots, loadouts, appearance, progression, or version fail safely. Loading tries the backup if the primary save is invalid. Settings persist separately from character progress. Combat is never serialized; resuming returns to the hub.

`--test` and editor `--capture <page>` runs disable normal save writes, protecting the user's run. Test disk operations use a separate `test-save.json` and clean up only that file and its backup.

## Verification

Use the installed Godot console binary:

```powershell
& 'C:\Users\sa-su\Documents\Godot\Godot_console.exe' --headless --path 'C:\Repos\battlemage-arena-v-3' 'res://tests/tests.tscn' -- --test
& 'C:\Users\sa-su\Documents\Godot\Godot_console.exe' --headless --path 'C:\Repos\battlemage-arena-v-3' 'res://tests/tests.tscn' -- --test --package 'Emberweaver' --difficulty 1
& 'C:\Users\sa-su\Documents\Godot\Godot_console.exe' --path 'C:\Repos\battlemage-arena-v-3' 'res://tests/performance.tscn' -- --test
```

F1 opens developer tools only in debug builds. It grants spells/equipment, sets a seed/level/gold, spawns opponents, resets cooldowns, toggles invulnerability, and finishes encounters. Release builds explicitly reject this menu and the capture shortcut.

`Windows Desktop` exports a single executable with its game package embedded. `Windows QA` is the same release runtime with test scenes retained for packaged-runtime checks. The QA preset selects its test scene with the `qa` project feature, because these release templates disallow command-line scene overrides. Distribute only `BattlemageArena.exe`. Tests, authoring scripts, logs, and screenshots are excluded from the distribution export. Text-to-binary Resource conversion is deliberately disabled: the installed 4.7.2 exporter dropped packed-array content in binary-converted Resources. Keeping authored text Resources inside the package passes the same release tests with spell tags, mage loadouts, and encounter lineups intact.

Content Resources can be edited in Godot. When adding a Resource, add its filename to `data/content_index.json`; the index keeps resource loading reliable inside exported packages. `tools/generate_content.py` and `tools/create_glyphs.py` reproduce the initial content/audio and distinct spell/item glyphs; running them overwrites authored Resource values, so use them deliberately.

## Release status

This is a functioning demo implementation with automated coverage and an export, not a claim that all 85 backlog acceptance criteria have been signed off. See `docs/BACKLOG_STATUS.md` and `docs/VALIDATION.md`. Human first-time playtesting, combat-fun validation, audio listening, and the 30–60 minute playtime target remain release gates. The automated bot is an unusually efficient player and is not a substitute for those observations.

