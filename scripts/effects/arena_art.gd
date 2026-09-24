class_name ArenaArt extends RefCounted
static func draw_arena(canvas: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	canvas.draw_rect(Rect2(0, 0, 1280, 800), Color("0a111c"))
	# Distant stonework and inset spectator galleries remain outside the open floor.
	for y: int in range(55, 760, 38):
		for x: int in range(220, 1070, 70):
			var point: Vector2 = Vector2(x + (35 if (y / 38) % 2 else 0), y)
			if point.distance_to(center) > radius + 40:
				canvas.draw_rect(Rect2(point, Vector2(66, 34)), Color("101b29"))
	canvas.draw_circle(center + Vector2(0, 15), radius + 39, Color("050c14"))
	canvas.draw_circle(center, radius + 30, Color("343c44"))
	canvas.draw_circle(center, radius + 23, Color("172734"))
	canvas.draw_arc(center, radius + 28, 0, TAU, 128, Color("6c6860"), 3.0)
	for i: int in 48:
		var angle: float = TAU * i / 48
		canvas.draw_line(center + Vector2.from_angle(angle) * (radius + 4), center + Vector2.from_angle(angle) * (radius + 28), Color("776f60"), 2.0)
	canvas.draw_circle(center, radius + 5, Color("887959"))
	canvas.draw_circle(center, radius, Color("273039"))
	# A clipped, staggered grid of worn paving stones.
	for y: int in range(-280, 285, 26):
		for x: int in range(-280, 290, 46):
			var offset: Vector2 = Vector2(x + (23 if (y / 26) % 2 else 0), y)
			if maxf(offset.length(), (offset + Vector2(42, 22)).length()) < radius - 16:
				var shade: float = float(posmod(x * 7 + y * 11, 13)) / 250.0
				canvas.draw_rect(Rect2(center + offset, Vector2(42, 22)), Color(0.17 + shade, 0.2 + shade, 0.22 + shade))
	canvas.draw_arc(center, radius - 12, 0, TAU, 128, Color("54544d"), 2.0)
	canvas.draw_arc(center, 108, 0, TAU, 96, Color("52534a"), 2.0)
	canvas.draw_arc(center, 100, 0, TAU, 96, Color("444c48"), 1.0)
	var sigil: PackedVector2Array = []
	for i: int in 7:
		sigil.append(center + Vector2.from_angle(-PI * 0.5 + i * TAU / 6) * (83 if i % 2 == 0 else 37))
	canvas.draw_polyline(sigil, Color("68604d"), 2)
	for i: int in 8:
		var angle: float = i * TAU / 8.0 + PI / 8
		var point: Vector2 = center + Vector2.from_angle(angle) * (radius + 47)
		canvas.draw_rect(Rect2(point + Vector2(-12, -4), Vector2(24, 23)), Color("0a111a"))
		canvas.draw_rect(Rect2(point + Vector2(-9, -7), Vector2(18, 20)), Color("535351"))
		canvas.draw_rect(Rect2(point + Vector2(-11, -10), Vector2(22, 6)), Color("8c7960"))
		canvas.draw_circle(point + Vector2(0, -13), 19, Color(0.92, 0.55, 0.22, 0.035))
		canvas.draw_rect(Rect2(point + Vector2(-5, -20), Vector2(10, 10)), Color("de9254"))
		canvas.draw_rect(Rect2(point + Vector2(-2, -25 - int(time * 7 + i) % 3), Vector2(4, 12)), Color("ffdb8a"))
	# Cardinal banners, each school marked by a distinct pixel glyph.
	for i: int in 4:
		var point: Vector2 = center + Vector2.from_angle(i * TAU / 4.0 - PI * 0.5) * (radius + 58)
		var color: Color = [Color("f59a63"), Color("83d5f5"), Color("d4ba7a"), Color("9de3c5")][i]
		canvas.draw_rect(Rect2(point + Vector2(-14, -20), Vector2(28, 43)), color.darkened(0.65))
		canvas.draw_rect(Rect2(point + Vector2(-18, -23), Vector2(36, 4)), Color("887759"))
		canvas.draw_rect(Rect2(point + Vector2(-4, -9), Vector2(8, 15)), color)
