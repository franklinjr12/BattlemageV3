extends Node
signal changed
signal saved(ok: bool)
const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://run.json"
var run: Dictionary = {}
var settings: Dictionary = {"master": 0.8, "music": 0.35, "sfx": 0.8, "shake": 0.5, "numbers": true, "fullscreen": false, "ui_scale": 1.0}
var save_error: String = ""
var in_combat: bool = false
var last_result: Dictionary = {}
var disk_enabled: bool = true

func _ready() -> void:
	disk_enabled = not OS.get_cmdline_user_args().has("--test") and not OS.get_cmdline_user_args().has("--capture")
	if disk_enabled:
		load_settings()

func new_run(character_name: String, appearance: int, package: String, seed_value: int = 0) -> void:
	if not Content.packages.has(package):
		return
	var actual_seed: int = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system()) ^ randi()
	run = {"version": SAVE_VERSION, "name": character_name.strip_edges().left(24) if not character_name.strip_edges().is_empty() else "Ash", "appearance": clampi(appearance, 0, 3), "seed": actual_seed, "level": 1, "xp": 0, "gold": int(Content.economy.starting_gold), "owned_spells": Content.packages[package].spells.duplicate(), "loadout": Content.packages[package].spells.duplicate(), "owned_gear": [], "equipment": {}, "bonuses": {}, "choices": 0, "stage": 0, "complete": false, "spell_offers": [], "gear_offers": [], "tutorial": false, "wins": []}
	in_combat = false
	last_result = {}
	refresh_shops()
	persist()

func stats() -> Dictionary:
	var result: Dictionary = {"max_hp": float(Content.economy.player_hp) + 8.0 * float(run.get("level", 1) - 1), "speed": 0.0, "power": 0.025 * float(run.get("level", 1) - 1), "cooldown": 0.0, "dodge_recharge": 0.0, "cast_speed": 0.0, "area": 0.0, "armor": 0.0}
	for key: String in run.get("bonuses", {}):
		result[key] = float(result.get(key, 0.0)) + float(run.bonuses[key])
	for id: String in run.get("equipment", {}).values():
		var item: GearData = Content.gear[id]
		for key: String in item.modifiers:
			result[key] = float(result.get(key, 0.0)) + float(item.modifiers[key])
	return result

func scaled_cooldown(spell: SpellData, modifiers: Dictionary) -> float:
	return spell.cooldown * maxf(0.35, 1.0 - float(modifiers.get("cooldown", 0.0)))

func refresh_shops() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(run.seed) + int(run.stage) * 7919
	for kind: String in ["spell", "gear"]:
		var pool: Array = []
		var collection: Dictionary = Content.spells if kind == "spell" else Content.gear
		var owned: Array = run.owned_spells if kind == "spell" else run.owned_gear
		for id: String in collection:
			if not owned.has(id) and not collection[id].tags.has("enemy_only"):
				pool.append(id)
		pool.sort()
		var offers: Array = []
		for index: int in mini(int(Content.economy[kind + "_offers"]), pool.size()):
			var selected: int = rng.randi_range(0, pool.size() - 1)
			offers.append(pool[selected])
			pool.remove_at(selected)
		run[kind + "_offers"] = offers

func purchase(kind: String, id: String) -> bool:
	if in_combat or run.is_empty() or not ["spell", "gear"].has(kind):
		return false
	var collection: Dictionary = Content.spells if kind == "spell" else Content.gear
	var owned: Array = run.owned_spells if kind == "spell" else run.owned_gear
	if not collection.has(id) or not run[kind + "_offers"].has(id) or owned.has(id):
		return false
	var price: int = collection[id].price
	if int(run.gold) < price:
		return false
	run.gold -= price
	owned.append(id)
	persist()
	return true

func equip_spell(slot: int, id: String) -> bool:
	if in_combat or slot < 0 or slot > 3 or not run.owned_spells.has(id):
		return false
	var other: int = run.loadout.find(id)
	if other >= 0:
		run.loadout[other] = run.loadout[slot]
	run.loadout[slot] = id
	persist()
	return true

func equip_gear(id: String) -> bool:
	if in_combat or not run.owned_gear.has(id):
		return false
	run.equipment[Content.gear[id].slot] = id
	persist()
	return true

func unequip_gear(slot: String) -> void:
	if not in_combat:
		run.equipment.erase(slot)
		persist()

func enemy_ids(stage: int, difficulty: int) -> PackedStringArray:
	var encounter: EncounterData = Content.encounters[clampi(stage, 0, 4)]
	var ids: PackedStringArray = encounter.enemies.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(run.seed) + stage * 3571
	if encounter.kind == "mage" and not encounter.variants.is_empty() and rng.randf() > 0.5:
		ids[0] = encounter.variants[rng.randi_range(0, encounter.variants.size() - 1)]
	if encounter.kind == "creatures" and not encounter.variants.is_empty():
		if stage > 0 or difficulty == 2:
			ids.append(encounter.variants[rng.randi_range(0, encounter.variants.size() - 1)])
	return ids

func reward_for(stage: int, difficulty: int, ids: PackedStringArray) -> Dictionary:
	var gold: int = int(Content.economy.encounter_gold[stage])
	var xp: int = int(Content.economy.encounter_xp[stage])
	for id: String in ids:
		gold += Content.enemies[id].gold * Content.encounters[stage].waves
		xp += Content.enemies[id].xp * Content.encounters[stage].waves
	var multiplier: float = float(Content.economy.difficulty[difficulty].reward) * Content.encounters[stage].reward_multiplier
	return {"gold": roundi(gold * multiplier), "xp": roundi(xp * multiplier)}

func finish_encounter(victory: bool, stage: int, difficulty: int, ids: PackedStringArray) -> Dictionary:
	if not in_combat or stage != int(run.stage):
		return {}
	in_combat = false
	last_result = {"victory": victory, "gold": 0, "xp": 0, "levels": 0, "stage": stage}
	if victory:
		var rewards: Dictionary = reward_for(stage, difficulty, ids)
		run.gold += rewards.gold
		run.xp += rewards.xp
		last_result.gold = rewards.gold
		last_result.xp = rewards.xp
		while int(run.level) < 5 and int(run.xp) >= int(Content.economy.xp_thresholds[int(run.level)]):
			run.level += 1
			run.choices += 1
			last_result.levels += 1
		run.wins.append({"stage": stage, "difficulty": difficulty})
		run.stage += 1
		run.complete = int(run.stage) >= Content.encounters.size()
		refresh_shops()
	persist()
	return last_result

func choose_bonus(key: String) -> bool:
	var values: Dictionary = {"max_hp": 25.0, "power": 0.1, "cooldown": 0.06, "dodge_recharge": 0.12, "status_duration": 0.2}
	if in_combat or int(run.get("choices", 0)) <= 0 or not values.has(key):
		return false
	run.bonuses[key] = float(run.bonuses.get(key, 0.0)) + float(values[key])
	run.choices -= 1
	persist()
	return true

func persist() -> void:
	changed.emit()
	if not disk_enabled or run.is_empty():
		return
	var ok: bool = atomic_write(SAVE_PATH, JSON.stringify(run, "\t"))
	save_error = "" if ok else "Could not save progress. Check the user data folder permissions."
	saved.emit(ok)

func atomic_write(path: String, text: String) -> bool:
	var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		return false
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func valid_run(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var data: Dictionary = value
	for key: String in ["version", "name", "appearance", "seed", "level", "xp", "gold", "owned_spells", "loadout", "owned_gear", "equipment", "bonuses", "choices", "stage", "complete", "spell_offers", "gear_offers", "tutorial", "wins"]:
		if not data.has(key):
			return false
	for key: String in ["version", "appearance", "seed", "level", "xp", "gold", "choices", "stage"]:
		if not (data[key] is int or data[key] is float) or not is_finite(float(data[key])):
			return false
	if int(data.version) != SAVE_VERSION or not data.name is String or not data.complete is bool or not data.tutorial is bool:
		return false
	if int(data.appearance) < 0 or int(data.appearance) > 3:
		return false
	if int(data.level) < 1 or int(data.level) > 5 or int(data.stage) < 0 or int(data.stage) > 5 or int(data.gold) < 0 or int(data.xp) < 0 or int(data.choices) < 0 or int(data.choices) > 4:
		return false
	if bool(data.complete) != (int(data.stage) == 5):
		return false
	for key: String in ["owned_spells", "loadout", "owned_gear", "spell_offers", "gear_offers", "wins"]:
		if not data[key] is Array:
			return false
	if not data.equipment is Dictionary or not data.bonuses is Dictionary or data.loadout.size() != 4:
		return false
	var seen: Array = []
	for id: Variant in data.owned_spells + data.loadout + data.spell_offers:
		if not id is String or not Content.spells.has(id) or Content.spells[id].tags.has("enemy_only"):
			return false
	for id: String in data.loadout:
		if not data.owned_spells.has(id) or seen.has(id):
			return false
		seen.append(id)
	for id: Variant in data.owned_gear + data.gear_offers:
		if not id is String or not Content.gear.has(id):
			return false
	for slot: Variant in data.equipment:
		var id: Variant = data.equipment[slot]
		if not id is String or not Content.gear.has(id) or not data.owned_gear.has(id) or Content.gear[id].slot != slot:
			return false
	for key: Variant in data.bonuses:
		if not ["max_hp", "power", "cooldown", "dodge_recharge", "status_duration"].has(key) or not (data.bonuses[key] is float or data.bonuses[key] is int) or not is_finite(float(data.bonuses[key])) or float(data.bonuses[key]) < 0:
			return false
	return true

func load_run(save_path: String = SAVE_PATH) -> bool:
	for path: String in [save_path, save_path + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if valid_run(value):
			run = value
			in_combat = false
			save_error = "Recovered the previous save backup." if path.ends_with(".bak") else ""
			changed.emit()
			return true
	save_error = "No compatible save found. You can start a new character."
	return false

func save_settings() -> void:
	if disk_enabled:
		atomic_write("user://settings.json", JSON.stringify(settings))
	apply_settings()

func load_settings() -> void:
	if FileAccess.file_exists("user://settings.json"):
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://settings.json"))
		if value is Dictionary:
			for key: String in settings:
				if not value.has(key):
					continue
				if settings[key] is bool and value[key] is bool:
					settings[key] = value[key]
				elif (settings[key] is float) and (value[key] is float or value[key] is int) and is_finite(float(value[key])):
					settings[key] = clampf(float(value[key]), 0.0, 1.0) if key != "ui_scale" else clampf(float(value[key]), 0.85, 1.15)
	apply_settings()

func apply_settings() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	for pair: Array in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var index: int = AudioServer.get_bus_index(pair[0])
		if index >= 0:
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, float(settings[pair[1]]))))
