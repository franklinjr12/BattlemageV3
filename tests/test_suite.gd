extends Node
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: " + message)

func _ready() -> void:
	GameState.disk_enabled = false
	await get_tree().process_frame
	test_content()
	test_progression()
	test_status_health()
	await test_combat()
	await test_screens()
	await test_bot_run()
	print("RESULT: %d checks / %d failures" % [checks, failures.size()])
	for failure: String in failures: print("  " + failure)
	Sound.shutdown(0 if failures.is_empty() else 1)

func test_content() -> void:
	print("CONTENT_SAMPLE tags=%s enemies=%s attacks=%s waves=%s" % [Content.spells.claw.tags, Content.encounters[0].enemies, Content.enemies.pyromancer.attacks, Content.encounters[0].waves])
	check(Content.validate().is_empty(), "All content references validate")
	check(Content.spells.size() == 21, "16 player spells and 5 creature attacks")
	check(Content.gear.size() == 20, "20 gear items")
	check(Content.enemies.size() == 9, "5 creatures, 3 mages, 1 champion")
	check(Content.encounters.size() == 5, "Five progression stages")
	for package: String in Content.packages:
		GameState.new_run("Tester", 2, package, 412)
		check(GameState.valid_run(GameState.run), "Valid starting package " + package)

func test_progression() -> void:
	GameState.new_run("Tester", 2, "Emberweaver", 412)
	var offers: Array = GameState.run.spell_offers.duplicate()
	GameState.refresh_shops()
	check(offers == GameState.run.spell_offers, "Shop seed is reproducible")
	for id: String in offers:
		check(not GameState.run.owned_spells.has(id), "Offers exclude owned spells")
	var purchase_id: String = offers[0]
	var price: int = Content.spells[purchase_id].price
	GameState.run.gold = price - 1
	check(not GameState.purchase("spell", purchase_id), "Unaffordable purchase blocked")
	GameState.run.gold = price
	check(GameState.purchase("spell", purchase_id), "Affordable purchase succeeds")
	check(int(GameState.run.gold) == 0 and GameState.run.owned_spells.has(purchase_id), "Purchase charges once")
	check(not GameState.purchase("spell", purchase_id), "Duplicate purchase blocked")
	var old_q: String = GameState.run.loadout[0]
	var old_w: String = GameState.run.loadout[1]
	check(GameState.equip_spell(0, old_w), "Equipped spell swaps")
	check(GameState.run.loadout[1] == old_q, "Swap preserves four unique spells")
	check(not GameState.equip_spell(-1, old_q), "Invalid slot blocked")
	check(not GameState.equip_spell(0, "slam"), "Enemy spell not equipable")
	GameState.run.owned_gear = ["granite_robe", "prism_staff", "tempo_ring"]
	var base: Dictionary = GameState.stats()
	GameState.equip_gear("granite_robe")
	GameState.equip_gear("prism_staff")
	GameState.equip_gear("tempo_ring")
	var stats: Dictionary = GameState.stats()
	check(is_equal_approx(stats.max_hp, base.max_hp + 45), "HP gear applies")
	check(is_equal_approx(stats.power, 0.15), "Global damage gear applies")
	check(is_equal_approx(GameState.scaled_cooldown(Content.spells.fireball, stats), 2.8 * 0.88), "Cooldown modifiers apply")
	GameState.unequip_gear("Robe")
	check(is_equal_approx(GameState.stats().max_hp, base.max_hp), "Unequip reverses gear")
	var data: Variant = JSON.parse_string(JSON.stringify(GameState.run))
	check(GameState.valid_run(data), "Save JSON roundtrip")
	for malformed: Variant in [null, [], {}, {"version": 900}]:
		check(not GameState.valid_run(malformed), "Reject malformed save")
	var bad: Dictionary = GameState.run.duplicate(true)
	bad.loadout = ["missing", "missing", "missing", "missing"]
	check(not GameState.valid_run(bad), "Reject missing spell references")
	bad = GameState.run.duplicate(true)
	bad.equipment = {"Staff": "granite_robe"}
	check(not GameState.valid_run(bad), "Reject wrong gear slots")
	bad = GameState.run.duplicate(true)
	bad.level = "two"
	check(not GameState.valid_run(bad), "Reject wrong numeric types safely")
	check(GameState.atomic_write("user://test-save.json", JSON.stringify(GameState.run)), "Atomic save write")
	check(GameState.valid_run(JSON.parse_string(FileAccess.get_file_as_string("user://test-save.json"))), "Disk save roundtrip")
	check(GameState.atomic_write("user://test-save.json", JSON.stringify(GameState.run)), "Atomic save replacement and backup")
	check(FileAccess.file_exists("user://test-save.json.bak"), "Save backup exists")
	check(GameState.load_run("user://test-save.json"), "Load valid save from disk")
	var invalid_file: FileAccess = FileAccess.open("user://test-save.json", FileAccess.WRITE)
	invalid_file.store_string('{"version":999}')
	invalid_file.close()
	check(GameState.load_run("user://test-save.json"), "Recover invalid primary save using valid backup")
	check(GameState.save_error.contains("backup"), "Backup recovery explains result")
	bad = GameState.run.duplicate(true)
	bad.appearance = 999
	check(not GameState.valid_run(bad), "Reject out-of-range appearance")
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists("user://test-save.json" + suffix): DirAccess.remove_absolute("user://test-save.json" + suffix)
	GameState.new_run("Runner", 0, "Winter Warden", 12345)
	for stage: int in 5:
		var ids: PackedStringArray = GameState.enemy_ids(stage, 1)
		var easy: Dictionary = GameState.reward_for(stage, 0, ids)
		var normal: Dictionary = GameState.reward_for(stage, 1, ids)
		var hard: Dictionary = GameState.reward_for(stage, 2, ids)
		check(easy.gold < normal.gold and normal.gold < hard.gold, "Difficulty scales gold")
		check(easy.xp < normal.xp and normal.xp < hard.xp, "Difficulty scales XP")
		GameState.in_combat = true
		var result: Dictionary = GameState.finish_encounter(true, stage, 1, ids)
		check(result.gold == normal.gold and int(GameState.run.stage) == stage + 1, "Reward and stage advance")
		var gold: int = GameState.run.gold
		check(GameState.finish_encounter(true, stage, 1, ids).is_empty(), "Duplicate reward blocked")
		check(int(GameState.run.gold) == gold, "Gold cannot be awarded twice")
		while int(GameState.run.choices) > 0: GameState.choose_bonus("power")
	check(GameState.run.complete and int(GameState.run.level) == 5, "Champion finishes demo at level 5")
	check(GameState.valid_run(GameState.run), "Completed run saves")
	GameState.new_run("Fresh", 1, "Stormcaller", 7)
	check(int(GameState.run.stage) == 0 and int(GameState.run.level) == 1 and GameState.run.owned_gear.is_empty() and GameState.run.bonuses.is_empty(), "New character clears previous progression")
	var gold: int = GameState.run.gold
	GameState.in_combat = true
	GameState.finish_encounter(false, 0, 2, GameState.enemy_ids(0, 2))
	check(int(GameState.run.gold) == gold and int(GameState.run.stage) == 0 and int(GameState.run.xp) == 0, "Defeat grants no rewards and preserves progress")

func test_status_health() -> void:
	var health: Vitality = Vitality.new()
	health.reset(100)
	health.hurt(25)
	check(health.current == 75, "Shared health damage")
	health.heal(80)
	check(health.current == 100, "Healing capped")
	health.invulnerable = true
	check(health.hurt(25) == 0, "Invulnerability blocks damage")
	health.invulnerable = false
	health.hurt(200)
	check(health.dead and health.current == 0, "Death at zero")
	health.heal(100)
	check(health.current == 0, "Healing cannot revive dead combatant")
	var status: StatusSet = StatusSet.new()
	status.apply("chill", 4, null)
	check(status.movement_factor() < 1, "Chill slows")
	status.apply("chill", 4, null)
	status.apply("chill", 4, null)
	check(status.active.has("freeze") and status.rooted(), "Three Chill stacks freeze")
	status.update(5)
	check(not status.rooted(), "Control expires")
	for i: int in 3: status.apply("stagger", 1, null)
	check(status.active.has("stunned"), "Stagger threshold stuns")
	status.clear()
	for i: int in 8: status.apply("burn", 4, null)
	check(status.active.burn.stacks == 4, "Burn stack cap")
	check(not status.update(0.7).is_empty(), "Burn produces shared damage events")

func make_arena(package: String = "Emberweaver") -> ArenaDirector:
	GameState.new_run("Combat test", 0, package, 152)
	var arena: ArenaDirector = ArenaDirector.new()
	add_child(arena)
	arena.begin(0, 1)
	arena.intro = 0.0
	arena.active = true
	arena.set_process(false)
	for fighter: Fighter in arena.fighters(): fighter.set_physics_process(false)
	return arena

func tick(arena: ArenaDirector, duration: float, enemies_active: bool = false) -> void:
	var steps: int = ceili(duration * 60)
	for step: int in steps:
		arena._process(1.0 / 60.0)
		arena.player._physics_process(1.0 / 60.0)
		for enemy: EnemyFighter in arena.enemies:
			enemy.set_physics_process(false)
			if enemies_active: enemy._physics_process(1.0 / 60.0)
		for effect: Node in arena.effects.get_children():
			effect.set_physics_process(false)
			if not effect.is_queued_for_deletion(): effect._physics_process(1.0 / 60.0)

func test_combat() -> void:
	var arena: ArenaDirector = make_arena()
	var player: PlayerFighter = arena.player
	var select_event: InputEventKey = InputEventKey.new()
	select_event.physical_keycode = KEY_Q
	select_event.pressed = true
	player._unhandled_input(select_event)
	check(player.selected == Content.spells[GameState.run.loadout[0]] and player.cooldowns.is_empty(), "Q selects without casting")
	select_event.physical_keycode = KEY_W
	player._unhandled_input(select_event)
	check(player.selected == Content.spells[GameState.run.loadout[1]], "Rapid selection replaces selected spell")
	select_event.physical_keycode = KEY_ESCAPE
	player._unhandled_input(select_event)
	check(player.selected == null, "Escape cancels selection")
	var enemy: EnemyFighter = arena.enemies[0]
	enemy.position = player.position + Vector2(90, 0)
	for other: EnemyFighter in arena.enemies:
		if other != enemy: other.position = ArenaDirector.CENTER + Vector2(-200, 0)
	check(arena.inside(arena.clamp_position(Vector2(9000, -9000)), player.body_radius - 1), "Arena clamps outside destinations")
	var spell: SpellData = Content.spells.burning_ground
	check(not player.request_cast(spell, Vector2(-999, -999)), "Invalid ground target rejected")
	check(not player.cooldowns.has(spell.id), "Invalid target consumes no cooldown")
	check(player.request_cast(spell, enemy.position), "Accept valid cast-time spell")
	var point: Vector2 = player.position
	player.destination = point + Vector2(100, 100)
	tick(arena, 0.2)
	check(player.position == point and player.casting != null, "Casting roots movement")
	check(player.dodge(point + Vector2(0, -100)), "Dodge cancels casting")
	check(player.casting == null and not player.cooldowns.has(spell.id), "Cancelled cast has no effect or cooldown")
	var before: float = player.health.current
	var damage: DamageEvent = DamageEvent.new()
	damage.amount = 10
	player.receive_damage(damage)
	check(player.health.current == before, "Dodge invulnerability active")
	tick(arena, 0.4)
	player.receive_damage(damage)
	check(player.health.current < before, "Dodge invulnerability ends")
	player.dodge(player.position + Vector2(0, 50))
	tick(arena, 0.4)
	check(not player.dodge(player.position + Vector2(0, 50)), "Cannot spam exhausted charges")
	tick(arena, 4.2)
	check(player.dodge_timers[0] == 0 and player.dodge_timers[1] == 0, "Charges recharge independently")
	for spell_id: String in Content.spells:
		var definition: SpellData = Content.spells[spell_id]
		if definition.tags.has("enemy_only"): continue
		player.cancel_cast()
		player.statuses.clear()
		player.dodge_time = 0
		player.cooldowns.clear()
		player.position = ArenaDirector.CENTER
		player.destination = player.position
		enemy.health.reset(5000)
		enemy.statuses.clear()
		enemy.position = player.position + Vector2(70, 0)
		var hp: float = enemy.health.current
		check(player.request_cast(definition, enemy.position), "Spell accepts cast: " + spell_id)
		tick(arena, definition.cast_time + definition.delay + 0.5)
		if definition.damage > 0:
			check(enemy.health.current < hp, "Spell hits: " + spell_id)
		else:
			check(player.barrier > 0 if definition.tags.has("barrier") else player.guard_time > 0, "Defensive spell applies: " + spell_id)
		check(float(player.cooldowns.get(spell_id, 0)) > 0, "Independent cooldown: " + spell_id)
		for effect: Node in arena.effects.get_children(): effect.free()
	var shatter: DamageEvent = DamageEvent.new()
	shatter.amount = 20
	shatter.tags = ["heavy"]
	enemy.statuses.apply("freeze", 3, player)
	check(is_equal_approx(enemy.receive_damage(shatter), 32), "Frozen heavy hit shatters for 60% bonus")
	var detonate: DamageEvent = DamageEvent.new()
	detonate.amount = 20
	detonate.tags = ["consume_burn"]
	enemy.statuses.apply("burn", 4, player)
	enemy.statuses.apply("burn", 4, player)
	check(is_equal_approx(enemy.receive_damage(detonate), 56), "Combustion consumes stacks for bonus damage")
	check(not enemy.statuses.active.has("burn"), "Consumed Burn removed")
	var cone: SpellData = Content.spells.gust
	check(SpellGeometry.contains(cone, Vector2.ZERO, Vector2.RIGHT, Vector2(100, 0), 0), "Cone front included")
	check(not SpellGeometry.contains(cone, Vector2.ZERO, Vector2.RIGHT, Vector2(-100, 0), 0), "Cone back excluded")
	player.cancel_cast()
	player.cooldowns.clear()
	player.request_cast(Content.spells.earth_pillar, enemy.position)
	player.statuses.apply("freeze", 1, enemy)
	tick(arena, 0.1)
	check(player.casting == null, "Hard control interrupts casting")
	player.statuses.clear()
	player.request_cast(Content.spells.earth_pillar, enemy.position)
	player.health.hurt(9999)
	check(player.casting == null and not player.can_cast(Content.spells.fireball), "Death cancels and blocks casts")
	arena.check_end()
	check(not arena.active and arena.ended and not GameState.in_combat, "Combat end disables actions")
	arena.free()
	await get_tree().process_frame

func test_screens() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	if not OS.is_debug_build():
		main.show_debug()
		check(main.overlay == null, "Release build refuses debug menu")
	for page: String in ["show_creation", "show_hub", "show_build", "show_encounters"]:
		main.call(page)
		await get_tree().process_frame
		check(main.screen.get_child_count() > 0, "Screen renders " + page)
	main.show_shop("spell")
	await get_tree().process_frame
	main.show_shop("gear")
	await get_tree().process_frame
	GameState.run.choices = 1
	main.show_level_choices()
	await get_tree().process_frame
	main.start_combat(0)
	await get_tree().process_frame
	main.show_settings(true)
	check(get_tree().paused, "Pause stops combat")
	main.close_overlay()
	check(not get_tree().paused, "Resume restores combat")
	main.arena.active = true
	main.arena.end_battle(false)
	main.show_reward()
	await get_tree().process_frame
	main.show_completion()
	await get_tree().process_frame
	main.free()

func test_bot_run() -> void:
	# Normal casts, movement, legal purchases, real AI and damage; no debug wins or invulnerability.
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var package: String = args[args.find("--package") + 1] if args.has("--package") else "Winter Warden"
	var difficulty: int = args[args.find("--difficulty") + 1].to_int() if args.has("--difficulty") else 0
	GameState.new_run("Autoplay", 0, package, 9901)
	print("AUTOPLAY package=%s difficulty=%d" % [package, difficulty])
	var successful: int = 0
	var seconds: float = 0.0
	for stage: int in 5:
		var arena: ArenaDirector = ArenaDirector.new()
		add_child(arena)
		arena.begin(stage, difficulty)
		arena.intro = 0
		arena.active = true
		arena.set_process(false)
		for fighter: Fighter in arena.fighters(): fighter.set_physics_process(false)
		var player: PlayerFighter = arena.player
		var elapsed: float = 0.0
		while elapsed < 480 and not arena.ended:
			var target: EnemyFighter = null
			var nearest: float = INF
			for candidate: EnemyFighter in arena.enemies:
				if not candidate.health.dead and player.position.distance_to(candidate.position) < nearest:
					nearest = player.position.distance_to(candidate.position)
					target = candidate
			if target == null:
				arena.check_end()
				if arena.ended: break
				tick(arena, 1.0 / 30, true)
				elapsed += 1.0 / 30
				continue
			player.destination = arena.clamp_position(ArenaDirector.CENTER + Vector2.from_angle(elapsed * 0.53) * 230)
			for effect: Node in arena.effects.get_children():
				if effect is SpellProjectile and effect.team != player.team:
					var offset: Vector2 = player.position - effect.position
					# The rooted Earth build uses anticipatory lateral dodges; the mobile builds keep their route.
					if package == "Winter Warden":
						if offset.length() < 90 and effect.heading.dot(offset.normalized()) > 0.8:
							player.dodge(player.position + effect.heading.orthogonal() * 130)
					elif offset.length() < 90 and effect.heading.dot(offset) > 0 and absf(effect.heading.cross(offset)) < player.body_radius + 8:
						player.dodge(player.destination)
			for enemy: EnemyFighter in arena.enemies:
				if enemy.casting != null and enemy.cast_remaining < 0.2 and SpellGeometry.contains(enemy.casting, enemy.position, enemy.cast_target, player.position, player.body_radius):
					player.dodge(player.destination)
			for id: String in player.loadout:
				var spell: SpellData = Content.spells[id]
				if not player.can_cast(spell): continue
				if spell.targeting == "self_area" and nearest > spell.radius: continue
				if spell.targeting == "self" and player.health.current > player.health.maximum * 0.8: continue
				if spell.targeting not in ["self", "self_area"] and nearest > spell.reach: continue
				player.request_cast(spell, target.position)
				break
			tick(arena, 1.0 / 30, true)
			elapsed += 1.0 / 30
			arena.check_end()
			# Flush finished nodes and deferred signals without advancing simulated combat.
			if int(elapsed * 30) % 15 == 0: await get_tree().process_frame
		seconds += elapsed
		var won: bool = arena.ended and arena.result.get("victory", false)
		print("AUTOPLAY stage=%d victory=%s time=%.1fs hp=%.1f effects=%d" % [stage + 1, won, elapsed, player.health.current, arena.effects.get_child_count()])
		arena.free()
		await get_tree().process_frame
		if not won: break
		successful += 1
		while int(GameState.run.choices) > 0: GameState.choose_bonus("power")
		for id: String in GameState.run.gear_offers:
			if not GameState.run.equipment.has(Content.gear[id].slot) and GameState.purchase("gear", id): GameState.equip_gear(id)
	print("AUTOPLAY completed=%d/5 simulated_combat=%.1fs" % [successful, seconds])
	check(successful == 5, "Full run completes using real combat and legal upgrades: " + package)

