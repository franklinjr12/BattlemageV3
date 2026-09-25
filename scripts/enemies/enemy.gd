class_name EnemyFighter extends Fighter
var data: EnemyData
var decision_timer: float = 0.0
var dodge_clock: float = 0.0
var attack_cursor: int = 0
var ai_state: String = "approach"
var champion_phase: bool = false
var aggression: float = 1.0
var last_player_position: Vector2
var observed_velocity: Vector2 = Vector2.ZERO
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(owner_arena: Node2D, definition: EnemyData, difficulty: Dictionary, scaling: float, random_seed: int) -> void:
	arena = owner_arena
	data = definition
	team = 1
	loadout = definition.attacks.duplicate()
	modifiers = {"power": definition.power, "outgoing_multiplier": float(difficulty.damage)}
	move_speed = definition.speed
	health.reset(definition.max_health * float(difficulty.health) * scaling)
	statuses.resistance = definition.stagger_resistance
	statuses.control_resistance = 0.55 if definition.id == "champion" else 1.0
	visual = definition.id
	refresh_visual()
	tint = definition.color
	display_name = definition.display_name
	body_radius = 22.0 if definition.profile == "tank" else 13.0
	aggression = definition.aggression * float(difficulty.aggression)
	rng.seed = random_seed
	decision_timer = rng.randf_range(0.6, 1.3)
	dodge_clock = definition.dodge_interval
	dodge_timers = [0.0]

func think(delta: float) -> void:
	if statuses.rooted():
		ai_state = "stunned"
		return
	var player: Fighter = arena.player
	if player.health.dead:
		return
	if data.id == "champion" and not champion_phase and health.current < health.maximum * 0.5:
		champion_phase = true
		move_speed *= 1.2
		aggression *= 1.25
		barrier = 80.0
		barrier_time = 12.0
		arena.float_text(position, "SECOND WIND", Color("f3d581"))
		Sound.cue("boss")
	if last_player_position != Vector2.ZERO:
		observed_velocity = observed_velocity.lerp((player.position - last_player_position) / maxf(delta, .001), 0.08)
	last_player_position = player.position
	var distance: float = position.distance_to(player.position)
	var toward: Vector2 = (player.position - position).normalized()
	var preferred: float = data.preferred_range
	ai_state = "approach"
	if distance > preferred + 24.0:
		destination = player.position - toward * preferred
	elif distance < preferred - 35.0 and data.profile in ["mage", "ranged", "support"]:
		ai_state = "retreat"
		destination = position - toward * 80.0
	else:
		ai_state = "reposition"
		destination = position + toward.orthogonal() * (35.0 if int(elapsed / 3.0) % 2 == 0 else -35.0)
	if data.profile in ["melee", "tank", "fast"] and distance < preferred + 15.0:
		destination = position
	# Visible persistent danger influences navigation, never the player's input.
	if data.profile == "mage":
		for effect: Node in arena.effects.get_children():
			if effect is SpellEffect and effect.team != team and effect.spell.targeting == "ground" and effect.spell.duration > 0.0 and position.distance_to(effect.target) < effect.spell.radius * effect.area_scale + 35:
				destination = position + (position - effect.target).normalized() * 110.0
		dodge_clock -= delta
		if dodge_clock <= 0.0:
			dodge_clock = data.dodge_interval + rng.randf_range(-1, 2)
			if rng.randf() < 0.65:
				dodge(arena.clamp_position(position + toward.orthogonal() * 120.0, body_radius))
	for other: Fighter in arena.fighters():
		if other == self or other.health.dead:
			continue
		var offset: Vector2 = position - other.position
		var minimum: float = body_radius + other.body_radius + 3.0
		if offset.length() < minimum:
			position = arena.clamp_position(position + offset.normalized() * delta * 50.0, body_radius)
	destination = arena.clamp_position(destination, body_radius)
	decision_timer -= delta
	if decision_timer > 0.0:
		return
	decision_timer = rng.randf_range(0.3, 0.6) / aggression
	for index: int in loadout.size():
		var slot: int = (attack_cursor + index) % loadout.size()
		var spell: SpellData = Content.spells[loadout[slot]]
		if not can_cast(spell):
			continue
		if spell.targeting == "self" and health.current > health.maximum * 0.85:
			continue
		if spell.targeting == "self_area" and distance > spell.radius + player.body_radius:
			continue
		if spell.targeting not in ["self", "self_area"] and distance > spell.reach:
			continue
		var target: Vector2 = player.position
		if spell.targeting in ["projectile", "ground"]:
			# Imperfect lead from observed movement. Aim stays fixed during wind-up.
			target += observed_velocity.limit_length(170) * 0.28
			target = arena.clamp_position(target)
			if spell.targeting == "ground":
				target = position + (target - position).limit_length(spell.reach)
		if spell.targeting == "ground":
			target = arena.clamp_position(target + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12)))
		if request_cast(spell, target):
			attack_cursor = (slot + 1) % loadout.size()
			ai_state = "attack"
			break
