class_name SpellData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("Fire", "Ice", "Earth", "Air") var element: String = "Fire"
@export_enum("projectile", "ground", "cone", "self_area", "directional", "self") var targeting: String = "projectile"
@export var reach: float = 300.0
@export var radius: float = 50.0
@export var cone_angle: float = 65.0
@export var damage: float = 20.0
@export var cooldown: float = 3.0
@export var cast_time: float = 0.0
@export var projectile_speed: float = 400.0
@export var delay: float = 0.0
@export var duration: float = 0.0
@export var tick_interval: float = 0.75
@export var status: String = ""
@export var status_duration: float = 3.0
@export var knockback: float = 0.0
@export var price: int = 65
@export var tags: PackedStringArray = []
@export var spell_scene: PackedScene
@export var icon: Texture2D

func tooltip(stats: Dictionary = {}) -> String:
	var power: float = float(stats.get("power", 0.0)) + float(stats.get(element.to_lower() + "_damage", 0.0))
	return "%s · %s\n%s\n\n%.0f damage · %.1fs cooldown · %.1fs cast\n%.0f range · %s%s" % [display_name, element, description, damage * (1.0 + power), cooldown * maxf(0.35, 1.0 - float(stats.get("cooldown", 0.0))), cast_time * maxf(0.25, 1.0 - float(stats.get("cast_speed", 0.0))), reach, targeting.replace("_", " "), "\n" + status.capitalize() + " · %.1fs" % status_duration if not status.is_empty() else ""]
