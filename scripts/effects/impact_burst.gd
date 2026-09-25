class_name ImpactBurst extends Node2D

var burst_color: Color = Color.WHITE
var burst_radius: float = 24.0
var lifetime: float = 0.42
var age: float = 0.0
var particles := GPUParticles2D.new()
var sparks := GPUParticles2D.new()

func _ready() -> void:
	z_index = 8
	add_child(particles)
	add_child(sparks)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = additive
	sparks.material = additive
	particles.texture = _particle_texture(false)
	sparks.texture = _particle_texture(true)

func configure(point: Vector2, color: Color, radius: float) -> void:
	position = point
	burst_color = color
	burst_radius = maxf(10.0, radius)
	_setup_particles()
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= lifetime:
		queue_free()

func _setup_particles() -> void:
	var scale_factor := clampf(burst_radius / 24.0, 0.65, 2.2)
	particles.amount = clampi(int(15.0 * scale_factor), 10, 34)
	particles.lifetime = 0.34
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.randomness = 0.55
	particles.emitting = true
	var smoke := ParticleProcessMaterial.new()
	smoke.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 3.0 * scale_factor
	smoke.direction = Vector3(0, -1, 0)
	smoke.spread = 180.0
	smoke.initial_velocity_min = 18.0 * scale_factor
	smoke.initial_velocity_max = 48.0 * scale_factor
	smoke.gravity = Vector3(0, 32.0, 0)
	smoke.scale_min = 0.8
	smoke.scale_max = 1.8
	smoke.color = Color(burst_color, 0.85)
	particles.process_material = smoke

	sparks.amount = clampi(int(9.0 * scale_factor), 6, 20)
	sparks.lifetime = 0.25
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.randomness = 0.35
	sparks.emitting = true
	var spark_process := ParticleProcessMaterial.new()
	spark_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_process.emission_sphere_radius = 2.0
	spark_process.direction = Vector3(1, 0, 0)
	spark_process.spread = 180.0
	spark_process.initial_velocity_min = 45.0 * scale_factor
	spark_process.initial_velocity_max = 95.0 * scale_factor
	spark_process.gravity = Vector3(0, 85.0, 0)
	spark_process.scale_min = 0.45
	spark_process.scale_max = 0.9
	spark_process.color = burst_color.lightened(0.3)
	sparks.process_material = spark_process

func _draw() -> void:
	var progress := clampf(age / lifetime, 0.0, 1.0)
	var alpha := 1.0 - progress
	var outer := lerpf(4.0, burst_radius, ease(progress, -1.7))
	var inner := outer * 0.58
	draw_circle(Vector2.ZERO, maxf(0.0, 7.0 * (1.0 - progress)), Color(burst_color.lightened(0.35), alpha * 0.28))
	draw_arc(Vector2.ZERO, outer, 0, TAU, 28, Color(burst_color, alpha * 0.72), maxf(1.0, 3.0 * (1.0 - progress)))
	draw_arc(Vector2.ZERO, inner, age * 7.0, age * 7.0 + PI * 1.4, 18, Color(burst_color.lightened(0.45), alpha * 0.55), 1.5)

static func _particle_texture(streak: bool) -> Texture2D:
	var image := Image.create(7 if streak else 5, 5, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	if streak:
		for x: int in 7:
			image.set_pixel(x, 2, Color(1, 1, 1, 0.25 + 0.12 * x))
		image.set_pixel(6, 1, Color(1, 1, 1, 0.65))
		image.set_pixel(6, 3, Color(1, 1, 1, 0.65))
	else:
		image.set_pixel(2, 1, Color(1, 1, 1, 0.6))
		image.set_pixel(1, 2, Color(1, 1, 1, 0.6))
		image.set_pixel(2, 2, Color.WHITE)
		image.set_pixel(3, 2, Color(1, 1, 1, 0.6))
		image.set_pixel(2, 3, Color(1, 1, 1, 0.6))
	return ImageTexture.create_from_image(image)
