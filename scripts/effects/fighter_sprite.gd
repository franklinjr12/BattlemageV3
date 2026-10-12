class_name FighterSprite extends AnimatedSprite2D
## Import asset-specific enemy clips, preserving the existing 4x5 player sheet.
const LEGACY := {
 "idle":{"row":0,"frames":4,"fps":4.5,"loop":true},
 "move":{"row":1,"frames":4,"fps":9.0,"loop":true},
 "cast":{"row":2,"frames":4,"fps":9.0,"loop":true},
 "hurt":{"row":3,"frames":4,"fps":13.0,"loop":false},
 "death":{"row":4,"frames":4,"fps":7.0,"loop":false},
}
var visual_key: String = ""
var state: StringName = &"idle"

func _init() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
 var metadata_path := "res://art/source/enemy_revamp/%s.json" % key
 var metadata: Dictionary = {}
 if FileAccess.file_exists(metadata_path):
  var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
  if parsed is Dictionary:
   metadata = parsed
 var cell := Vector2(64, 64)
 var columns := 4
 var clips: Dictionary = LEGACY
 if not metadata.is_empty():
  var dimensions: Array = metadata.get("cell", [64,64])
  cell = Vector2(float(dimensions[0]),float(dimensions[1]))
  columns = int(metadata.get("columns",7))
  clips = metadata.get("clips",LEGACY)
  var pivot: Array = metadata.get("pivot", [int(cell.x/2),int(cell.y*.82)])
  offset = cell/2.0 - Vector2(float(pivot[0]),float(pivot[1]))
  position = Vector2.ZERO
 else:
  offset = Vector2.ZERO
  position = Vector2(0,-14)
 var frames := SpriteFrames.new()
 for animation_name: String in (["idle","move","cast","hurt","death","barrier","phase"] if key=="champion" else ["idle","move","cast","hurt","death"]):
  if not clips.has(animation_name):
   push_error("Missing actor clip: " + key + "/" + animation_name)
   continue
  var spec: Dictionary = clips[animation_name]
  frames.add_animation(animation_name)
  frames.set_animation_speed(animation_name, float(spec.get("fps",8.0)))
  frames.set_animation_loop(animation_name, bool(spec.get("loop",false)))
  var row := int(spec.get("row",0))
  var count := mini(columns,int(spec.get("frames",4)))
  for index in count:
   var atlas := AtlasTexture.new()
   atlas.atlas = texture
   atlas.region = Rect2(Vector2(index*cell.x,row*cell.y),cell)
   frames.add_frame(animation_name,atlas)
 sprite_frames = frames
 state = &"idle"
 play(state)
 # With correctly scaled large sprites, the art—not collision radii—defines visual size.
 scale = Vector2.ONE
 visible = true

func set_state(next_state: StringName, facing: Vector2, frozen: bool, hit_flash: bool) -> void:
 flip_h = facing.x < -0.05
 if next_state != state:
  state = next_state
  if sprite_frames.has_animation(state):
   play(state)
 if frozen:
  self_modulate = Color(0.72, 0.9, 1.0, 1.0)
 elif hit_flash:
  self_modulate = Color(1.0, 0.78, 0.72, 1.0)
 else:
  self_modulate = Color.WHITE
