class_name SpellVisual extends Node2D

const FRAME_SIZE := Vector2(32, 32)
const FRAME_COUNT := 4

var sprite := AnimatedSprite2D.new()
var glow := AnimatedSprite2D.new()
var particles := GPUParticles2D.new()
var element_color := Color.WHITE
var pulse_radius: float = 14.0
var age: float = 0.0
var persistent: bool = false

func _ready() -> void:
	z_index = 3
	add_child(glow)
	add_child(sprite)
	add_child(particles)
	for item in [sprite, glow]:
		item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		item.centered = true
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	particles.material = additive
	glow.modulate = Color(1, 1, 1, 0.22)
	particles.texture = _particle_texture()

func configure(definition: SpellData, team: int, world_position: Vector2, rotation_angle: float, visual_scale: float, keep_emitting: bool) -> void:
	position = world_position
	rotation = rotation_angle
	persistent = keep_emitting
	element_color = Content.colors.get(definition.element, Color.WHITE)
	if team == 1:
		element_color = element_color.lerp(Color("f28c81"), 0.38)
	pulse_radius = 13.0 * visual_scale
	var texture_path := "res://art/sprites/spells/%s.png" % definition.id
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Missing spell sprite: " + texture_path)
		visible = false
		return
	var frames := SpriteFrames.new()
	frames.add_animation("active")
	frames.set_animation_speed("active", 10.0)
	frames.set_animation_loop("active", true)
	for column: int in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(column * FRAME_SIZE.x, 0), FRAME_SIZE)
		frames.add_frame("active", atlas)
	sprite.sprite_frames = frames
	glow.sprite_frames = frames
	sprite.scale = Vector2.ONE * visual_scale
	glow.scale = Vector2.ONE * visual_scale * 1.38
	sprite.play("active")
	glow.play("active")
	_configure_particles(visual_scale, keep_emitting)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	var pulse := 1.0 + sin(age * 9.0) * 0.06
	glow.scale = sprite.scale * 1.38 * pulse
	glow.modulate = Color(element_color, 0.16 + 0.08 * (0.5 + 0.5 * sin(age * 7.0)))
	queue_redraw()

func _configure_particles(visual_scale: float, keep_emitting: bool) -> void:
	particles.amount = clampi(int(12.0 * visual_scale), 10, 36)
	particles.lifetime = 0.55 if not keep_emitting else 0.8
	particles.one_shot = not keep_emitting
	particles.explosiveness = 0.72 if not keep_emitting else 0.15
	particles.randomness = 0.65
	particles.emitting = true
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = maxf(3.0, 7.0 * visual_scale)
	process.direction = Vector3(0, -1, 0)
	process.spread = 180.0
	process.initial_velocity_min = 8.0 * visual_scale
	process.initial_velocity_max = 24.0 * visual_scale
	process.gravity = Vector3(0, 8.0, 0)
	process.scale_min = 0.6
	process.scale_max = 1.5
	process.color = Color(element_color, 0.92)
	particles.process_material = process

func _draw() -> void:
	var alpha := 0.22 if persistent else maxf(0.08, 0.34 - age * 0.35)
	var ring_size := pulse_radius * (1.0 + 0.08 * sin(age * 8.0))
	draw_arc(Vector2.ZERO, ring_size, 0, TAU, 28, Color(element_color, alpha), 2.0)
	draw_arc(Vector2.ZERO, ring_size * 0.67, age, age + PI * 1.35, 18, Color(element_color.lightened(0.3), alpha * 0.9), 1.0)

static func _particle_texture() -> Texture2D:
	var image := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.set_pixel(2, 1, Color(1, 1, 1, 0.7))
	image.set_pixel(1, 2, Color(1, 1, 1, 0.7))
	image.set_pixel(2, 2, Color.WHITE)
	image.set_pixel(3, 2, Color(1, 1, 1, 0.7))
	image.set_pixel(2, 3, Color(1, 1, 1, 0.7))
	return ImageTexture.create_from_image(image)
