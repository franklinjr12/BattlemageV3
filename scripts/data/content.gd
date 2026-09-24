extends Node

var spells: Dictionary = {}
var gear: Dictionary = {}
var enemies: Dictionary = {}
var encounters: Array[EncounterData] = []
var economy: Dictionary = {}
var packages: Dictionary = {}
var colors: Dictionary = {"Fire": Color("f59a63"), "Ice": Color("83d5f5"), "Earth": Color("d4ba7a"), "Air": Color("9de3c5")}

func _ready() -> void:
	# Explicit paths survive .tres -> .res remapping inside exported game packages.
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content_index.json"))
	for kind: String in ["spells", "gear", "enemies", "encounters"]:
		var files: PackedStringArray = PackedStringArray(index[kind])
		for file: String in files:
			if not file.ends_with(".tres"):
				continue
			var item: Resource = load("res://resources/" + kind + "/" + file)
			if kind == "encounters":
				encounters.append(item as EncounterData)
			else:
				var collection: Dictionary = get(kind)
				if collection.has(item.id):
					push_error("Duplicate content ID: " + item.id)
					continue
				collection[item.id] = item
	economy = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy.json"))
	packages = JSON.parse_string(FileAccess.get_file_as_string("res://data/packages.json"))
	for error: String in validate():
		push_error(error)

func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	for spell: SpellData in spells.values():
		if spell.spell_scene == null or spell.icon == null or spell.cooldown <= 0.0:
			errors.append("Invalid spell resources: " + spell.id)
	for item: GearData in gear.values():
		if item.icon == null or item.price < 0 or item.modifiers.is_empty():
			errors.append("Invalid gear: " + item.id)
	for enemy: EnemyData in enemies.values():
		if enemy.scene == null or enemy.max_health <= 0 or enemy.attacks.is_empty():
			errors.append("Invalid enemy: " + enemy.id)
		for spell_id: String in enemy.attacks:
			if not spells.has(spell_id):
				errors.append("Missing enemy spell: " + spell_id)
	for encounter: EncounterData in encounters:
		if encounter.enemies.is_empty() or encounter.waves < 1:
			errors.append("Empty encounter: " + encounter.id)
		for enemy_id: String in encounter.enemies + encounter.variants:
			if not enemies.has(enemy_id):
				errors.append("Missing encounter enemy: " + enemy_id)
	for package: Dictionary in packages.values():
		var seen: Array = []
		for spell_id: String in package.spells:
			if not spells.has(spell_id) or seen.has(spell_id):
				errors.append("Invalid starting spell: " + spell_id)
			seen.append(spell_id)
		if seen.size() != 4:
			errors.append("Starting package must contain four spells")
	return errors
