"""Finish the shop and build screens using the shared production theme."""
from pathlib import Path
p=Path("scripts/ui/main.gd")
s=p.read_text(encoding="utf8")
def replace(name,new):
 global s
 a=s.index("func "+name+"(")
 b=s.find("\nfunc ",a+5)
 if b<0:b=len(s)
 s=s[:a]+new.strip()+"\n"+s[b:]
replace('show_shop',r'''
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
''')
replace('show_build',r'''
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
''')
if "var selected_collection_tab" not in s:
 s=s.replace('var selected_build_slot: int = 0','var selected_build_slot: int = 0\nvar selected_collection_tab: int = 0')
p.write_text(s,encoding='utf8')
print('Shop and loadout replaced')
