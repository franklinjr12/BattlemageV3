class_name SpellProjectile extends SpellEffect
var heading: Vector2
var travelled: float = 0.0
var trail: Array[Vector2] = []

func configure(caster: Fighter, definition: SpellData, aim: Vector2) -> void:
	super.configure(caster, definition, aim)
	position = caster.position
	heading = SpellGeometry.direction(origin, target)
	if visual_fx != null:
		visual_fx.position = Vector2.ZERO
		visual_fx.rotation = heading.angle()

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
	if trail.size() > 8:
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
	if spell == null:
		return
	var color: Color = Content.colors[spell.element]
	if team == 1:
		color = color.lerp(Color("f28c81"), 0.35)
	if trail.size() >= 2:
		var points := PackedVector2Array()
		for point: Vector2 in trail:
			points.append(point - position)
		draw_polyline(points, Color(color, 0.32), 3.0, true)
	for index: int in trail.size():
		var fade := maxf(0.0, 0.3 - index * 0.035)
		draw_circle(trail[index] - position, maxf(1.0, 3.2 - index * 0.24), Color(color, fade))
