class_name GearData extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("Staff", "Robe", "Boots", "Ring") var slot: String = "Staff"
@export var price: int = 65
@export var modifiers: Dictionary = {}
@export var tags: PackedStringArray = []
@export var icon: Texture2D
