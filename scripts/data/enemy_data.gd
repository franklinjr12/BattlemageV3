class_name EnemyData extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export var max_health: float = 100.0
@export var speed: float = 80.0
@export var power: float = 0.0
@export var gold: int = 15
@export var xp: int = 15
@export_enum("melee", "ranged", "fast", "tank", "support", "mage") var profile: String = "melee"
@export var attacks: PackedStringArray = []
@export var preferred_range: float = 60.0
@export var aggression: float = 1.0
@export var dodge_interval: float = 8.0
@export var stagger_resistance: int = 3
@export var visual: String = "hound"
@export var color: Color = Color("cc9570")
@export var scene: PackedScene
@export var scaling: float = 1.0
