extends Node
var screen: Control
var background: Node2D
var arena: ArenaDirector
var overlay: Control
var current_page: String = "title"
var hud: Dictionary = {}
var slot_buttons: Array[Button] = []
var selected_build_slot: int = 0
var creation_name: String = "Ash"
var creation_appearance: int = 0
var creation_package: String = "Emberweaver"
var capture_mode: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	background = Node2D.new()
	background.set_script(load("res://scripts/ui/backdrop.gd"))
	add_child(background)
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.theme = UI.theme()
	layer.add_child(screen)
	show_title()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if OS.is_debug_build() and args.has("--capture"):
		capture_mode = true
		GameState.disk_enabled = false
		var index: int = args.find("--capture")
		var page: String = args[index + 1] if args.size() > index + 1 else "title"
		if page != "title":
			GameState.new_run("Ash", 0, "Emberweaver", 12345)
			if page in ["combat", "champion"]:
				if page == "champion": GameState.run.stage = 4
				start_combat(1)
			elif page == "shop":
				show_shop("spell")
			elif page in ["build", "populated"]:
				if page == "populated":
					GameState.run.owned_gear = ["granite_robe", "prism_staff", "tempo_ring", "wind_boots"]
					for id: String in GameState.run.owned_gear: GameState.equip_gear(id)
				show_build()
			elif page == "creation":
				show_creation()
			elif page == "settings":
				show_settings(false)
			elif page == "completion":
				GameState.run.complete = true
				GameState.run.stage = 5
				show_completion()
			else:
				show_hub()
		capture.call_deferred(page)

func capture(page: String) -> void:
	Input.warp_mouse(Vector2(630, 650))
	for frame: int in 150:
		await get_tree().process_frame
	if is_instance_valid(arena):
		arena.player.selected = Content.spells["fireball"]
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	image.save_png("res://docs/screenshots/" + page + ".png")
	Sound.shutdown()

func clear_screen(page: String, keep_arena: bool = false) -> void:
	get_tree().paused = false
	current_page = page
	for child: Node in screen.get_children():
		screen.remove_child(child)
		child.queue_free()
	overlay = null
	hud.clear()
	slot_buttons.clear()
	if is_instance_valid(arena) and not keep_arena:
		remove_child(arena)
		arena.queue_free()
		arena = null
	background.visible = page != "combat"

func header(title: String, subtitle: String, back: Callable = Callable()) -> void:
	var card: PanelContainer = UI.panel(screen, Rect2(35, 25, 1210, 96), Color("0d1826"))
	var line: HBoxContainer = UI.row(card, 20)
	var titles: VBoxContainer = UI.column(line, 3)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.label(titles, title, 27, UI.GOLD)
	UI.label(titles, subtitle, 15, UI.MUTED)
	if not GameState.run.is_empty():
		UI.label(line, "Lv. %d    /    %d gold" % [int(GameState.run.level), int(GameState.run.gold)], 18, UI.GOLD)
	if back.is_valid():
		UI.button(line, "Back", back)

func show_title() -> void:
	clear_screen("title")
	GameState.in_combat = false
	var left: VBoxContainer = UI.column(UI.panel(screen, Rect2(80, 58, 555, 96), Color(0.04, 0.07, 0.11, 0.9)), 4)
	UI.label(left, "THE LOCAL ARENA", 17, UI.GOLD)
	UI.label(left, "Four schools. Four spells. One crown.", 23)
	var box: VBoxContainer = UI.column(UI.panel(screen, Rect2(735, 155, 465, 480), Color("101c2a")), 16)
	UI.label(box, "B A T T L E M A G E", 33, UI.GOLD)
	UI.label(box, "A R E N A", 46, UI.WHITE)
	UI.label(box, "LOCAL ASCENSION", 16, UI.MUTED)
	UI.spacer(box, 6)
	UI.label(box, "Shape your magic. Read your rival.\nEarn your place among the champions.", 18, UI.WHITE, true)
	UI.spacer(box, 12)
	UI.button(box, "Create a battlemage", confirm_new, true)
	var resume: Button = UI.button(box, "Continue journey", func() -> void:
		if GameState.load_run():
			if GameState.run.complete: show_completion()
			else: show_hub()
		else: show_notice(GameState.save_error))
	resume.disabled = not FileAccess.file_exists(GameState.SAVE_PATH) and not FileAccess.file_exists(GameState.SAVE_PATH + ".bak")
	var row: HBoxContainer = UI.row(box)
	UI.button(row, "Settings", func() -> void: show_settings(false)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.button(row, "Quit", func() -> void: Sound.shutdown()).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var foot: Label = UI.label(screen, "PLAYABLE DEMO   /   v0.1.0                                       Mouse + keyboard   ·   No mana. Every cast counts.", 14, UI.MUTED)
	foot.position = Vector2(80, 740)

func confirm_new() -> void:
	if not GameState.run.is_empty() or FileAccess.file_exists(GameState.SAVE_PATH):
		show_modal("Begin a new journey?", "Creating a new character replaces the saved run. Your settings are kept.", "Create character", show_creation)
	else:
		show_creation()

func show_creation() -> void:
	clear_screen("creation")
	header("Create your battlemage", "Your first four spells are a starting point. Every school stays open to you.", show_title)
	var identity: VBoxContainer = UI.column(UI.panel(screen, Rect2(55, 150, 340, 575)), 15)
	UI.label(identity, "01  /  IDENTITY", 17, UI.GOLD)
	UI.label(identity, "Battlemage name", 17)
	var name_field: LineEdit = LineEdit.new()
	name_field.text = creation_name
	name_field.max_length = 24
	name_field.custom_minimum_size.y = 48
	name_field.text_changed.connect(func(value: String) -> void: creation_name = value)
	identity.add_child(name_field)
	UI.spacer(identity, 10)
	UI.label(identity, "Mantle color", 17)
	for index: int in 4:
		var button: Button = UI.button(identity, ["Moonstone blue", "Ember orange", "Sunworn gold", "Verdant green"][index] + ("  ✓" if index == creation_appearance else ""), func() -> void: creation_appearance = index; show_creation())
		button.modulate = [Color("83d5f5"), Color("f59a63"), Color("d4ba7a"), Color("9de3c5")][index]
	UI.label(identity, "A name and a mantle.\nThe rest is earned in the arena.", 16, UI.MUTED, true)
	var packages: VBoxContainer = UI.column(UI.panel(screen, Rect2(420, 150, 805, 575)), 14)
	UI.label(packages, "02  /  STARTING MAGIC", 17, UI.GOLD)
	for package_name: String in Content.packages:
		var data: Dictionary = Content.packages[package_name]
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.box(Color("18293a"), UI.GOLD if creation_package == package_name else Color("2c4054")))
		packages.add_child(card)
		var column: VBoxContainer = UI.column(card, 5)
		UI.button(column, package_name + ("   /   SELECTED" if creation_package == package_name else ""), func() -> void: creation_package = package_name; show_creation())
		UI.label(column, data.description, 15, UI.MUTED, true)
		var names: PackedStringArray = []
		for id: String in data.spells: names.append(Content.spells[id].display_name)
		UI.label(column, "  /  ".join(names), 15, UI.WHITE, true)
	UI.button(packages, "Enter the Local Arena", func() -> void: GameState.new_run(creation_name, creation_appearance, creation_package); show_hub(), true)

func show_hub() -> void:
	if GameState.run.complete:
		show_completion()
		return
	clear_screen("hub")
	header("The antechamber", "%s  ·  Local Arena  ·  %d of 5 trials conquered" % [GameState.run.name, int(GameState.run.stage)], show_title)
	var route: VBoxContainer = UI.column(UI.panel(screen, Rect2(55, 153, 570, 495), Color(0.04, 0.08, 0.12, 0.95)), 15)
	UI.label(route, "THE ROAD TO THE CROWN", 17, UI.GOLD)
	for index: int in Content.encounters.size():
		var encounter: EncounterData = Content.encounters[index]
		var mark: String = "✓" if index < int(GameState.run.stage) else "→" if index == int(GameState.run.stage) else "·"
		UI.label(route, "%s   %02d  /  %s" % [mark, index + 1, encounter.display_name], 21, UI.GOLD if index == int(GameState.run.stage) else UI.MUTED)
	UI.spacer(route, 10)
	UI.label(route, "Victory restores your health. Defeat costs no gold and allows a fresh attempt. Shops refresh after each victory.", 16, UI.MUTED, true)
	UI.label(route, "Run seed  %d" % int(GameState.run.seed), 13, UI.MUTED)
	var next: VBoxContainer = UI.column(UI.panel(screen, Rect2(705, 153, 520, 545)), 15)
	UI.label(next, "NEXT TRIAL", 16, UI.GOLD)
	UI.label(next, Content.encounters[int(GameState.run.stage)].display_name, 30)
	UI.label(next, Content.encounters[int(GameState.run.stage)].description, 17, UI.MUTED, true)
	UI.spacer(next, 6)
	UI.button(next, "Choose your challenge  →", show_encounters, true)
	UI.button(next, "Character & spell loadout", show_build)
	var shops: HBoxContainer = UI.row(next)
	UI.button(shops, "Magic shop", func() -> void: show_shop("spell")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.button(shops, "Gear shop", func() -> void: show_shop("gear")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if int(GameState.run.choices) > 0:
		UI.button(next, "Choose level bonus  (%d)" % int(GameState.run.choices), show_level_choices, true)
	UI.button(next, "Save & return to title", func() -> void: GameState.persist(); show_title())
	if not GameState.save_error.is_empty():
		UI.label(next, GameState.save_error, 14, Color("f59a63"), true)
	var tip: VBoxContainer = UI.column(UI.panel(screen, Rect2(55, 674, 570, 85)), 4)
	UI.label(tip, "BUILD NOTE  /  Mixing schools is encouraged", 16, UI.GOLD)
	UI.label(tip, "Freeze → Earth shatters. Vortex → area spells catches a crowd.", 14, UI.MUTED, true)

func show_shop(kind: String) -> void:
	clear_screen("shop")
	header("The spellwright" if kind == "spell" else "The quartermaster", "Three offers per visit. New stock arrives after each victory.", show_hub)
	var offers: Array = GameState.run[kind + "_offers"]
	var collection: Dictionary = Content.spells if kind == "spell" else Content.gear
	var owned: Array = GameState.run.owned_spells if kind == "spell" else GameState.run.owned_gear
	for index: int in offers.size():
		var id: String = offers[index]
		var item: Resource = collection[id]
		var box: VBoxContainer = UI.column(UI.panel(screen, Rect2(55 + index * 400, 164, 370, 483)), 18)
		var icon: TextureRect = TextureRect.new()
		icon.texture = item.icon
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
		UI.label(box, item.element.to_upper() if kind == "spell" else item.slot.to_upper(), 15, UI.GOLD)
		UI.label(box, item.display_name, 27, UI.WHITE, true)
		UI.label(box, item.description, 17, UI.MUTED, true)
		if kind == "spell":
			UI.label(box, "%.0f damage\n%.1fs cooldown   /   %.1fs cast\n%s   /   %.0f range" % [item.damage, item.cooldown, item.cast_time, item.targeting.replace("_", " ").capitalize(), item.reach], 16)
		else:
			var equipped: String = GameState.run.equipment.get(item.slot, "")
			UI.label(box, "Equipped: " + (Content.gear[equipped].display_name if not equipped.is_empty() else "None"), 15, UI.MUTED, true)
		var space: Control = Control.new()
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(space)
		var buy: Button = UI.button(box, "Owned" if owned.has(id) else "Acquire  ·  %d gold" % item.price, func() -> void: GameState.purchase(kind, id); show_shop(kind), true)
		buy.disabled = owned.has(id) or int(GameState.run.gold) < item.price
		buy.tooltip_text = item.tooltip(GameState.stats()) if kind == "spell" else item.description
	if offers.is_empty():
		UI.label(UI.column(UI.panel(screen, Rect2(250, 250, 780, 200))), "You own all available items in this collection.", 25, UI.GOLD)
	var footer: VBoxContainer = UI.column(UI.panel(screen, Rect2(55, 679, 1170, 80)), 4)
	UI.label(footer, "Acquired spells and gear go to your collection. Equip them on the Character & spell loadout screen.", 17, UI.MUTED, true)
	UI.button(footer, "Open character & loadout", show_build)

func show_build() -> void:
	clear_screen("build")
	header("%s  /  Character & build" % GameState.run.name, "Choose a QWER slot, then an owned spell. Equipping a spell already in use swaps the two slots.", show_hub)
	var stats: Dictionary = GameState.stats()
	var summary: VBoxContainer = UI.column(UI.panel(screen, Rect2(35, 144, 290, 610)), 12)
	UI.label(summary, "BATTLEMAGE  ·  Lv. %d" % int(GameState.run.level), 20, UI.GOLD)
	UI.label(summary, "%d XP   /   %s" % [int(GameState.run.xp), str(int(Content.economy.xp_thresholds[int(GameState.run.level)])) + " next level" if int(GameState.run.level) < 5 else "Level cap"], 15, UI.MUTED, true)
	UI.label(summary, "%.0f maximum health\n+%.0f%% spell power\n-%.0f%% cooldown duration\n+%.0f%% movement speed\n+%.0f%% spell area\n-%.0f%% cast time" % [stats.max_hp, stats.power * 100, stats.cooldown * 100, stats.speed * 100, stats.area * 100, stats.cast_speed * 100], 17)
	UI.spacer(summary, 6)
	UI.label(summary, "EQUIPPED GEAR", 15, UI.GOLD)
	for slot: String in ["Staff", "Robe", "Boots", "Ring"]:
		var id: String = GameState.run.equipment.get(slot, "")
		var gear_row: HBoxContainer = UI.row(summary, 4)
		UI.label(gear_row, slot + "\n" + (Content.gear[id].display_name if not id.is_empty() else "None"), 14, UI.WHITE, true)
		if not id.is_empty():
			var remove: Button = UI.button(gear_row, "×", func() -> void: GameState.unequip_gear(slot); show_build())
			remove.tooltip_text = "Remove " + slot.to_lower()
			remove.custom_minimum_size.y = 28
	var loadout: VBoxContainer = UI.column(UI.panel(screen, Rect2(345, 144, 890, 119)), 7)
	UI.label(loadout, "EQUIPPED SPELLS", 15, UI.GOLD)
	var slots: HBoxContainer = UI.row(loadout, 8)
	for index: int in 4:
		var spell: SpellData = Content.spells[GameState.run.loadout[index]]
		var button: Button = UI.button(slots, "%s  /  %s" % [["Q", "W", "E", "R"][index], spell.display_name], func() -> void: selected_build_slot = index; show_build(), selected_build_slot == index)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = spell.tooltip(stats)
	var tabs: TabContainer = TabContainer.new()
	tabs.position = Vector2(345, 283)
	tabs.size = Vector2(890, 471)
	screen.add_child(tabs)
	for kind: String in ["Spells", "Gear"]:
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.name = kind
		tabs.add_child(scroll)
		var list: VBoxContainer = UI.column(scroll, 9)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ids: Array = GameState.run.owned_spells if kind == "Spells" else GameState.run.owned_gear
		if ids.is_empty(): UI.label(list, "Visit the gear shop to acquire your first item.", 18, UI.MUTED)
		for id: String in ids:
			var item: Resource = Content.spells[id] if kind == "Spells" else Content.gear[id]
			var card: PanelContainer = PanelContainer.new()
			card.add_theme_stylebox_override("panel", UI.box())
			list.add_child(card)
			var row: HBoxContainer = UI.row(card)
			var desc: VBoxContainer = UI.column(row, 4)
			desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UI.label(desc, item.display_name + "  ·  " + (item.element if kind == "Spells" else item.slot), 20, UI.GOLD)
			UI.label(desc, item.description, 15, UI.MUTED, true)
			var equip: Button = UI.button(row, "Equip to " + ["Q", "W", "E", "R"][selected_build_slot] if kind == "Spells" else "Equip", func() -> void:
				if kind == "Spells": GameState.equip_spell(selected_build_slot, id)
				else: GameState.equip_gear(id)
				show_build())
			equip.tooltip_text = item.tooltip(stats) if kind == "Spells" else item.description

func show_encounters() -> void:
	clear_screen("encounters")
	var encounter: EncounterData = Content.encounters[int(GameState.run.stage)]
	header(encounter.display_name, encounter.description, show_hub)
	for index: int in 3:
		var data: Dictionary = Content.economy.difficulty[index]
		var rewards: Dictionary = GameState.reward_for(int(GameState.run.stage), index, GameState.enemy_ids(int(GameState.run.stage), index))
		var box: VBoxContainer = UI.column(UI.panel(screen, Rect2(65 + index * 400, 190, 350, 405)), 20)
		UI.label(box, ["I", "II", "III"][index], 50, UI.GOLD)
		UI.label(box, data.name, 30)
		UI.label(box, ["Room to learn. Gentler damage and more breathing space.", "The intended challenge. Read each wind-up and commit to your casts.", "Relentless pressure. Faster attacks, stronger foes, and richer rewards."][index], 18, UI.MUTED, true)
		UI.label(box, "%d gold  /  %d XP" % [rewards.gold, rewards.xp], 21, UI.GOLD)
		UI.label(box, "%d wave%s" % [encounter.waves, "s" if encounter.waves > 1 else ""], 15, UI.MUTED)
		UI.label(box, "%d%% enemy health · %d%% damage" % [roundi(float(data.health) * 100), roundi(float(data.damage) * 100)], 14, UI.MUTED)
		UI.button(box, "Enter arena", func() -> void: start_combat(index), index == 1)
	var rules: VBoxContainer = UI.column(UI.panel(screen, Rect2(65, 627, 1150, 126)), 5)
	UI.label(rules, "RIGHT-CLICK move    /    Q W E R select    /    LEFT-CLICK cast    /    SPACE dodge    /    ESC pause", 17, UI.GOLD, true)
	UI.label(rules, "All spells use cooldowns. Cast-time spells root you; dodge cancels the cast without spending its cooldown. Defeat preserves your build and gold.", 16, UI.MUTED, true)

func start_combat(difficulty: int) -> void:
	clear_screen("combat")
	arena = ArenaDirector.new()
	add_child(arena)
	arena.begin(int(GameState.run.stage), difficulty)
	arena.finished.connect(func(_result: Dictionary) -> void: show_reward())
	build_hud()

func build_hud() -> void:
	var top: VBoxContainer = UI.column(UI.panel(screen, Rect2(345, 16, 590, 67), Color(0.035, 0.065, 0.10, 0.94)), 2)
	hud.title = UI.label(top, Content.encounters[arena.stage].display_name.to_upper(), 20, UI.GOLD)
	hud.title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.encounter = UI.label(top, "", 14, UI.MUTED)
	hud.encounter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var health_box: VBoxContainer = UI.column(UI.panel(screen, Rect2(22, 205, 228, 211)), 10)
	UI.label(health_box, GameState.run.name.to_upper(), 20, UI.GOLD)
	hud.health = UI.label(health_box, "", 18)
	hud.health_bar = UI.bar(health_box, arena.player.health.current, arena.player.health.maximum)
	hud.dodge = UI.label(health_box, "", 15, UI.MUTED)
	hud.status = UI.label(health_box, "", 13, UI.GOLD, true)
	var guide: VBoxContainer = UI.column(UI.panel(screen, Rect2(1030, 194, 228, 300)), 12)
	UI.label(guide, "COMBAT FIELD GUIDE", 14, UI.GOLD)
	UI.label(guide, "RMB   Move\nQWER   Select spell\nLMB   Confirm cast\nSPACE   Dodge\nESC   Cancel / pause", 16, UI.WHITE)
	hud.selection = UI.label(guide, "Select a spell to see its range.", 15, UI.MUTED, true)
	UI.button(guide, "Pause", func() -> void: show_settings(true))
	var cast_box: VBoxContainer = UI.column(UI.panel(screen, Rect2(22, 437, 228, 111)), 7)
	hud.cast = UI.label(cast_box, "READY", 14, UI.GOLD, true)
	hud.cast_bar = UI.bar(cast_box, 0, 1)
	var bottom: HBoxContainer = UI.row(UI.panel(screen, Rect2(257, 709, 766, 78)), 8)
	for index: int in 4:
		var spell: SpellData = Content.spells[arena.player.loadout[index]]
		var button: Button = UI.button(bottom, "", func() -> void: arena.player.select_slot(index))
		button.custom_minimum_size = Vector2(168, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = spell.icon
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 20)
		button.add_theme_font_size_override("font_size", 15)
		button.tooltip_text = spell.tooltip(arena.player.modifiers)
		slot_buttons.append(button)
	hud.announcement = UI.label(screen, "", 35, UI.GOLD)
	hud.announcement.position = Vector2(310, 336)
	hud.announcement.size = Vector2(660, 80)
	hud.announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tutorial: VBoxContainer = UI.column(UI.panel(screen, Rect2(22, 563, 228, 185)), 7)
	hud.tutorial_box = tutorial.get_parent()
	hud.tutorial = UI.label(tutorial, "", 14, UI.MUTED, true)
	UI.button(tutorial, "Got it · hide tips", func() -> void: arena.player.dismiss_tutorial())
	if Content.encounters[arena.stage].kind != "creatures":
		var boss: VBoxContainer = UI.column(UI.panel(screen, Rect2(450, 88, 380, 70)), 4)
		hud.boss_name = UI.label(boss, arena.enemies[0].display_name, 15, UI.GOLD)
		hud.boss = UI.bar(boss, 100, 100)

func _process(_delta: float) -> void:
	if current_page != "combat" or not is_instance_valid(arena) or hud.is_empty():
		return
	var player: PlayerFighter = arena.player
	hud.health.text = "%d / %d HP" % [ceili(player.health.current), ceili(player.health.maximum)]
	hud.health_bar.value = player.health.current
	var dodge_text: PackedStringArray = []
	for timer: float in player.dodge_timers:
		dodge_text.append("READY" if timer <= 0.0 else "%.1fs" % timer)
	hud.dodge.text = "DODGE  " + "  /  ".join(dodge_text)
	hud.status.text = "  ".join(player.statuses.active.keys()).to_upper()
	if player.barrier > 0: hud.status.text += "  BARRIER %.0f" % player.barrier
	if player.guard_time > 0: hud.status.text += "  GUARD %.1fs" % player.guard_time
	hud.cast.text = "CASTING  " + player.casting.display_name if player.casting != null else "READY TO CAST"
	hud.cast_bar.value = 1.0 - player.cast_remaining / player.cast_total if player.casting != null else 0.0
	hud.selection.text = player.selected.display_name + "\nLeft-click to confirm.\nRight-click to cancel & move." if player.selected != null else "Select a spell to see its range."
	hud.tutorial.text = player.hint
	hud.tutorial_box.visible = not player.tutorial_done
	var living: int = 0
	for enemy: EnemyFighter in arena.enemies:
		if not enemy.health.dead: living += 1
	hud.encounter.text = "%s  /  Wave %d of %d  /  %d opponents" % [Content.economy.difficulty[arena.difficulty].name, arena.wave_number, Content.encounters[arena.stage].waves, living]
	if hud.has("boss"):
		hud.boss.value = arena.enemies[0].health.current / arena.enemies[0].health.maximum * 100
	for index: int in slot_buttons.size():
		var spell: SpellData = Content.spells[player.loadout[index]]
		var cooldown: float = float(player.cooldowns.get(spell.id, 0.0))
		slot_buttons[index].text = "%s  %s\n%s" % [["Q", "W", "E", "R"][index], spell.display_name, "%.1fs" % cooldown if cooldown > 0 else "SELECTED" if player.selected == spell else "Ready"]
		slot_buttons[index].modulate = Color("788696") if cooldown > 0 else Content.colors[spell.element] if player.selected == spell else Color.WHITE
	if arena.intro > 0.0:
		hud.announcement.text = "PREPARE   %d" % ceili(arena.intro)
	elif arena.ended:
		hud.announcement.text = "VICTORY" if arena.result.get("victory", false) else "DEFEAT"
	else:
		hud.announcement.text = ""

func show_reward() -> void:
	clear_screen("reward")
	var result: Dictionary = GameState.last_result
	var won: bool = result.get("victory", false)
	header("Victory · a step toward the crown" if won else "Defeat · the arena awaits your return", "Your progress has been saved." if GameState.save_error.is_empty() else GameState.save_error)
	var box: VBoxContainer = UI.column(UI.panel(screen, Rect2(725, 163, 475, 495)), 22)
	UI.label(box, "TRIAL CONQUERED" if won else "A LESSON, NOT AN END", 16, UI.GOLD)
	UI.label(box, Content.encounters[int(result.get("stage", 0))].display_name, 31, UI.WHITE, true)
	if won:
		UI.label(box, "+%d gold\n+%d experience" % [result.gold, result.xp], 29, UI.GOLD)
		UI.label(box, "%d / 5 trials completed\nShops have new stock. Health restored next battle." % int(GameState.run.stage), 18, UI.MUTED, true)
		if int(GameState.run.choices) > 0:
			UI.button(box, "Level %d  ·  Choose your bonus" % int(GameState.run.level), show_level_choices, true)
		UI.button(box, "Claim the crown" if GameState.run.complete else "Return to antechamber", show_completion if GameState.run.complete else show_hub, true)
	else:
		UI.label(box, "No gold or experience lost. Study the wind-ups, change your build, and try again.", 19, UI.MUTED, true)
		UI.button(box, "Choose difficulty & retry", show_encounters, true)
		UI.button(box, "Return to antechamber", show_hub)

func show_level_choices() -> void:
	if int(GameState.run.choices) <= 0:
		show_hub()
		return
	clear_screen("level")
	header("Grow your power", "%d level bonus choices remaining. Each choice lasts for this character." % int(GameState.run.choices), show_hub)
	var choices: Array = [["max_hp", "VITALITY", "+25 maximum health"], ["power", "POTENCY", "+10% all spell damage"], ["cooldown", "RHYTHM", "-6% spell cooldown duration"], ["dodge_recharge", "AGILITY", "-12% dodge recharge time"], ["status_duration", "CONTROL", "+20% status duration"]]
	var box: VBoxContainer = UI.column(UI.panel(screen, Rect2(700, 156, 515, 545)), 13)
	for choice: Array in choices:
		UI.label(box, choice[1], 16, UI.GOLD)
		UI.button(box, choice[2], func() -> void: GameState.choose_bonus(choice[0]); show_level_choices())

func show_completion() -> void:
	clear_screen("completion")
	header("Local Arena · conquered", "Your first crown is earned. This concludes the playable demo.")
	var box: VBoxContainer = UI.column(UI.panel(screen, Rect2(718, 160, 500, 525)), 21)
	UI.label(box, "THE CROWN IS YOURS", 30, UI.GOLD)
	UI.label(box, "%s, Arena Champion" % GameState.run.name, 25, UI.WHITE, true)
	UI.label(box, "Five trials. Four spell slots. A build of your own.", 20, UI.MUTED, true)
	UI.label(box, "LOCAL  →  CITY  →  REGION\n→  NATION  →  THE BATTLEMAGE", 18, UI.GOLD, true)
	UI.label(box, "Higher arenas belong to the full game. Begin again with another school and discover a different path.", 18, UI.MUTED, true)
	UI.button(box, "Create another battlemage", confirm_new, true)
	UI.button(box, "Return to title", show_title)

func make_overlay() -> VBoxContainer:
	if is_instance_valid(overlay):
		screen.remove_child(overlay)
		overlay.queue_free()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(overlay)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.04, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	return UI.column(UI.panel(overlay, Rect2(370, 83, 540, 640)), 13)

func close_overlay() -> void:
	if is_instance_valid(overlay):
		screen.remove_child(overlay)
		overlay.queue_free()
	overlay = null
	get_tree().paused = false

func show_notice(message: String) -> void:
	var box: VBoxContainer = make_overlay()
	UI.label(box, message, 21, UI.GOLD, true)
	UI.button(box, "Close", close_overlay)

func show_modal(title: String, message: String, confirm: String, action: Callable) -> void:
	var box: VBoxContainer = make_overlay()
	UI.label(box, title, 27, UI.GOLD, true)
	UI.label(box, message, 18, UI.MUTED, true)
	UI.button(box, confirm, func() -> void: close_overlay(); action.call(), true)
	UI.button(box, "Cancel", close_overlay)

func show_settings(paused: bool) -> void:
	get_tree().paused = paused
	var box: VBoxContainer = make_overlay()
	UI.label(box, "Combat paused" if paused else "Settings", 29, UI.GOLD)
	for pair: Array in [["master", "Master volume"], ["music", "Music volume"], ["sfx", "Sound effects"], ["shake", "Screen shake"], ["ui_scale", "Text scale"]]:
		var row: HBoxContainer = UI.row(box)
		UI.label(row, pair[1], 17).custom_minimum_size.x = 180
		var slider: HSlider = HSlider.new()
		slider.min_value = 0.85 if pair[0] == "ui_scale" else 0.0
		slider.max_value = 1.15 if pair[0] == "ui_scale" else 1.0
		slider.step = 0.05
		slider.value = float(GameState.settings[pair[0]])
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(func(value: float) -> void: GameState.settings[pair[0]] = value; GameState.save_settings())
		row.add_child(slider)
	for pair: Array in [["numbers", "Show damage numbers"], ["fullscreen", "Fullscreen"]]:
		var check: CheckButton = CheckButton.new()
		check.text = pair[1]
		check.button_pressed = GameState.settings[pair[0]]
		check.toggled.connect(func(value: bool) -> void: GameState.settings[pair[0]] = value; GameState.save_settings())
		box.add_child(check)
	UI.label(box, "Text scaling applies when opening the next screen. Targeting uses outlines and shapes as well as color.", 14, UI.MUTED, true)
	UI.button(box, "Resume" if paused else "Done", close_overlay, true)
	if paused:
		UI.button(box, "Leave fight & return to hub", func() -> void:
			GameState.in_combat = false
			GameState.persist()
			close_overlay()
			show_hub())
		UI.button(box, "Save & return to title", func() -> void:
			GameState.in_combat = false
			GameState.persist()
			close_overlay()
			show_title())
	UI.button(box, "Quit game", func() -> void: GameState.persist(); Sound.shutdown())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if is_instance_valid(overlay):
				close_overlay()
			elif current_page == "combat":
				if arena.player.selected != null: arena.player.selected = null
				else: show_settings(true)
		if event.physical_keycode == KEY_F1 and OS.is_debug_build():
			show_debug()

func show_debug() -> void:
	if not OS.is_debug_build():
		return
	get_tree().paused = true
	var box: VBoxContainer = make_overlay()
	UI.label(box, "DEVELOPMENT  /  F1", 23, UI.GOLD)
	if GameState.run.is_empty():
		UI.button(box, "Create test character", func() -> void: GameState.new_run("Test", 0, "Emberweaver", 12345); close_overlay(); show_hub())
		return
	var tools_row: HBoxContainer = UI.row(box)
	UI.button(tools_row, "+1000 gold", func() -> void: GameState.run.gold += 1000; GameState.persist())
	UI.button(tools_row, "Level 5", func() -> void: GameState.run.level = 5; GameState.run.xp = 510; GameState.persist())
	var seed_input: LineEdit = LineEdit.new()
	seed_input.placeholder_text = "Run seed"
	seed_input.text = str(GameState.run.seed)
	box.add_child(seed_input)
	UI.button(box, "Set seed & refresh offers", func() -> void: GameState.run.seed = seed_input.text.to_int(); GameState.refresh_shops(); GameState.persist())
	var selection: OptionButton = OptionButton.new()
	for id: String in Content.spells:
		if not Content.spells[id].tags.has("enemy_only"):
			selection.add_item(Content.spells[id].display_name)
			selection.set_item_metadata(selection.item_count - 1, id)
	box.add_child(selection)
	UI.button(box, "Add spell / equip in Q", func() -> void:
		var id: String = selection.get_item_metadata(selection.selected)
		if not GameState.run.owned_spells.has(id): GameState.run.owned_spells.append(id)
		if is_instance_valid(arena):
			arena.player.loadout[0] = id
		else: GameState.equip_spell(0, id))
	var gear_select: OptionButton = OptionButton.new()
	for id: String in Content.gear:
		gear_select.add_item(Content.gear[id].display_name)
		gear_select.set_item_metadata(gear_select.item_count - 1, id)
	box.add_child(gear_select)
	UI.button(box, "Grant & equip gear", func() -> void:
		var id: String = gear_select.get_item_metadata(gear_select.selected)
		if not GameState.run.owned_gear.has(id): GameState.run.owned_gear.append(id)
		GameState.run.equipment[Content.gear[id].slot] = id
		if is_instance_valid(arena): arena.player.modifiers = GameState.stats()
		GameState.persist())
	if is_instance_valid(arena):
		var enemies: OptionButton = OptionButton.new()
		for id: String in Content.enemies:
			enemies.add_item(Content.enemies[id].display_name)
			enemies.set_item_metadata(enemies.item_count - 1, id)
		box.add_child(enemies)
		UI.button(box, "Spawn selected opponent", func() -> void: arena.spawn_enemy(enemies.get_item_metadata(enemies.selected), ArenaDirector.CENTER + Vector2(150, 0)))
		var row: HBoxContainer = UI.row(box)
		UI.button(row, "Reset cooldowns", func() -> void: arena.player.cooldowns.clear(); arena.player.dodge_timers.fill(0.0))
		UI.button(row, "Invulnerability", func() -> void: arena.player.debug_invulnerable = not arena.player.debug_invulnerable)
		UI.button(box, "Win encounter", func() -> void: close_overlay(); arena.active = true; arena.end_battle(true))
	else:
		UI.button(box, "Load arena", func() -> void: close_overlay(); start_combat(1))
	UI.button(box, "Close", close_overlay)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.persist()
		Sound.shutdown()
