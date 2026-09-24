class_name EncounterData extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export_enum("creatures", "mage", "boss") var kind: String = "creatures"
@export var enemies: PackedStringArray = []
@export var variants: PackedStringArray = []
@export var base_difficulty: float = 1.0
@export var reward_multiplier: float = 1.0
@export var progression_required: int = 0
@export var boss: bool = false
@export var formation: String = "ring"

@export var waves: int = 1
@export var intermission_heal: float = 0.1
