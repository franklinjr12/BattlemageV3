class_name ArenaArt extends RefCounted

# Aseprite-authored tile source. Static composition happens once per project session,
# never as thousands of draw calls each rendered frame.
const TILE_SIZE := 64
const TILE_VARIANTS := 8
static var floor_texture: ImageTexture
static var cached_radius: int = 0
static var prop_textures: Dictionary = {}

static func _make_floor(radius: float) -> void:
	var size: int = ceili(radius * 2.0 / TILE_SIZE) * TILE_SIZE
	var atlas_texture := load("res://art/sprites/tiles/arena_floor.png") as Texture2D
	if atlas_texture == null:
		push_error("Missing Aseprite arena-floor atlas")
		return
	var atlas: Image = atlas_texture.get_image()
	var floor: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	floor.fill(Color.TRANSPARENT)
	var tiles: int = size / TILE_SIZE
	var half: float = size * 0.5
	for ty: int in tiles:
		for tx: int in tiles:
			var tile_mid := Vector2(tx * TILE_SIZE + 32 - half, ty * TILE_SIZE + 32 - half)
			if tile_mid.length() > radius - 50.0:
				continue
			var variant: int = posmod(tx * 17 + ty * 29 + (tx * ty) % 11, TILE_VARIANTS)
			var rect := Rect2i(variant * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
			floor.blit_rect(atlas, rect, Vector2i(tx * TILE_SIZE, ty * TILE_SIZE))
	floor_texture = ImageTexture.create_from_image(floor)
	cached_radius = int(radius)

static func draw_arena(canvas: CanvasItem, center: Vector2, radius: float, time: float) -> void:
	if prop_textures.is_empty():
		for name: String in ["column", "broken_column", "brazier", "crystal", "banner_fire", "banner_ice", "banner_earth", "banner_air"]:
			prop_textures[name] = load("res://art/sprites/props/%s.png" % name)
	if floor_texture == null or cached_radius != int(radius):
		_make_floor(radius)

	# Atmospheric surrounding stone is intentionally much larger than the camera.
	var out: float = radius + 950.0
	canvas.draw_rect(Rect2(center - Vector2.ONE * out, Vector2.ONE * out * 2.0), Color("0b1522"))
	canvas.draw_circle(center + Vector2(0, 15), radius + 57.0, Color("080e19"))
	canvas.draw_circle(center, radius + 42.0, Color("495267"))
	canvas.draw_circle(center, radius + 27.0, Color("8a785a"))
	canvas.draw_circle(center, radius + 16.0, Color("1a2837"))
	canvas.draw_circle(center, radius, Color("304153"))

	if floor_texture != null:
		var size: Vector2 = floor_texture.get_size()
		canvas.draw_texture(floor_texture, center - size * 0.5)

	# A quiet engraved sigil anchors the otherwise unobstructed arena floor.
	canvas.draw_arc(center, 122.0, 0.0, TAU, 96, Color("76898c", 0.29), 2.0)
	canvas.draw_arc(center, 115.0, 0.0, TAU, 96, Color("988366", 0.20), 1.0)
	for i: int in 6:
		var a: float = TAU * i / 6.0 - PI * 0.5
		canvas.draw_line(center + Vector2.from_angle(a) * 30.0, center + Vector2.from_angle(a) * 108.0, Color("8daaaa", 0.19), 2.0)

	# Intermittent perimeter architecture stays beyond traversable bounds.
	canvas.draw_arc(center, radius + 34.0, 0.0, TAU, 160, Color("b49a6b", 0.62), 3.0)
	canvas.draw_arc(center, radius - 9.0, 0.0, TAU, 160, Color("b8ad87", 0.48), 2.0)
	for i: int in 80:
		var a: float = TAU * i / 80.0
		var normal := Vector2.from_angle(a)
		canvas.draw_line(center + normal * (radius + 19), center + normal * (radius + 41), Color("635c57"), 2.0)
	for i: int in 12:
		var a: float = TAU * i / 12.0
		var p: Vector2 = center + Vector2.from_angle(a) * (radius + 75.0)
		canvas.draw_rect(Rect2(p + Vector2(-17, -7), Vector2(34, 31)), Color("111b29"))
		canvas.draw_rect(Rect2(p + Vector2(-13, -15), Vector2(26, 32)), Color("566072"))
		canvas.draw_rect(Rect2(p + Vector2(-15, -19), Vector2(30, 6)), Color("9a8565"))
		canvas.draw_rect(Rect2(p + Vector2(-4, -29 - int(time * 5 + i) % 3), Vector2(8, 15)), Color("ed9757"))
		canvas.draw_rect(Rect2(p + Vector2(-2, -34 - int(time * 7 + i) % 4), Vector2(4, 13)), Color("fff1ba"))
	for i: int in 4:
		var a: float = TAU * i / 4.0 - PI * 0.5
		var p: Vector2 = center + Vector2.from_angle(a) * (radius + 98.0)
		var school: Color = [Color("f59a63"), Color("83d5f5"), Color("d4ba7a"), Color("9de3c5")][i]
		canvas.draw_rect(Rect2(p + Vector2(-17, -31), Vector2(34, 55)), school.darkened(0.63))
		canvas.draw_rect(Rect2(p + Vector2(-20, -34), Vector2(40, 5)), Color("c0a779"))
		canvas.draw_rect(Rect2(p + Vector2(-4, -15), Vector2(8, 21)), school)

	# Aseprite-authored perimeter props. Nonblocking; the combat floor stays open.
	for index: int in 24:
		var a: float = TAU * index / 24.0
		var point: Vector2 = center + Vector2.from_angle(a) * (radius + 175.0)
		var type: String = "column" if index % 4 == 0 else "broken_column" if index % 3 == 0 else "crystal" if index % 5 == 0 else "brazier"
		var texture: Texture2D = prop_textures[type]
		canvas.draw_texture(texture, point - texture.get_size() * Vector2(0.5, 0.85))
	for index: int in 4:
		var a: float = TAU * index / 4.0 - PI * 0.5
		var point: Vector2 = center + Vector2.from_angle(a) * (radius + 114.0)
		var type: String = ["banner_fire", "banner_ice", "banner_earth", "banner_air"][index]
		var texture: Texture2D = prop_textures[type]
		canvas.draw_texture(texture, point - texture.get_size() * Vector2(0.5, 0.1))

	# Faint mosaic rings help the large world feel authored between battles.
	for i: int in 6:
		var a: float = TAU * i / 6.0 + PI / 7.0
		var point: Vector2 = center + Vector2.from_angle(a) * 520.0
		canvas.draw_arc(point, 29.0, 0.0, TAU, 32, Color("76908f", 0.13), 1.0)
		canvas.draw_line(point + Vector2(-13, 0), point + Vector2(13, 0), Color("b49c79", 0.12), 1.0)
