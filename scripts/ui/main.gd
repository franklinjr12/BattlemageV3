extends Node
var screen: Control
var background: Node2D
var arena: ArenaDirector
var overlay: Control
var current_page: String = "title"
var hud: Dictionary = {}
var slot_buttons: Array[Button] = []
var selected_build_slot: int = 0
var selected_collection_tab: int = 0
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
			if page in ["combat", "champion", "arena_edge", "magic"]:
				if page == "champion": GameState.run.stage = 4
				start_combat(1)
				if page == "arena_edge":
					arena.player.position = ArenaDirector.CENTER + Vector2(ArenaDirector.RADIUS - 160.0, 0.0)
					arena.player.destination = arena.player.position
			elif page == "shop":
				show_shop("spell")
			elif page == "gear":
				show_shop("gear")
			elif page == "encounters":
				show_encounters()
			elif page == "level":
				GameState.run.choices = 1
				show_level_choices()
			elif page == "reward":
				GameState.last_result = {"victory": true, "stage": 0, "gold": 120, "xp": 75}
				show_reward()
			elif page == "pause":
				start_combat(1)
				show_settings(true)
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
		if page == "magic" and frame == 140 and is_instance_valid(arena):
			arena.intro = 0.0
			arena.active = true
			var actor: PlayerFighter = arena.player
			actor.execute_spell(Content.spells.fireball, actor.position + Vector2(155, -85))
			actor.execute_spell(Content.spells.frost_nova, actor.position)
			actor.execute_spell(Content.spells.vortex, actor.position + Vector2(-140, 100))
			actor.execute_spell(Content.spells.earth_pillar, actor.position + Vector2(100, 115))
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
	var card: PanelContainer = UI.featured(screen,Rect2(30,19,1220,106))
	var line: HBoxContainer = UI.row(card,16)
	var sigil: VBoxContainer = UI.column(line,2)
	UI.label(sigil,"✦",29,UI.GOLD)
	var titles: VBoxContainer = UI.column(line,3)
	titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	UI.label(titles,title,28,UI.GOLD)
	UI.label(titles,subtitle,14,UI.MUTED,true)
	if not GameState.run.is_empty():
		var funds: VBoxContainer = UI.column(line,4)
		UI.label(funds,"CURRENT BATTLEMAGE",11,UI.MUTED)
		UI.label(funds,"Lv. %d    ◆ %d gold" % [int(GameState.run.level),int(GameState.run.gold)],17,UI.GOLD)
	if back.is_valid():
		UI.button(line,"← Back",back)


func show_title() -> void:
	clear_screen("title")
	GameState.in_combat=false
	var legend: VBoxContainer=UI.column(UI.featured(screen,Rect2(70,100,615,573)),13)
	UI.section(legend,"THE LOCAL ARENA    /    ASCENSION")
	UI.label(legend,"FOUR SCHOOLS. ONE CROWN.",29,UI.GOLD)
	UI.label(legend,"Master the elements. Survive five trials.\nEarn your name among the champions.",17,UI.MUTED,true)
	var fighters: HBoxContainer=UI.row(legend,9)
	for actor_id: String in ["pyromancer","champion","cryomancer"]:
		var frame: PanelContainer=PanelContainer.new()
		frame.add_theme_stylebox_override("panel",UI.texture_skin("portrait"))
		frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		fighters.add_child(frame)
		var col: VBoxContainer=UI.column(frame,4)
		UI.actor_portrait(col,actor_id,145)
		UI.label(col,{"pyromancer":"FIRE","champion":"THE CROWN","cryomancer":"ICE"}[actor_id],13,UI.GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	UI.rule(legend)
	UI.label(legend,"FIRE   ◆   ICE   ◆   EARTH   ◆   AIR",18,UI.WHITE).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	UI.spacer(legend,12)
	UI.rule(legend)
	UI.label(legend,"THE ARENA REMEMBERS EVERY CAST",21,UI.GOLD,true)
	UI.label(legend,"Adapt your spells. Read your rivals. Your build is the difference between defeat and the crown.",15,UI.MUTED,true)
	var box: VBoxContainer=UI.column(UI.featured(screen,Rect2(731,119,482,536),true),13)
	UI.label(box,"B A T T L E M A G E",25,UI.GOLD)
	UI.label(box,"A R E N A",49,UI.WHITE)
	UI.label(box,"LOCAL ASCENSION",14,UI.MUTED)
	UI.rule(box)
	UI.label(box,"Choose your path, shape your spellbook,\nand stand before the crown.",17,UI.WHITE,true)
	UI.spacer(box,8)
	UI.button(box,"Create a battlemage",confirm_new,true)
	var resume: Button=UI.button(box,"Continue journey",func() -> void:
		if GameState.load_run():
			if GameState.run.complete: show_completion()
			else: show_hub()
		else: show_notice(GameState.save_error))
	resume.disabled=not FileAccess.file_exists(GameState.SAVE_PATH) and not FileAccess.file_exists(GameState.SAVE_PATH+".bak")
	var utility: HBoxContainer=UI.row(box,8)
	UI.button(utility,"Settings",func() -> void: show_settings(false)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	UI.button(utility,"Quit",func() -> void: Sound.shutdown()).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	UI.label(box,"RIGHT-CLICK MOVE   ◆   Q/W/E/R SPELLS   ◆   SPACE DODGE",12,UI.MUTED,true)

func confirm_new() -> void:
	if not GameState.run.is_empty() or FileAccess.file_exists(GameState.SAVE_PATH):
		show_modal("Begin a new journey?", "Creating a new character replaces the saved run. Your settings are kept.", "Create character", show_creation)
	else:
		show_creation()


func show_creation() -> void:
	clear_screen("creation")
	header("Create your battlemage","Choose a mantle and one starting collection; every school remains available.",show_title)
	var identity: VBoxContainer=UI.column(UI.featured(screen,Rect2(51,151,426,576)),10)
	UI.section(identity,"01  /  IDENTITY")
	UI.actor_portrait(identity,"player",105)
	UI.label(identity,"THE UNTESTED MAGE",18,UI.GOLD)
	UI.label(identity,"Your name will be spoken across the arena.",14,UI.MUTED,true)
	UI.label(identity,"Battlemage name",16)
	var name_field: LineEdit=LineEdit.new()
	name_field.text=creation_name
	name_field.max_length=24
	name_field.custom_minimum_size.y=45
	name_field.text_changed.connect(func(value: String) -> void: creation_name=value)
	identity.add_child(name_field)
	UI.section(identity,"MANTLE APPEARANCE")
	for index: int in 4:
		var names: Array=["Moonstone blue","Ember orange","Sunworn gold","Verdant green"]
		var palette: Array=[UI.ICE,UI.FIRE,UI.EARTH,UI.AIR]
		var row: HBoxContainer=UI.row(identity,8)
		UI.label(row,"◆",18,palette[index])
		var color_button: Button=UI.button(row,names[index]+("  ✓" if index==creation_appearance else ""),func() -> void: creation_appearance=index; show_creation(),index==creation_appearance)
		color_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		color_button.custom_minimum_size.y=37
	UI.label(identity,"Cosmetic choice only. Your spell schools remain flexible.",13,UI.MUTED,true)
	var choices: VBoxContainer=UI.column(UI.featured(screen,Rect2(495,151,733,576)),9)
	UI.section(choices,"02  /  STARTING MAGIC")
	for package_name: String in Content.packages:
		var pkg: Dictionary=Content.packages[package_name]
		var selected: bool=creation_package==package_name
		var frame: PanelContainer=PanelContainer.new()
		frame.add_theme_stylebox_override("panel",UI.texture_skin("portrait" if selected else "tooltip"))
		choices.add_child(frame)
		var info: HBoxContainer=UI.row(frame,12)
		var skill_id: String=str(pkg.spells[0])
		UI.item_icon(info,Content.spells[skill_id].icon,56)
		var details: VBoxContainer=UI.column(info,3)
		details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		UI.label(details,package_name.to_upper()+("   ◆ SELECTED" if selected else ""),18,UI.GOLD)
		UI.label(details,pkg.description,13,UI.MUTED,true)
		var spell_names: PackedStringArray=[]
		for id: String in pkg.spells:spell_names.append(Content.spells[id].display_name)
		UI.label(details,"  •  ".join(spell_names),13,UI.WHITE,true)
		var choose: Button=UI.button(info,"SELECTED" if selected else "Choose",func() -> void: creation_package=package_name; show_creation(),selected)
		choose.custom_minimum_size.x=108
	UI.spacer(choices,5)
	UI.button(choices,"Enter the Local Arena   →",func() -> void: GameState.new_run(creation_name,creation_appearance,creation_package); show_hub(),true)


func show_hub() -> void:
	if GameState.run.complete:
		show_completion()
		return
	clear_screen("hub")
	header("The antechamber","%s  ·  Local Arena  ·  %d of 5 trials conquered" % [GameState.run.name,int(GameState.run.stage)],show_title)
	var route: VBoxContainer=UI.column(UI.featured(screen,Rect2(53,151,571,566)),8)
	UI.section(route,"THE ROAD TO THE CROWN")
	for index: int in Content.encounters.size():
		var encounter: EncounterData=Content.encounters[index]
		var status: String="CONQUERED" if index<int(GameState.run.stage) else ("NEXT CHALLENGE" if index==int(GameState.run.stage) else "LOCKED")
		var card: VBoxContainer=UI.detail_card(route,"%02d    %s" % [index+1,encounter.display_name],status,UI.GOLD if index==int(GameState.run.stage) else UI.MUTED)
		card.custom_minimum_size.y=49
	UI.label(route,"Five trials. Every victory draws you closer to the crown.",14,UI.MUTED,true)
	var next: VBoxContainer=UI.column(UI.featured(screen,Rect2(688,151,540,566),true),10)
	UI.section(next,"YOUR NEXT TRIAL")
	var next_encounter: EncounterData=Content.encounters[int(GameState.run.stage)]
	var preview: HBoxContainer=UI.row(next,15)
	var representative: Array=["pyromancer","cryomancer","hound","battlemage","champion"]
	UI.actor_portrait(preview,representative[mini(int(GameState.run.stage),4)],132)
	var description: VBoxContainer=UI.column(preview,4)
	description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	UI.label(description,next_encounter.display_name,30,UI.GOLD,true)
	UI.label(description,next_encounter.description,15,UI.MUTED,true)
	UI.rule(next)
	UI.button(next,"Choose your challenge   →",show_encounters,true)
	UI.button(next,"Character & spell loadout",show_build)
	var shops: HBoxContainer=UI.row(next,7)
	UI.button(shops,"Magic shop",func() -> void: show_shop("spell")).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	UI.button(shops,"Gear shop",func() -> void: show_shop("gear")).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if int(GameState.run.choices)>0:
		UI.button(next,"Choose level bonus   (%d)" % int(GameState.run.choices),show_level_choices,true)
	UI.button(next,"Save & return to title",func() -> void: GameState.persist(); show_title())
	UI.label(next,"Victory restores health. Defeat does not cost gold.",13,UI.MUTED,true)
	if not GameState.save_error.is_empty():
		UI.label(next,GameState.save_error,14,UI.FIRE,true)

func show_shop(kind: String) -> void:
	clear_screen("shop")
	header("The spellwright" if kind == "spell" else "The quartermaster", "Three offers per visit. New stock arrives after each victory.", show_hub)
	var offers: Array = GameState.run[kind + "_offers"]
	var collection: Dictionary = Content.spells if kind == "spell" else Content.gear
	var owned: Array = GameState.run.owned_spells if kind == "spell" else GameState.run.owned_gear
	for index: int in offers.size():
		var id: String = offers[index]
		var item: Resource = collection[id]
		var card: VBoxContainer = UI.column(UI.featured(screen, Rect2(43 + index * 400, 155, 386, 507), false), 11)
		UI.section(card, "THE SPELLWRIGHT" if kind == "spell" else "THE QUARTERMASTER")
		var banner: HBoxContainer = UI.row(card, 12)
		var icon_frame: PanelContainer = PanelContainer.new()
		icon_frame.add_theme_stylebox_override("panel",UI.texture_skin("portrait"))
		banner.add_child(icon_frame)
		UI.item_icon(icon_frame, item.icon, 84)
		var item_info: VBoxContainer = UI.column(banner, 5)
		item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var item_type: String = item.element if kind == "spell" else item.slot
		UI.label(item_info, item_type.to_upper(), 14, UI.color_for_school(item_type) if kind == "spell" else UI.GOLD)
		UI.label(item_info, item.display_name, 24, UI.WHITE, true)
		UI.label(item_info, "◆  OWNED" if owned.has(id) else "◆  AVAILABLE", 13, UI.MUTED)
		UI.rule(card)
		UI.label(card, item.description, 17, UI.WHITE, true)
		UI.spacer(card, 8)
		UI.section(card, "SPELL DETAILS" if kind == "spell" else "EQUIPMENT")
		if kind == "spell":
			UI.label(card, "%.0f DAMAGE    ◆    %.1fs COOLDOWN" % [item.damage, item.cooldown], 17, UI.GOLD, true)
			UI.label(card, "%.1fs cast  /  %s targeting  /  %.0f range" % [item.cast_time,item.targeting.replace("_"," "),item.reach], 14, UI.MUTED, true)
		else:
			var equipped: String = GameState.run.equipment.get(item.slot, "")
			UI.label(card, item.description, 15, UI.MUTED, true)
			UI.label(card, "Currently equipped: " + (Content.gear[equipped].display_name if not equipped.is_empty() else "None"), 14, UI.GOLD, true)
		var space: Control = Control.new()
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(space)
		UI.rule(card)
		UI.label(card, "◆  %d GOLD" % int(item.price), 21, UI.GOLD)
		var buy: Button = UI.button(card, "Owned" if owned.has(id) else ("Insufficient gold" if int(GameState.run.gold)<item.price else "Acquire this item"), func() -> void: GameState.purchase(kind,id);show_shop(kind),true)
		buy.disabled = owned.has(id) or int(GameState.run.gold)<item.price
		buy.tooltip_text = item.tooltip(GameState.stats()) if kind == "spell" else item.description
	if offers.is_empty():
		UI.label(UI.column(UI.featured(screen,Rect2(250,250,780,200))),"You own all available items in this collection.",25,UI.GOLD)
	var footer: VBoxContainer = UI.column(UI.panel(screen,Rect2(55,686,1170,76)),3)
	UI.label(footer, "Purchased items join your collection. Equip them on the character and spell loadout screen.", 14,UI.MUTED,true)
	UI.button(footer, "Open character & loadout   →", show_build)

func show_build() -> void:
	clear_screen("build")
	header("%s  /  Character & build" % GameState.run.name, "Select a spell slot, then choose a spell or item from your collection.", show_hub)
	var stats: Dictionary = GameState.stats()
	var summary: VBoxContainer = UI.column(UI.featured(screen,Rect2(32,145,292,607)),7)
	UI.section(summary,"YOUR BATTLEMAGE")
	var avatar: HBoxContainer = UI.row(summary,6)
	UI.actor_portrait(avatar,"player",79)
	var detail: VBoxContainer=UI.column(avatar,4)
	UI.label(detail,GameState.run.name,21,UI.GOLD)
	UI.label(detail,"LEVEL %d" % int(GameState.run.level),16,UI.WHITE)
	UI.label(detail,"%d XP" % int(GameState.run.xp),13,UI.MUTED)
	UI.rule(summary)
	UI.label(summary,"%.0f HP  ◆  +%.0f%% POWER" % [stats.max_hp,stats.power*100],16,UI.WHITE)
	UI.label(summary,"-%.0f%% COOLDOWN  ◆  +%.0f%% SPEED" % [stats.cooldown*100,stats.speed*100],14,UI.MUTED,true)
	UI.label(summary,"+%.0f%% AREA  ◆  -%.0f%% CAST TIME" % [stats.area*100,stats.cast_speed*100],14,UI.MUTED,true)
	UI.rule(summary)
	UI.section(summary,"EQUIPPED GEAR")
	for slot: String in ["Staff","Robe","Boots","Ring"]:
		var id: String = GameState.run.equipment.get(slot,"")
		var line: HBoxContainer = UI.row(summary,6)
		if not id.is_empty():
			UI.item_icon(line, Content.gear[id].icon,38)
		var txt: VBoxContainer=UI.column(line,1)
		txt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		UI.label(txt,slot.to_upper(),12,UI.MUTED)
		UI.label(txt,Content.gear[id].display_name if not id.is_empty() else "Empty slot",14,UI.WHITE,true)
		if not id.is_empty():
			var remove: Button=UI.button(line,"×",func() -> void: GameState.unequip_gear(slot);show_build())
			remove.tooltip_text="Unequip "+slot
			remove.custom_minimum_size=Vector2(33,30)
	var loadout: VBoxContainer = UI.column(UI.featured(screen,Rect2(339,145,897,159)),8)
	UI.section(loadout,"Q W E R  /  EQUIPPED SPELLS")
	var slots: HBoxContainer=UI.row(loadout,7)
	for index: int in 4:
		var spell: SpellData = Content.spells[GameState.run.loadout[index]]
		var button: Button=UI.button(slots,"%s  %s" % [["Q","W","E","R"][index],spell.display_name],func() -> void: selected_build_slot=index;show_build(), selected_build_slot==index)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y=74
		button.icon=spell.icon
		button.expand_icon=true
		button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text=spell.tooltip(stats)
	var tabs: TabContainer=TabContainer.new()
	tabs.position=Vector2(339,321)
	tabs.size=Vector2(897,433)
	screen.add_child(tabs)
	for kind: String in ["Spells","Gear"]:
		var scroll: ScrollContainer=ScrollContainer.new()
		scroll.name=kind
		tabs.add_child(scroll)
		var list: VBoxContainer=UI.column(scroll,10)
		list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var ids: Array=GameState.run.owned_spells if kind=="Spells" else GameState.run.owned_gear
		if ids.is_empty():UI.label(list,"No items yet. Visit the magic or gear shop.",18,UI.MUTED)
		for id: String in ids:
			var item: Resource = Content.spells[id] if kind=="Spells" else Content.gear[id]
			var card: PanelContainer=PanelContainer.new()
			card.add_theme_stylebox_override("panel",UI.texture_skin("tooltip"))
			list.add_child(card)
			var content: HBoxContainer=UI.row(card,13)
			UI.item_icon(content,item.icon,62)
			var desc: VBoxContainer=UI.column(content,4)
			desc.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			var category: String = item.element if kind=="Spells" else item.slot
			UI.label(desc,item.display_name+"  /  "+category,19,UI.color_for_school(category) if kind=="Spells" else UI.GOLD,true)
			UI.label(desc,item.description,14,UI.MUTED,true)
			var equip: Button=UI.button(content,"Equip to "+["Q","W","E","R"][selected_build_slot] if kind=="Spells" else "Equip",func() -> void:
				if kind=="Spells":GameState.equip_spell(selected_build_slot,id)
				else:GameState.equip_gear(id)
				show_build())
			equip.custom_minimum_size.x=158
			equip.tooltip_text=item.tooltip(stats) if kind=="Spells" else item.description
	tabs.current_tab=clampi(selected_collection_tab,0,1)
	tabs.tab_changed.connect(func(index: int) -> void: selected_collection_tab=index)

func show_encounters() -> void:
	clear_screen("encounters")
	var encounter: EncounterData=Content.encounters[int(GameState.run.stage)]
	header(encounter.display_name,encounter.description,show_hub)
	for index: int in 3:
		var data: Dictionary=Content.economy.difficulty[index]
		var rewards: Dictionary=GameState.reward_for(int(GameState.run.stage),index,GameState.enemy_ids(int(GameState.run.stage),index))
		var panel: VBoxContainer=UI.column(UI.featured(screen,Rect2(52+index*401,161,373,478),index==1),10)
		UI.section(panel,"TRIAL DIFFICULTY  /  "+["I","II","III"][index])
		UI.label(panel,data.name,31,UI.GOLD if index==1 else UI.WHITE)
		UI.actor_portrait(panel,["hound","pyromancer","champion"][index],96)
		UI.label(panel,["INITIATE","ADEPT","MASTER"][index],17,UI.GOLD)
		UI.label(panel,["Room to learn and read the arena.","The intended challenge.","Relentless pressure and greater rewards."][index],14,UI.MUTED,true)
		UI.rule(panel)
		UI.label(panel,"%d waves    ◆    %d%% health    ◆    %d%% damage" % [encounter.waves,roundi(float(data.health)*100),roundi(float(data.damage)*100)],14,UI.MUTED,true)
		UI.label(panel,"◆ %d GOLD      ✦ %d XP" % [rewards.gold,rewards.xp],20,UI.GOLD)
		UI.spacer(panel,12)
		UI.button(panel,"Enter arena   →",func() -> void: start_combat(index),index==1)
	var instructions: VBoxContainer=UI.column(UI.panel(screen,Rect2(65,664,1150,98)),5)
	UI.label(instructions,"MOVE  Right-click    ◆    SPELLS  Q W E R    ◆    CAST  Left-click    ◆    DODGE  Space    ◆    PAUSE  Esc",15,UI.GOLD,true)
	UI.label(instructions,"Cast-time spells root you. Dodge cancels a cast without spending its cooldown. Defeat preserves your gold and build.",14,UI.MUTED,true)

func start_combat(difficulty: int) -> void:
	clear_screen("combat")
	arena = ArenaDirector.new()
	add_child(arena)
	arena.begin(int(GameState.run.stage), difficulty)
	arena.finished.connect(func(_result: Dictionary) -> void: show_reward())
	build_hud()

func build_hud() -> void:
	var top: VBoxContainer = UI.column(UI.panel(screen, Rect2(394, 14, 492, 60), Color(0.035, 0.065, 0.10, 0.91)), 1)
	hud.title = UI.label(top, Content.encounters[arena.stage].display_name.to_upper(), 19, UI.GOLD)
	hud.title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.encounter = UI.label(top, "", 13, UI.MUTED)
	hud.encounter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var player_box: VBoxContainer = UI.column(UI.panel(screen, Rect2(18, 16, 318, 184), Color(0.032, 0.065, 0.11, 0.93)), 5)
	var header_row: HBoxContainer = UI.row(player_box, 10)
	var portrait: TextureRect = TextureRect.new()
	var portrait_atlas := AtlasTexture.new()
	portrait_atlas.atlas = load("res://art/sprites/actors/player.png")
	portrait_atlas.region = Rect2(0, 0, 48, 48)
	portrait.texture = portrait_atlas
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(42, 42)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_row.add_child(portrait)
	var identity: VBoxContainer = UI.column(header_row, 2)
	UI.label(identity, "%s   ·   LV %d" % [GameState.run.name.to_upper(), int(GameState.run.level)], 19, UI.GOLD)
	hud.health = UI.label(identity, "", 15)
	hud.health_bar = UI.bar(player_box, arena.player.health.current, arena.player.health.maximum)
	hud.dodge = UI.label(player_box, "", 15, Color("b3e5e7"))
	hud.cast = UI.label(player_box, "READY TO CAST", 14, UI.GOLD)
	hud.cast_bar = UI.bar(player_box, 0, 1, Color("d9ae69"))
	hud.status = UI.label(player_box, "", 12, UI.MUTED, true)
	hud.status_icons = UI.row(player_box, 4)
	hud.status_icon_keys = ""

	var bottom: HBoxContainer = UI.row(UI.panel(screen, Rect2(265, 708, 750, 78), Color(0.04, 0.07, 0.12, 0.95)), 8)
	for index: int in 4:
		var spell: SpellData = Content.spells[arena.player.loadout[index]]
		var button: Button = UI.button(bottom, "", func() -> void: arena.player.select_slot(index))
		button.custom_minimum_size = Vector2(170, 53)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = spell.icon
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40)
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = spell.tooltip(arena.player.modifiers)
		slot_buttons.append(button)

	hud.announcement = UI.label(screen, "", 32, UI.GOLD)
	hud.announcement.position = Vector2(345, 330)
	hud.announcement.size = Vector2(590, 74)
	hud.announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if Content.encounters[arena.stage].kind != "creatures":
		var boss: VBoxContainer = UI.column(UI.panel(screen, Rect2(466, 81, 348, 65), Color(0.05, 0.08, 0.12, 0.91)), 2)
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
	var active_status: Array[String] = []
	for key: String in player.statuses.active.keys():
		if key in ["burn", "chill", "freeze", "stagger", "airborne", "barrier", "guard", "invulnerable"]:
			active_status.append(key)
	if player.barrier > 0.0: active_status.append("barrier")
	if player.guard_time > 0.0: active_status.append("guard")
	active_status.sort()
	var status_signature: String = ",".join(active_status)
	if status_signature != hud.status_icon_keys:
		hud.status_icon_keys = status_signature
		for child: Node in hud.status_icons.get_children():
			child.queue_free()
			hud.status_icons.remove_child(child)
		for key: String in active_status:
			var status_icon := TextureRect.new()
			status_icon.texture = load("res://art/sprites/status/%s.png" % key)
			status_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			status_icon.custom_minimum_size = Vector2(22, 22)
			status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			status_icon.tooltip_text = key.capitalize()
			hud.status_icons.add_child(status_icon)
	hud.cast.text = "CASTING  " + player.casting.display_name if player.casting != null else "READY TO CAST"
	hud.cast_bar.value = 1.0 - player.cast_remaining / player.cast_total if player.casting != null else 0.0
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
	var result: Dictionary=GameState.last_result
	var won: bool=result.get("victory",false)
	header("Victory · a step toward the crown" if won else "Defeat · the arena awaits your return","Your progress has been saved." if GameState.save_error.is_empty() else GameState.save_error)
	var left: VBoxContainer=UI.column(UI.featured(screen,Rect2(86,166,559,480)),13)
	UI.section(left,"TRIAL RECORD")
	UI.actor_portrait(left,"champion" if won else "hound",179)
	UI.label(left,"TRIAL CONQUERED" if won else "RETURN STRONGER",30,UI.GOLD)
	UI.label(left,Content.encounters[int(result.get("stage",0))].display_name,24,UI.WHITE,true)
	UI.label(left,"Every duel teaches. The crown waits for those who persist.",16,UI.MUTED,true)
	var right: VBoxContainer=UI.column(UI.featured(screen,Rect2(689,166,528,480),true),16)
	UI.section(right,"BATTLE OUTCOME")
	if won:
		UI.label(right,"◆  +%d GOLD" % int(result.gold),29,UI.GOLD)
		UI.label(right,"✦  +%d EXPERIENCE" % int(result.xp),24,UI.WHITE)
		UI.rule(right)
		UI.label(right,"%d / 5 trials completed" % int(GameState.run.stage),20,UI.GOLD)
		UI.label(right,"New offers at the shops. Health restored next battle.",16,UI.MUTED,true)
		if int(GameState.run.choices)>0:
			UI.button(right,"Choose your level bonus",show_level_choices,true)
		UI.button(right,"Claim the crown" if GameState.run.complete else "Return to antechamber",show_completion if GameState.run.complete else show_hub,true)
	else:
		UI.label(right,"The arena awaits another attempt.",20,UI.WHITE,true)
		UI.label(right,"No gold or experience lost. Study enemy wind-ups, adjust your loadout and retry.",17,UI.MUTED,true)
		UI.button(right,"Choose difficulty & retry",show_encounters,true)
		UI.button(right,"Return to antechamber",show_hub)


func show_level_choices() -> void:
	if int(GameState.run.choices)<=0:
		show_hub()
		return
	clear_screen("level")
	header("Grow your power","%d bonus choices remaining. Each choice lasts for this character." % int(GameState.run.choices),show_hub)
	var cards: VBoxContainer=UI.column(UI.featured(screen,Rect2(230,154,820,577),true),8)
	UI.section(cards,"CHOOSE YOUR ASCENSION")
	var choices: Array=[["max_hp","VITALITY","+25 maximum health"],["power","POTENCY","+10% all spell damage"],["cooldown","RHYTHM","-6% spell cooldown duration"],["dodge_recharge","AGILITY","-12% dodge recharge time"],["status_duration","CONTROL","+20% status duration"]]
	for choice: Array in choices:
		var line: HBoxContainer=UI.row(cards,14)
		var icon_label: Label=UI.label(line,"✦",21,UI.GOLD)
		icon_label.custom_minimum_size.x=32
		var value: VBoxContainer=UI.column(line,3)
		value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		UI.label(value,choice[1],18,UI.GOLD)
		UI.label(value,choice[2],14,UI.MUTED)
		var pick: Button=UI.button(line,"CHOOSE",func() -> void: GameState.choose_bonus(choice[0]);show_level_choices())
		pick.custom_minimum_size.x=139
		UI.rule(cards)


func show_completion() -> void:
	clear_screen("completion")
	header("Local Arena · conquered","Your first crown is earned. This concludes the playable demo.")
	var triumph: VBoxContainer=UI.column(UI.featured(screen,Rect2(88,142,570,591)),12)
	UI.section(triumph,"THE VICTOR OF THE LOCAL ARENA")
	UI.actor_portrait(triumph,"champion",236)
	UI.label(triumph,"THE CROWN IS YOURS",32,UI.GOLD)
	UI.label(triumph,"%s  /  ARENA CHAMPION" % GameState.run.name.to_upper(),21,UI.WHITE,true)
	UI.label(triumph,"Five trials. Four spell slots. A build of your own.",16,UI.MUTED,true)
	var next: VBoxContainer=UI.column(UI.featured(screen,Rect2(690,173,515,518),true),16)
	UI.section(next,"A LEGEND BEGINS")
	UI.label(next,"LOCAL  →  CITY  →  REGION\n→  NATION  →  THE BATTLEMAGE",21,UI.GOLD,true)
	UI.rule(next)
	UI.label(next,"Higher arenas belong to the full game. Begin again with a different starting school and shape a new legend.",18,UI.MUTED,true)
	UI.spacer(next,16)
	UI.button(next,"Create another battlemage",confirm_new,true)
	UI.button(next,"Return to title",show_title)

func make_overlay(tall: bool = false) -> VBoxContainer:
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
	return UI.column(UI.featured(overlay, Rect2(370, 86 if tall else 245, 540, 615 if tall else 310), true), 13)

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
	var box: VBoxContainer = make_overlay(true)
	UI.label(box, "Combat paused" if paused else "Settings", 29, UI.GOLD)
	for pair: Array in [["master", "Master volume"], ["music", "Music volume"], ["sfx", "Sound effects"], ["shake", "Screen shake"], ["ui_scale", "Text scale"], ["fx_quality", "Spell VFX intensity"]]:
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
