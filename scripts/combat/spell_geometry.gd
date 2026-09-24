class_name SpellGeometry extends RefCounted

static func direction(origin: Vector2, target: Vector2) -> Vector2:
	return (target - origin).normalized() if origin.distance_squared_to(target) > 0.01 else Vector2.RIGHT

static func contains(spell: SpellData, origin: Vector2, target: Vector2, point: Vector2, body_radius: float, area_scale: float = 1.0) -> bool:
	var aim: Vector2 = direction(origin, target)
	var offset: Vector2 = point - origin
	match spell.targeting:
		"ground":
			return point.distance_to(target) <= spell.radius * area_scale + body_radius
		"self_area", "self":
			return offset.length() <= spell.radius * area_scale + body_radius
		"cone":
			return offset.length() <= spell.reach + body_radius and absf(aim.angle_to(offset)) <= deg_to_rad(spell.cone_angle * 0.5) + body_radius / maxf(20.0, offset.length())
		"directional":
			var end: Vector2 = origin + aim * (minf(spell.reach, origin.distance_to(target)) if spell.tags.has("dash") else spell.reach)
			return Geometry2D.get_closest_point_to_segment(point, origin, end).distance_to(point) <= spell.radius * area_scale + body_radius
	return false

static func draw_shape(canvas: CanvasItem, spell: SpellData, origin: Vector2, target: Vector2, color: Color, area_scale: float = 1.0, fill: bool = true) -> void:
	var aim: Vector2 = direction(origin, target)
	var tint: Color = Color(color, 0.12 if fill else 0.04)
	match spell.targeting:
		"ground", "self_area", "self":
			var center: Vector2 = target if spell.targeting == "ground" else origin
			var radius: float = spell.radius * area_scale
			canvas.draw_circle(center, radius, tint)
			canvas.draw_arc(center, radius, 0.0, TAU, 64, color, 2.0)
			canvas.draw_line(center - Vector2(7, 0), center + Vector2(7, 0), color, 2.0)
			canvas.draw_line(center - Vector2(0, 7), center + Vector2(0, 7), color, 2.0)
		"cone":
			var points: PackedVector2Array = [origin]
			for i: int in 25:
				points.append(origin + aim.rotated(deg_to_rad(-spell.cone_angle * 0.5 + spell.cone_angle * i / 24.0)) * spell.reach)
			canvas.draw_colored_polygon(points, tint)
			points.append(origin)
			canvas.draw_polyline(points, color, 2.0)
		"directional", "projectile":
			var end: Vector2 = origin + aim * (minf(spell.reach, origin.distance_to(target)) if spell.tags.has("dash") else spell.reach)
			var width: float = spell.radius * area_scale if spell.targeting == "directional" else 5.0
			var normal: Vector2 = aim.orthogonal() * width
			canvas.draw_colored_polygon(PackedVector2Array([origin + normal, end + normal, end - normal, origin - normal]), tint)
			canvas.draw_line(origin + normal, end + normal, color, 1.5)
			canvas.draw_line(origin - normal, end - normal, color, 1.5)
			canvas.draw_line(end, end - aim.rotated(0.5) * 15, color, 2.0)
			canvas.draw_line(end, end - aim.rotated(-0.5) * 15, color, 2.0)
