class_name Fighter extends Node2D
signal died(fighter: Fighter)
signal spell_cast(spell: SpellData)
var arena: Node2D
var health: Vitality = Vitality.new()
var statuses: StatusSet = StatusSet.new()
var team: int = 0
var modifiers: Dictionary = {}
var loadout: PackedStringArray = []
var cooldowns: Dictionary = {}
var move_speed: float = 160.0
var body_radius: float = 13.0
var destination: Vector2
var facing: Vector2 = Vector2.RIGHT
var moving: bool = false
var casting: SpellData
var cast_remaining: float = 0.0
var cast_total: float = 0.0
var cast_target: Vector2
var flash: float = 0.0
var dodge_time: float = 0.0
var dodge_direction: Vector2
var dodge_timers: Array[float] = [0.0, 0.0]
var debug_invulnerable: bool = false
var barrier: float = 0.0
var barrier_time: float = 0.0
var guard_time: float = 0.0
var visual: String = "mage"
var tint: Color = Color("83d5f5")
var display_name: String = "Battlemage"
var elapsed: float = 0.0
var fighter_sprite: FighterSprite

func _ready() -> void:
	health.died.connect(_on_death)
	destination = position
	fighter_sprite = FighterSprite.new()
	add_child(fighter_sprite)
	refresh_visual()

func _physics_process(delta: float) -> void:
	if arena == null or not arena.active or health.dead:
		return
	elapsed += delta
	flash = maxf(0.0, flash - delta)
	guard_time = maxf(0.0, guard_time - delta)
	barrier_time = maxf(0.0, barrier_time - delta)
	if barrier_time <= 0.0:
		barrier = 0.0
	for id: String in cooldowns:
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)
	for index: int in dodge_timers.size():
		dodge_timers[index] = maxf(0.0, dodge_timers[index] - delta)
	health.invulnerable = debug_invulnerable or dodge_time > 0.06
	for event: DamageEvent in statuses.update(delta):
		receive_damage(event)
	if health.dead:
		return
	if statuses.rooted():
		cancel_cast()
	if dodge_time > 0.0:
		dodge_time = maxf(0.0, dodge_time - delta)
		position = arena.clamp_position(position + dodge_direction * 560.0 * delta, body_radius)
		if dodge_time <= 0.0:
			destination = position
	elif casting != null:
		cast_remaining -= delta
		if cast_remaining <= 0.0:
			var ready_spell: SpellData = casting
			casting = null
			execute_spell(ready_spell, cast_target)
	else:
		think(delta)
		moving = position.distance_to(destination) > 3.0 and not statuses.rooted()
		if moving:
			facing = (destination - position).normalized()
			position = arena.clamp_position(position.move_toward(destination, move_speed * statuses.movement_factor() * delta), body_radius)
	update_visual_state()
	queue_redraw()

func think(_delta: float) -> void:
	pass

func can_cast(spell: SpellData) -> bool:
	return arena != null and arena.active and not health.dead and casting == null and dodge_time <= 0.0 and not statuses.rooted() and float(cooldowns.get(spell.id, 0.0)) <= 0.0

func valid_target(spell: SpellData, target: Vector2) -> bool:
	if spell.targeting == "ground":
		return position.distance_to(target) <= spell.reach and arena.inside(target)
	return true

func request_cast(spell: SpellData, target: Vector2) -> bool:
	if not can_cast(spell) or not valid_target(spell, target):
		return false
	cast_target = target
	facing = SpellGeometry.direction(position, target)
	cast_total = spell.cast_time * maxf(0.25, 1.0 - float(modifiers.get("cast_speed", 0.0)))
	# Enemy instant abilities get a minimum wind-up, sharing exact targeting geometry.
	if team == 1:
		cast_total = maxf(0.6, cast_total)
	if cast_total > 0.0:
		casting = spell
		cast_remaining = cast_total
	else:
		execute_spell(spell, target)
	return true

func cancel_cast() -> void:
	casting = null
	cast_remaining = 0.0

func execute_spell(spell: SpellData, target: Vector2) -> void:
	if health.dead or not arena.active:
		return
	cooldowns[spell.id] = GameState.scaled_cooldown(spell, modifiers)
	if spell.tags.has("barrier"):
		barrier = 45.0 * (1.0 + float(modifiers.get("barrier", 0.0)))
		barrier_time = spell.duration
	if spell.tags.has("guard"):
		guard_time = spell.duration
	var effect: Node2D = spell.spell_scene.instantiate()
	effect.configure(self, spell, target)
	arena.effects.add_child(effect)
	if spell.tags.has("dash"):
		position = arena.clamp_position(position + SpellGeometry.direction(position, target) * minf(spell.reach, position.distance_to(target)), body_radius)
		destination = position
	Sound.cue(spell.element.to_lower(), -5.0 if team == 1 else 0.0)
	spell_cast.emit(spell)

func dodge(target: Vector2) -> bool:
	if health.dead or not arena.active or dodge_time > 0.0 or statuses.rooted():
		return false
	var charge: int = -1
	for index: int in dodge_timers.size():
		if dodge_timers[index] <= 0.0:
			charge = index
			break
	if charge == -1:
		return false
	cancel_cast()
	dodge_timers[charge] = float(Content.economy.dodge_recharge) * maxf(0.35, 1.0 - float(modifiers.get("dodge_recharge", 0.0)))
	dodge_time = 0.23
	dodge_direction = SpellGeometry.direction(position, target)
	health.invulnerable = true
	Sound.cue("dodge", -5.0)
	return true

func receive_damage(event: DamageEvent) -> float:
	if health.dead or health.invulnerable or not arena.active:
		return 0.0
	var value: float = event.amount
	if event.tags.has("consume_burn") and statuses.active.has("burn"):
		value += float(statuses.active.burn.stacks) * 18.0
		statuses.active.erase("burn")
		arena.float_text(position, "DETONATE", Color("f59a63"))
	if event.tags.has("heavy") and statuses.active.has("freeze"):
		value *= 1.6
		statuses.active.erase("freeze")
		arena.float_text(position, "SHATTER", Color("83d5f5"))
	if event.tags.has("controlled_bonus") and (statuses.rooted() or statuses.active.has("chill")):
		value *= 1.35
	value *= maxf(0.2, 1.0 - float(modifiers.get("armor", 0.0)))
	if guard_time > 0.0:
		value *= 0.45
	var absorbed: float = minf(barrier, value)
	barrier -= absorbed
	value -= absorbed
	var dealt: float = health.hurt(value)
	if not health.dead:
		statuses.apply(event.status, event.status_duration, event.instigator, event.status_power)
		if statuses.rooted():
			cancel_cast()
		position = arena.clamp_position(position + event.knockback, body_radius)
	var impact_ready := flash <= 0.0
	flash = 0.12
	if dealt > 0:
		if impact_ready:
			var impact_color: Color = Content.colors.get(event.element, tint)
			arena.burst(position + Vector2(0, -8), impact_color, 18.0 if event.tags.has("heavy") else 12.0)
		arena.float_text(position + Vector2(0, -22), str(ceili(dealt)), Color("ff9482") if team == 0 else Color("f7e6bd"))
		Sound.cue("hit", -14.0)
		if event.tags.has("heavy"):
			arena.shake = 5.0
	return dealt

func _on_death() -> void:
	cancel_cast()
	moving = false
	statuses.clear()
	Sound.cue("death", -8.0)
	if arena != null:
		arena.burst(position + Vector2(0, -8), tint, maxf(24.0, body_radius * 1.7))
	update_visual_state()
	died.emit(self)
	queue_redraw()

func refresh_visual() -> void:
	if fighter_sprite == null:
		return
	var key: String = "player" if team == 0 else visual
	fighter_sprite.setup(key)

func update_visual_state() -> void:
	if fighter_sprite == null:
		return
	var key: String = "player" if team == 0 else visual
	if fighter_sprite.visual_key != key:
		fighter_sprite.setup(key)
	var state: StringName = &"idle"
	if health.dead:
		state = &"death"
	elif flash > 0.0:
		state = &"hurt"
	elif casting != null:
		state = &"cast"
	elif moving or dodge_time > 0.0:
		state = &"move"
	fighter_sprite.set_state(state, facing, statuses.active.has("freeze"), flash > 0.0)

func _draw() -> void:
	draw_ellipse_shadow()
	if dodge_time > 0.0:
		for index: int in 3:
			var back := -dodge_direction * float(9 + index * 9)
			draw_line(back + Vector2(-7, -18), back + Vector2(7, -18), Color(tint, 0.2 - index * 0.045), 3.0)
	if barrier > 0.0 or guard_time > 0.0:
		var shield_color := Color("aadff2") if barrier > 0.0 else Color("d4ba7a")
		draw_circle(Vector2(0, -9), 27, Color(shield_color, 0.08))
		draw_arc(Vector2(0, -9), 28, -PI * 0.2 + elapsed, PI * 1.55 + elapsed, 30, Color(shield_color, 0.78), 2.0)
		draw_arc(Vector2(0, -9), 24, PI + elapsed * 0.7, TAU + elapsed * 0.7, 22, Color(shield_color, 0.35), 1.0)
	if statuses.active.has("burn"):
		for index: int in 5:
			var phase := elapsed * 8.0 + index * 1.7
			var point := Vector2(-12 + index * 6, -31 - fmod(phase * 3.0, 9.0))
			draw_circle(point, 2.5, Color("f59a63"))
			draw_circle(point + Vector2(0, -3), 1.5, Color("ffd06a"))
	if statuses.active.has("chill") or statuses.rooted():
		draw_arc(Vector2(0, -5), 23, 0, TAU, 12, Color("b4e8ff"), 2.0)
		for index: int in 6:
			var angle := TAU * float(index) / 6.0 + elapsed * 0.4
			draw_circle(Vector2(0, -5) + Vector2.from_angle(angle) * 26.0, 1.5, Color("e3f7ff"))
	if team == 1:
		draw_rect(Rect2(-22, -47, 44, 4), Color("222c3a"))
		draw_rect(Rect2(-22, -47, 44 * health.current / health.maximum, 4), Color("d78478"))
	if casting != null and cast_total > 0.0:
		draw_rect(Rect2(-22, -53, 44, 3), Color(0.06, 0.08, 0.12, 0.8))
		draw_rect(Rect2(-22, -53, 44 * (1.0 - cast_remaining / cast_total), 3), Color("ffe0a0"))

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, body_radius * 1.3, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
