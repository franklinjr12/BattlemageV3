class_name FighterSprite extends AnimatedSprite2D

const FRAME_SIZE := Vector2(48, 48)
const FRAME_COUNT := 4
const ANIMATIONS := {
	"idle": {"row": 0, "fps": 4.5, "loop": true},
	"move": {"row": 1, "fps": 9.0, "loop": true},
	"cast": {"row": 2, "fps": 9.0, "loop": true},
	"hurt": {"row": 3, "fps": 13.0, "loop": true},
	"death": {"row": 4, "fps": 7.0, "loop": false},
}

var visual_key: String = ""
var state: StringName = &"idle"

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2(0, -14)
	centered = true
	z_index = 2

func setup(key: String) -> void:
	if key == visual_key and sprite_frames != null:
		return
	visual_key = key
	var texture_path := "res://art/sprites/actors/%s.png" % key
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Missing fighter sprite: " + texture_path)
		visible = false
		return
	visible = true
	var frames := SpriteFrames.new()
	for animation_name: String in ANIMATIONS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(ANIMATIONS[animation_name].fps))
		frames.set_animation_loop(animation_name, bool(ANIMATIONS[animation_name].loop))
		var row: int = int(ANIMATIONS[animation_name].row)
		for column: int in FRAME_COUNT:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(column * FRAME_SIZE.x, row * FRAME_SIZE.y), FRAME_SIZE)
			frames.add_frame(animation_name, atlas)
	sprite_frames = frames
	state = &"idle"
	play(state)
	if key in ["golem", "champion"]:
		scale = Vector2.ONE * 1.12
	elif key == "wisp":
		scale = Vector2.ONE * 1.05
	else:
		scale = Vector2.ONE

func set_state(next_state: StringName, facing: Vector2, frozen: bool, hit_flash: bool) -> void:
	flip_h = facing.x < -0.05
	if next_state != state:
		state = next_state
		play(state)
	if frozen:
		self_modulate = Color(0.72, 0.9, 1.0, 1.0)
	elif hit_flash:
		self_modulate = Color(1.0, 0.78, 0.72, 1.0)
	else:
		self_modulate = Color.WHITE
