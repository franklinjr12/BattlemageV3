class_name ArenaDirector extends Node2D
signal finished(result: Dictionary)
const CENTER: Vector2 = Vector2(640, 399)
const RADIUS: float = 293.0
var player: PlayerFighter
var enemies: Array[EnemyFighter] = []
var effects: Node2D
var actors: Node2D
var wave_number: int = 1
var stage: int = 0
var difficulty: int = 1
var ids: PackedStringArray
var active: bool = false
var intro: float = 2.2
var ended: bool = false
var outcome_timer: float = -1.0
var result: Dictionary = {}
var shake: float = 0.0
var elapsed: float = 0.0
var floating: Array[Dictionary] = []
var bursts: Array[Dictionary] = []
var frame_times: Array[float] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	effects = Node2D.new()
	effects.name = "SpellEffects"
	add_child(effects)
	actors = Node2D.new()
	actors.name = "Combatants"
	actors.y_sort_enabled = true
	add_child(actors)

func begin(encounter_stage: int, selected_difficulty: int) -> void:
	stage = encounter_stage
	difficulty = selected_difficulty
	ids = GameState.enemy_ids(stage, difficulty)
	GameState.in_combat = true
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	player = scene.instantiate() as PlayerFighter
	player.setup(self)
	player.position = CENTER + Vector2(-150, 0) if Content.encounters[stage].kind != "creatures" else CENTER
	actors.add_child(player)
	player.died.connect(_fighter_died)
	spawn_wave()
	if Content.encounters[stage].boss:
		Sound.cue("boss")

func spawn_wave() -> void:
	for index: int in ids.size():
		var point: Vector2 = CENTER + Vector2.from_angle(TAU * index / ids.size() - PI * 0.5 + (wave_number - 1) * .65) * 220.0
		if Content.encounters[stage].kind != "creatures":
			point = CENTER + Vector2(165, 0)
		spawn_enemy(ids[index], point)

func spawn_enemy(id: String, point: Vector2) -> EnemyFighter:
	var data: EnemyData = Content.enemies[id]
	var enemy: EnemyFighter = data.scene.instantiate() as EnemyFighter
	enemy.setup(self, data, Content.economy.difficulty[difficulty], Content.encounters[stage].base_difficulty, int(GameState.run.seed) + enemies.size() * 37 + stage * 103)
	enemy.position = clamp_position(point, enemy.body_radius)
	actors.add_child(enemy)
	enemies.append(enemy)
	enemy.died.connect(_fighter_died)
	return enemy

func fighters() -> Array[Fighter]:
	var all: Array[Fighter] = []
	if is_instance_valid(player):
		all.append(player)
	for enemy: EnemyFighter in enemies:
		if is_instance_valid(enemy):
			all.append(enemy)
	return all

func inside(point: Vector2, margin: float = 0.0) -> bool:
	return point.distance_to(CENTER) <= RADIUS - margin

func clamp_position(point: Vector2, margin: float = 12.0) -> Vector2:
	return CENTER + (point - CENTER).limit_length(RADIUS - margin)

func _fighter_died(_fighter: Fighter) -> void:
	# Resolve at frame boundary so simultaneous damage consistently favors defeat.
	call_deferred("check_end")

func check_end() -> void:
	if ended or not active:
		return
	if player.health.dead:
		end_battle(false)
	elif enemies.all(func(enemy: EnemyFighter) -> bool: return enemy.health.dead):
		if wave_number < Content.encounters[stage].waves:
			wave_number += 1
			active = false
			intro = 2.8
			player.cancel_cast()
			player.selected = null
			player.statuses.clear()
			player.health.heal(player.health.maximum * Content.encounters[stage].intermission_heal)
			for effect: Node in effects.get_children(): effect.queue_free()
			for enemy: EnemyFighter in enemies: enemy.queue_free()
			enemies.clear()
			spawn_wave()
		else:
			end_battle(true)

func end_battle(victory: bool) -> void:
	if ended:
		return
	ended = true
	active = false
	for fighter: Fighter in fighters():
		fighter.cancel_cast()
	player.selected = null
	for effect: Node in effects.get_children():
		effect.queue_free()
	result = GameState.finish_encounter(victory, stage, difficulty, ids)
	outcome_timer = 1.4
	Sound.cue("victory" if victory else "defeat")

func _process(delta: float) -> void:
	elapsed += delta
	if intro > 0.0:
		intro -= delta
		if intro <= 0.0 and not ended:
			active = true
	if outcome_timer >= 0.0:
		outcome_timer -= delta
		if outcome_timer < 0.0:
			finished.emit(result)
	shake = maxf(0.0, shake - delta * 20.0)
	position = Vector2(sin(elapsed * 119), cos(elapsed * 97)) * shake * float(GameState.settings.shake)
	for i: int in range(floating.size() - 1, -1, -1):
		floating[i].life -= delta
		floating[i].point.y -= delta * 23.0
		if float(floating[i].life) <= 0:
			floating.remove_at(i)
	for i: int in range(bursts.size() - 1, -1, -1):
		bursts[i].life -= delta
		if float(bursts[i].life) <= 0:
			bursts.remove_at(i)
	queue_redraw()

func float_text(point: Vector2, text: String, color: Color) -> void:
	if GameState.settings.numbers:
		floating.append({"point": point, "text": text, "color": color, "life": 0.85})
		if floating.size() > 90:
			floating.pop_front()

func burst(point: Vector2, color: Color, radius: float) -> void:
	bursts.append({"point": point, "color": color, "radius": radius, "life": 0.3})
	var impact := ImpactBurst.new()
	effects.add_child(impact)
	impact.configure(point, color, radius)

func _draw() -> void:
	ArenaArt.draw_arena(self, CENTER, RADIUS, elapsed)
	if is_instance_valid(player):
		if player.position.distance_to(player.destination) > 5.0 and active:
			draw_arc(player.destination, 7, 0, TAU, 12, Color("89b3ae"), 1.0)
			draw_circle(player.destination, 2, Color("b5ddd0"))
		if player.selected != null and active:
			var spell: SpellData = player.selected
			var aim: Vector2 = get_global_mouse_position()
			var color: Color = Content.colors[spell.element] if player.valid_target(spell, aim) else Color("ee756d")
			if spell.reach > 0:
				draw_arc(player.position, spell.reach, 0, TAU, 96, Color(color, 0.22), 1.0)
			SpellGeometry.draw_shape(self, spell, player.position, aim, color, 1.0 + float(player.modifiers.get("area", 0.0)))
		for fighter: Fighter in fighters():
			if fighter.casting != null:
				var color: Color = Color("f79682") if fighter.team == 1 else Color("b8e3dc")
				SpellGeometry.draw_shape(self, fighter.casting, fighter.position, fighter.cast_target, color, 1.0 + float(fighter.modifiers.get("area", 0.0)))
				if fighter.team == 1:
					draw_string(ThemeDB.fallback_font, fighter.position + Vector2(-4, -58), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
	for entry: Dictionary in bursts:
		draw_arc(entry.point, float(entry.radius) * (1.0 - float(entry.life) / 0.3), 0, TAU, 32, Color(entry.color, float(entry.life) / 0.3), 3.0)
	for entry: Dictionary in floating:
		draw_string(ThemeDB.fallback_font, entry.point, entry.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(entry.color, minf(1.0, float(entry.life) * 2)))
