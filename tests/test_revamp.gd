extends Node
## Presentation regression checks run with Godot --headless --script res://tests/test_revamp.gd.
var checks := 0
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures.append(message)
  push_error("REVAMP: " + message)

func _ready() -> void:
 call_deferred("_run")

func _run() -> void:
 GameState.disk_enabled = false
 var main: Node = load("res://scenes/main.tscn").instantiate()
 get_tree().root.add_child(main)
 await get_tree().process_frame
 GameState.new_run("Test Mage",0,"Emberweaver",54321)
 var roster: Array[String] = ["hound","skitter","spitter","wisp","golem","pyromancer","cryomancer","battlemage","champion"]
 for enemy_id in roster:
  var visual: FighterSprite=FighterSprite.new()
  get_tree().root.add_child(visual)
  visual.setup(enemy_id)
  require(visual.visible,enemy_id+" visible")
  require(visual.sprite_frames!=null,enemy_id+" SpriteFrames")
  for state: String in ["idle","move","cast","hurt","death"]:
   require(visual.sprite_frames.has_animation(state),enemy_id+"/"+state+" clip")
  require(visual.sprite_frames.get_frame_count("idle")==6,enemy_id+" idle count")
  require(not visual.sprite_frames.get_animation_loop("hurt"),enemy_id+" hurt one shot")
  require(not visual.sprite_frames.get_animation_loop("death"),enemy_id+" death one shot")
  require(visual.sprite_frames.get_frame_count("death")==7,enemy_id+" death count")
  if enemy_id=="champion":
   require(visual.sprite_frames.has_animation("phase"),"champion phase clip")
   require(visual.sprite_frames.has_animation("barrier"),"champion barrier clip")
  visual.queue_free()
 for gear_id: String in Content.gear.keys():
  require(Content.gear[gear_id].icon != null, "gear icon "+gear_id)
 main.show_title()
 require(main.current_page=="title","title")
 main.show_creation()
 require(main.current_page=="creation","character creation")
 main.show_hub()
 require(main.current_page=="hub","hub")
 main.show_shop("spell")
 require(main.current_page=="shop","spell shop")
 main.show_shop("gear")
 require(main.current_page=="shop","gear shop")
 main.show_build()
 require(main.current_page=="build","loadout")
 main.show_encounters()
 require(main.current_page=="encounters","encounters")
 main.show_level_choices()
 require(main.current_page=="hub","empty level bonus returns to hub")
 main.show_settings(false)
 require(main.overlay!=null,"settings modal")
 main.close_overlay()
 require(main.overlay==null,"modal close")
 main.queue_free()
 await get_tree().process_frame
 print("REVAMP RESULT: %d checks / %d failures" % [checks,failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)
