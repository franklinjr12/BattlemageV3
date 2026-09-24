extends Node
var arena: ArenaDirector
var elapsed: float = 0.0
var next_cast: float = 0.0
var frame_times: Array[float] = []
var peak_effects: int = 0
var peak_nodes: int = 0
var start_memory: float = 0.0
var cycles: int = 0

func _ready() -> void:
	GameState.disk_enabled = false
	new_arena()
	start_memory = float(Performance.get_monitor(Performance.MEMORY_STATIC))

func new_arena() -> void:
	GameState.new_run("Stress test", 0, "Stormcaller", 123)
	GameState.run.stage = 2
	arena = ArenaDirector.new()
	add_child(arena)
	arena.begin(2, 2)
	arena.intro = 0
	arena.active = true
	arena.player.debug_invulnerable = true
	for enemy: EnemyFighter in arena.enemies:
		enemy.health.reset(100000)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 1: frame_times.append(delta * 1000)
	peak_effects = maxi(peak_effects, arena.effects.get_child_count())
	peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	arena.player.destination = ArenaDirector.CENTER + Vector2.from_angle(elapsed * 0.6) * 180
	if elapsed >= next_cast:
		next_cast = elapsed + 0.18
		var spell_ids: Array[String] = ["fireball", "burning_ground", "vortex", "icicle_rain", "wind_blade"]
		var id: String = spell_ids[int(elapsed * 10) % spell_ids.size()]
		arena.player.execute_spell(Content.spells[id], ArenaDirector.CENTER + Vector2.from_angle(elapsed) * 100)
	if elapsed > (cycles + 1) * 4.0 and cycles < 2:
		arena.free()
		cycles += 1
		new_arena()
	if elapsed >= 12:
		set_process(false)
		arena.active = false
		arena.free()
		await get_tree().process_frame
		frame_times.sort()
		var sum: float = 0
		for ms: float in frame_times: sum += ms
		var report: Dictionary = {"adapter": RenderingServer.get_video_adapter_name(), "frames": frame_times.size(), "mean_frame_ms": sum / maxf(1, frame_times.size()), "p95_frame_ms": frame_times[int(frame_times.size() * .95)], "peak_effects": peak_effects, "peak_nodes": peak_nodes, "arena_cycles": cycles + 1, "static_memory_start": start_memory, "static_memory_end": Performance.get_monitor(Performance.MEMORY_STATIC), "nodes_after_cleanup": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
		print("PERFORMANCE " + JSON.stringify(report))
		FileAccess.open("res://docs/performance.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
		Sound.shutdown()
