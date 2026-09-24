extends Node
var pool: Array[AudioStreamPlayer] = []
var tracks: Dictionary = {}
var music: AudioStreamPlayer
var next_voice: int = 0
var silent: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	silent = DisplayServer.get_name() == "headless"
	for bus: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	for cue: String in ["fire", "ice", "earth", "air", "hit", "dodge", "ui", "death", "victory", "defeat", "boss"]:
		tracks[cue] = load("res://audio/" + cue + ".wav")
	for index: int in 12:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		pool.append(voice)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.stream = load("res://audio/ambience.wav")
	add_child(music)
	music.finished.connect(music.play)
	if not silent:
		music.play()
	GameState.apply_settings()

func cue(id: String, volume: float = 0.0) -> void:
	if silent or not tracks.has(id) or pool.is_empty():
		return
	var voice: AudioStreamPlayer = pool[next_voice]
	next_voice = (next_voice + 1) % pool.size()
	voice.stream = tracks[id]
	voice.volume_db = volume
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()

func stop_all() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for voice: AudioStreamPlayer in pool:
		voice.stop()
		voice.stream = null
	tracks.clear()

func shutdown(exit_code: int = 0) -> void:
	stop_all()
	await get_tree().create_timer(0.12, true).timeout
	get_tree().quit(exit_code)

func _exit_tree() -> void:
	stop_all()
