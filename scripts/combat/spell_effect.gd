class_name SpellEffect extends Node2D
var caster_ref: WeakRef
var arena: Node2D
var spell: SpellData
var origin: Vector2
var target: Vector2
var team: int
var stats: Dictionary
var area_scale: float = 1.0
var age: float = 0.0
var next_tick: float = 0.0
var activated: bool = false
var hit_ids: Array[int] = []

func configure(caster: Fighter, definition: SpellData, aim: Vector2) -> void:
	caster_ref = weakref(caster)
	arena = caster.arena
	spell = definition
	origin = caster.position
	target = aim
	team = caster.team
	stats = caster.modifiers.duplicate()
	area_scale = 1.0 + float(stats.get("area", 0.0))
	next_tick = spell.delay

func _physics_process(delta: float) -> void:
	if not arena.active:
		queue_free()
		return
	age += delta
	if spell.tags.has("pull") and age >= spell.delay:
		for fighter: Fighter in arena.fighters():
			if fighter.team != team and not fighter.health.dead and not fighter.health.invulnerable and fighter.position.distance_to(target) < spell.radius * area_scale + fighter.body_radius:
				fighter.position = arena.clamp_position(fighter.position.move_toward(target, delta * 95), fighter.body_radius)
	if age >= next_tick and (not activated or spell.duration > 0.0):
		next_tick += maxf(0.1, spell.tick_interval)
		activated = true
		for fighter: Fighter in arena.fighters():
			if fighter.team == team or fighter.health.dead:
				continue
			if SpellGeometry.contains(spell, origin, target, fighter.position, fighter.body_radius, area_scale):
				apply_hit(fighter)
	if age > spell.delay + maxf(0.28, spell.duration):
		queue_free()
	queue_redraw()

func apply_hit(fighter: Fighter) -> void:
	var caster: Fighter = caster_ref.get_ref() as Fighter
	var event: DamageEvent = DamageEvent.new()
	event.source = self
	event.instigator = caster
	event.amount = spell.damage * (1.0 + float(stats.get("power", 0.0)) + float(stats.get(spell.element.to_lower() + "_damage", 0.0))) * float(stats.get("outgoing_multiplier", 1.0))
	event.element = spell.element
	event.spell_id = spell.id
	event.tags = spell.tags
	event.status = spell.status
	event.status_duration = spell.status_duration * (1.0 + float(stats.get("status_duration", 0.0)) + (float(stats.get("burn_duration", 0.0)) if spell.status == "burn" else 0.0))
	event.status_power = float(stats.get("stagger_power", 0.0)) if spell.status == "stagger" else float(stats.get("chill_strength", 0.0)) if spell.status == "chill" else 0.0
	event.knockback = SpellGeometry.direction(origin, fighter.position) * spell.knockback
	fighter.receive_damage(event)

func _draw() -> void:
	if spell == null:
		return
	var color: Color = Content.colors[spell.element]
	if team == 1:
		color = Color("f28c81")
	if age < spell.delay:
		color.a = 0.8
	else:
		color.a = 0.9 if spell.duration > 0 else maxf(0.0, 1.0 - (age - spell.delay) / 0.3)
	SpellGeometry.draw_shape(self, spell, origin, target, color, area_scale)
	var center: Vector2 = target if spell.targeting == "ground" else origin
	if spell.targeting in ["ground", "self_area", "self"]:
		for i: int in 12:
			var angle: float = TAU * i / 12.0 + age * 0.5
			var point: Vector2 = center + Vector2.from_angle(angle) * spell.radius * area_scale * (0.35 + fmod(age + i * 0.17, 0.6))
			draw_rect(Rect2(point, Vector2(4, 4)), color)
		if team == 1:
			draw_string(ThemeDB.fallback_font, center + Vector2(-4, 5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)
