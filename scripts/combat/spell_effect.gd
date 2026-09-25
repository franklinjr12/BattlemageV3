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
var visual_fx: SpellVisual

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
	_create_visual()

func _create_visual() -> void:
	visual_fx = SpellVisual.new()
	add_child(visual_fx)
	var direction := SpellGeometry.direction(origin, target)
	var angle := direction.angle()
	var fx_position := origin
	var fx_scale := 1.0
	match spell.targeting:
		"projectile":
			fx_position = Vector2.ZERO
			fx_scale = 0.82
		"ground":
			fx_position = target
			fx_scale = clampf(spell.radius * area_scale / 30.0, 0.95, 2.7)
		"self_area":
			fx_position = origin
			fx_scale = clampf(spell.radius * area_scale / 30.0, 0.9, 2.4)
		"self":
			fx_position = origin
			fx_scale = 1.05
		_:
			fx_position = origin + direction * minf(spell.reach * 0.38, 68.0)
			fx_scale = clampf(spell.reach / 95.0, 0.9, 1.75)
	visual_fx.configure(spell, team, fx_position, angle, fx_scale, spell.duration > 0.0)

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
		color = color.lerp(Color("f28c81"), 0.4)
	var telegraph_alpha := 0.34 if age < spell.delay else (0.16 if spell.duration > 0.0 else maxf(0.04, 0.2 - (age - spell.delay) * 0.5))
	color.a = telegraph_alpha
	SpellGeometry.draw_shape(self, spell, origin, target, color, area_scale)
	var center: Vector2 = target if spell.targeting == "ground" else origin
	if spell.targeting in ["ground", "self_area", "self"]:
		for i: int in 8:
			var angle: float = TAU * i / 8.0 + age * 0.8
			var point: Vector2 = center + Vector2.from_angle(angle) * spell.radius * area_scale * (0.45 + 0.08 * sin(age * 5.0 + i))
			draw_circle(point, 1.5, Color(color, minf(0.5, telegraph_alpha + 0.12)))
		if team == 1 and age < spell.delay:
			draw_string(ThemeDB.fallback_font, center + Vector2(-4, 5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(color, 0.9))
