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

func _ready() -> void:
	health.died.connect(_on_death)
	destination = position

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
	flash = 0.12
	if dealt > 0:
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
	died.emit(self)
	queue_redraw()

func _draw() -> void:
	if health.dead:
		draw_circle(Vector2.ZERO, body_radius, Color("2e3339"))
		draw_line(Vector2(-8, -4), Vector2(8, 4), Color("798085"), 3)
		return
	var color: Color = Color.WHITE if flash > 0.0 else tint
	if statuses.active.has("freeze"):
		color = Color("c9efff")
	var bob: float = roundf(sin(elapsed * (12 if moving else 3)) * (2 if moving else 1))
	var offset: Vector2 = Vector2(0, bob)
	draw_set_transform(offset)
	draw_ellipse_shadow()
	if dodge_time > 0.0:
		for index: int in 3:
			draw_rect(Rect2(-dodge_direction * float(index * 9) + Vector2(-8, -15), Vector2(16, 24)), Color(color, 0.13))
	if visual in ["mage", "champion"]:
		pixel(Vector2(-9, -11), Vector2(18, 22), color.darkened(0.4))
		pixel(Vector2(-12, 3), Vector2(24, 9), color.darkened(0.18))
		pixel(Vector2(-7, -20), Vector2(14, 13), Color("e5bea0"))
		pixel(Vector2(-10, -23), Vector2(20, 7), color)
		pixel(Vector2(-7, -29), Vector2(14, 8), color)
		pixel(Vector2(-4, -34), Vector2(8, 7), color)
		pixel(Vector2(-5, -15), Vector2(10, 3), Color("263148"))
		pixel(Vector2(facing.x * 3, -14), Vector2(3, 2), Color("fff3d6"))
		pixel(Vector2(-8, 12), Vector2(6, 4), Color("2a2832"))
		pixel(Vector2(3, 12), Vector2(6, 4), Color("2a2832"))
		var hand: float = 15.0 if facing.x >= 0 else -18.0
		pixel(Vector2(hand, -18), Vector2(3, 31), Color("9c8056"))
		pixel(Vector2(hand - 3, -24), Vector2(9, 8), color.lightened(0.4))
		if visual == "champion":
			pixel(Vector2(-12, -25), Vector2(24, 4), Color("f3d581"))
			for x: int in [-10, -2, 6]:
				pixel(Vector2(x, -30), Vector2(4, 5), Color("f3d581"))
	elif visual == "golem":
		pixel(Vector2(-18, -22), Vector2(36, 34), color.darkened(0.2))
		pixel(Vector2(-13, -31), Vector2(26, 15), color)
		pixel(Vector2(-25, -10), Vector2(10, 23), color)
		pixel(Vector2(15, -10), Vector2(10, 23), color)
		pixel(Vector2(-9, -25), Vector2(5, 3), Color("ffd585"))
		pixel(Vector2(4, -25), Vector2(5, 3), Color("ffd585"))
		pixel(Vector2(-3, -15), Vector2(6, 17), color.lightened(0.5))
	elif visual == "spitter":
		pixel(Vector2(-16, -17), Vector2(31, 27), color.darkened(0.2))
		pixel(Vector2(-12, -23), Vector2(22, 14), color)
		pixel(Vector2(-18, 7), Vector2(10, 7), color)
		pixel(Vector2(7, 7), Vector2(10, 7), color)
		pixel(Vector2(facing.x * 12 - 7, -12), Vector2(15, 13), Color("293b38"))
		pixel(Vector2(facing.x * 13 - 4, -8), Vector2(8, 6), Color("c4df91"))
		pixel(Vector2(-7, -20), Vector2(4, 3), Color("fff0b9"))
		pixel(Vector2(5, -20), Vector2(4, 3), Color("fff0b9"))
	elif visual == "wisp":
		pixel(Vector2(-12, -19), Vector2(24, 22), color.darkened(0.2))
		pixel(Vector2(-8, -27), Vector2(16, 13), color)
		pixel(Vector2(-4, -22), Vector2(8, 5), Color("fcebc4"))
		pixel(Vector2(-7, 3), Vector2(5, 9), color)
		pixel(Vector2(3, 3), Vector2(5, 13), color)
	else:
		pixel(Vector2(-14, -13), Vector2(28, 21), color.darkened(0.15))
		pixel(Vector2(facing.x * 9 - 7, -20), Vector2(14, 13), color)
		pixel(Vector2(-13, -22), Vector2(5, 10), color)
		pixel(Vector2(8, -22), Vector2(5, 10), color)
		for x: int in [-13, 7]:
			pixel(Vector2(x, 7), Vector2(6, 7), color)
		pixel(Vector2(facing.x * 9 - 3, -16), Vector2(6, 3), Color("fff0b9"))
		if visual == "skitter":
			for y: int in [-10, 0, 10]:
				pixel(Vector2(-22, y), Vector2(8, 3), color)
				pixel(Vector2(14, y), Vector2(8, 3), color)
	if barrier > 0.0 or guard_time > 0.0:
		draw_arc(Vector2(0, -8), 29, 0, TAU, 24, Color("aadff2") if barrier > 0 else Color("d4ba7a"), 2)
	if statuses.active.has("burn"):
		for x: int in [-10, 0, 10]:
			pixel(Vector2(x, -36 - int(elapsed * 8 + x) % 5), Vector2(4, 9), Color("f59a63"))
	if statuses.active.has("chill") or statuses.rooted():
		draw_arc(Vector2.ZERO, 22, 0, TAU, 8, Color("b4e8ff"), 2)
	if team == 1:
		draw_rect(Rect2(-22, -43, 44, 4), Color("222c3a"))
		draw_rect(Rect2(-22, -43, 44 * health.current / health.maximum, 4), Color("d78478"))
	if casting != null:
		draw_rect(Rect2(-22, -49, 44 * (1.0 - cast_remaining / cast_total), 3), Color("ffe0a0"))
	draw_set_transform(Vector2.ZERO)

func pixel(point: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(point - Vector2.ONE, size + Vector2(2, 2)), Color("151a25"))
	draw_rect(Rect2(point, size), color)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, body_radius * 1.3, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
