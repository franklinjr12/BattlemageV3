class_name SpellProjectile extends SpellEffect
var heading: Vector2
var travelled: float = 0.0
var trail: Array[Vector2] = []

func configure(caster: Fighter, definition: SpellData, aim: Vector2) -> void:
	super.configure(caster, definition, aim)
	position = caster.position
	heading = SpellGeometry.direction(origin, target)

func _physics_process(delta: float) -> void:
	if not arena.active:
		queue_free()
		return
	age += delta
	var previous: Vector2 = position
	var step: float = minf(spell.projectile_speed * delta, spell.reach - travelled)
	position += heading * step
	travelled += step
	trail.push_front(position)
	if trail.size() > 7:
		trail.pop_back()
	# Swept segment collision prevents fast bolts tunnelling through actors.
	var candidates: Array[Fighter] = []
	for fighter: Fighter in arena.fighters():
		if fighter.team == team or fighter.health.dead or hit_ids.has(fighter.get_instance_id()):
			continue
		if Geometry2D.get_closest_point_to_segment(fighter.position, previous, position).distance_to(fighter.position) < fighter.body_radius + 6.0:
			candidates.append(fighter)
	candidates.sort_custom(func(a: Fighter, b: Fighter) -> bool: return previous.distance_squared_to(a.position) < previous.distance_squared_to(b.position))
	for fighter: Fighter in candidates:
		apply_hit(fighter)
		hit_ids.append(fighter.get_instance_id())
		if spell.tags.has("explode"):
			for other: Fighter in arena.fighters():
				if other != fighter and other.team != team and not other.health.dead and other.position.distance_to(fighter.position) <= spell.radius * area_scale + other.body_radius:
					apply_hit(other)
			arena.burst(fighter.position, Content.colors[spell.element], spell.radius * area_scale)
		if not spell.tags.has("pierce"):
			queue_free()
			return
	if travelled >= spell.reach or age > 6.0 or not arena.inside(position, -20.0):
		queue_free()
	queue_redraw()

func _draw() -> void:
	var color: Color = Content.colors[spell.element]
	for i: int in trail.size():
		draw_rect(Rect2(trail[i] - position - Vector2(3, 3), Vector2(6, 6)), Color(color, 0.6 - i * 0.07))
	draw_rect(Rect2(-5, -5, 10, 10), color)
	draw_rect(Rect2(-2, -2, 4, 4), Color("fff1d3"))
	if team == 1:
		draw_arc(Vector2.ZERO, 9, 0, TAU, 8, Color("ff9286"), 2)
