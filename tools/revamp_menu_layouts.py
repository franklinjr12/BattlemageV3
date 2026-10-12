"""Focused noncombat menu composition refresh. Re-apply only to original or reset main.gd."""
from pathlib import Path
p=Path('scripts/ui/main.gd')
text=p.read_text(encoding='utf8')
def replace_func(name,code):
 global text
 start=text.find('func '+name+'(')
 if start<0: raise RuntimeError('not found '+name)
 end=text.find('\nfunc ',start+5)
 if end<0: end=len(text)
 text=text[:start]+code.rstrip()+'\n'+text[end:]

replace_func('header',r'''
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
''')

replace_func('show_title',r'''
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
''')

replace_func('show_creation',r'''
func show_creation() -> void:
 clear_screen("creation")
 header("Create your battlemage","Choose a mantle and one starting collection; every school remains available.",show_title)
 var identity: VBoxContainer=UI.column(UI.featured(screen,Rect2(51,151,426,576)),10)
 UI.section(identity,"01  /  IDENTITY")
 var hero: HBoxContainer=UI.row(identity,11)
 UI.actor_portrait(hero,"player",120)
 var hero_info: VBoxContainer=UI.column(hero,5)
 UI.label(hero_info,"THE UNTESTED MAGE",22,UI.GOLD,true)
 UI.label(hero_info,"Your name will be spoken across the arena.",15,UI.MUTED,true)
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
''')

replace_func('show_hub',r'''
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
''')

replace_func('show_encounters',r'''
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
  var preview: HBoxContainer=UI.row(panel,10)
  UI.actor_portrait(preview,["hound","pyromancer","champion"][index],93)
  var summary: VBoxContainer=UI.column(preview,5)
  UI.label(summary,["INITIATE","ADEPT","MASTER"][index],17,UI.GOLD)
  UI.label(summary,["Room to learn and read the arena.","The intended challenge.","Relentless pressure and greater rewards."][index],14,UI.MUTED,true)
  UI.rule(panel)
  UI.label(panel,"%d waves    ◆    %d%% health    ◆    %d%% damage" % [encounter.waves,roundi(float(data.health)*100),roundi(float(data.damage)*100)],14,UI.MUTED,true)
  UI.label(panel,"◆ %d GOLD      ✦ %d XP" % [rewards.gold,rewards.xp],20,UI.GOLD)
  UI.spacer(panel,12)
  UI.button(panel,"Enter arena   →",func() -> void: start_combat(index),index==1)
 var instructions: VBoxContainer=UI.column(UI.panel(screen,Rect2(65,664,1150,98)),5)
 UI.label(instructions,"MOVE  Right-click    ◆    SPELLS  Q W E R    ◆    CAST  Left-click    ◆    DODGE  Space    ◆    PAUSE  Esc",15,UI.GOLD,true)
 UI.label(instructions,"Cast-time spells root you. Dodge cancels a cast without spending its cooldown. Defeat preserves your gold and build.",14,UI.MUTED,true)
''')

replace_func('show_reward',r'''
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
''')

replace_func('show_level_choices',r'''
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
''')

replace_func('show_completion',r'''
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
''')
p.write_text(text,encoding='utf8')
print('Menu functions replaced: 7')
