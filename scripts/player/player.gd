class_name PlayerFighter extends Fighter
signal selection_changed
var selected: SpellData
var hint: String = "Right-click a destination to move."
var tutorial_step: int = 0
var tutorial_done: bool = false

func setup(owner_arena: Node2D) -> void:
	arena = owner_arena
	team = 0
	visual = "player"
	refresh_visual()
	modifiers = GameState.stats()
	move_speed = float(Content.economy.player_speed) * (1.0 + float(modifiers.get("speed", 0.0)))
	health.reset(float(modifiers.max_hp))
	loadout = PackedStringArray(GameState.run.loadout)
	tint = [Color("83d5f5"), Color("f59a63"), Color("d4ba7a"), Color("9de3c5")][int(GameState.run.appearance)]
	display_name = GameState.run.name
	tutorial_done = bool(GameState.run.tutorial)
	dodge_timers.resize(int(Content.economy.dodge_charges))
	dodge_timers.fill(0.0)

func _unhandled_input(event: InputEvent) -> void:
	if arena == null or not arena.active or health.dead or get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = [KEY_Q, KEY_W, KEY_E, KEY_R].find(event.physical_keycode)
		if index >= 0:
			select_slot(index)
		if event.physical_keycode == KEY_SPACE:
			if dodge(get_global_mouse_position()):
				advance_tutorial(3)
		if event.physical_keycode == KEY_ESCAPE and selected != null:
			selected = null
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			selected = null
			destination = arena.clamp_position(get_global_mouse_position(), body_radius)
			advance_tutorial(0)
		if event.button_index == MOUSE_BUTTON_LEFT and selected != null:
			if request_cast(selected, get_global_mouse_position()):
				selected = null
				advance_tutorial(2)
			else:
				hint = "Target outside range, or action unavailable. No cooldown spent."
	queue_redraw()

func select_slot(index: int) -> void:
	var spell: SpellData = Content.spells[loadout[index]]
	if can_cast(spell):
		selected = spell
		advance_tutorial(1)
		selection_changed.emit()
	else:
		hint = "That spell is not ready yet."

func advance_tutorial(step: int) -> void:
	if tutorial_done:
		return
	if step == tutorial_step:
		tutorial_step += 1
		var prompts: Array[String] = ["Right-click a destination to move.", "Press Q, W, E, or R to select a spell.", "Aim the preview, then left-click to cast.", "Press Space to dodge toward your cursor. Two charges recharge independently.", "Casts root you; dodge cancels them. Freeze + Earth shatters. Burn + Combustion detonates."]
		hint = prompts[mini(tutorial_step, prompts.size() - 1)]

func dismiss_tutorial() -> void:
	tutorial_done = true
	GameState.run.tutorial = true
	GameState.persist()

func _on_death() -> void:
	selected = null
	super._on_death()
