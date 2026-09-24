from pathlib import Path
import json, struct, wave, math, random
ROOT=Path(__file__).resolve().parents[1]
for folder in ['scenes/spells','scenes/enemies','scenes/player','scripts/player','scripts/enemies','scripts/combat','scripts/ui','scripts/progression','scripts/gear','scripts/audio','scripts/effects','resources/spells','resources/gear','resources/enemies','resources/encounters','data','audio','effects','art','tests','docs','builds']:
 (ROOT/folder).mkdir(parents=True,exist_ok=True)
def write(p,s): (ROOT/p).write_text(s,encoding='utf-8')
def tres(kind,name,fields,scene=None,icon=None):
 typ={'spells':'SpellData','gear':'GearData','enemies':'EnemyData','encounters':'EncounterData'}[kind]
 script={'spells':'spell','gear':'gear','enemies':'enemy','encounters':'encounter'}[kind]
 s=f'[gd_resource type="Resource" script_class="{typ}" load_steps={2+bool(scene)+bool(icon)} format=3]\n[ext_resource type="Script" path="res://scripts/data/{script}_data.gd" id="1"]\n'
 if scene:s+=f'[ext_resource type="PackedScene" path="res://{scene}" id="2"]\n'
 if icon:s+=f'[ext_resource type="Texture2D" path="res://{icon}" id="3"]\n'
 s+='[resource]\nscript = ExtResource("1")\n'
 for k,v in fields.items():
  if k=='color': val='Color('+', '.join(str(int(v[i:i+2],16)/255) for i in (0,2,4))+', 1)'
  elif isinstance(v,list):val='PackedStringArray('+', '.join(json.dumps(x) for x in v)+')'
  else: val=json.dumps(v,ensure_ascii=False)
  s+=f'{k} = {val}\n'
 if scene:s+=('spell_scene' if kind=='spells' else 'scene')+' = ExtResource("2")\n'
 if icon:s+='icon = ExtResource("3")\n'
 write(f'resources/{kind}/{name}.tres',s)
# Hand-authored, code-native pixel glyphs, rasterized by Godot at nearest filtering.
colors={'Fire':'f59a63','Ice':'83d5f5','Earth':'d4ba7a','Air':'9de3c5'}
glyphs={'Fire':['...x....','...xx...','..xxx.x.','.xxxxxx.','.xxxxxx.','..xxxx..','...xx...'], 'Ice':['...xx...','.x.xx.x.','..xxxx..','xxxxxxxx','..xxxx..','.x.xx.x.','...xx...'], 'Earth':['...xx...','..xxxx..','.xxxxxx.','xxxxxxxx','xxxxxxxx','.xxxxxx.','..xxxx..'], 'Air':['..xxxxx.','.xx.....','...xxxx.','......xx','.xxxxxx.','xx......','.xxxxx..']}
for element,rows in glyphs.items():
 rects=''.join(f'<rect x="{x*3+4}" y="{y*3+5}" width="3" height="3" fill="#{colors[element]}"/>' for y,row in enumerate(rows) for x,c in enumerate(row) if c=='x')
 write(f'art/{element.lower()}.svg',f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><rect width="32" height="32" rx="3" fill="#152231"/>{rects}</svg>')
write('icon.svg','<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" rx="22" fill="#101a2a"/><path d="M64 15L109 98H19Z" fill="#d4ba7a"/><path d="M64 38L88 86H40Z" fill="#101a2a"/><path d="M64 50L72 68L64 82L56 68Z" fill="#83d5f5"/></svg>')
spells=[
 ('fireball','Fireball','Fire','projectile',dict(damage=30,cooldown=2.8,reach=360,radius=36,status='burn',tags=['explode']), 'A burning bolt that bursts on impact. Applies Burn.'),
 ('flame_lash','Flame Lash','Fire','cone',dict(damage=37,cooldown=4.8,reach=150,cone_angle=75,status='burn',knockback=35), 'Sweep nearby enemies with flame. Applies Burn.'),
 ('burning_ground','Burning Ground','Fire','ground',dict(damage=10,cooldown=10,cast_time=.65,reach=280,radius=76,duration=5,tick_interval=.8,status='burn'), 'Scorch an area for 5 seconds. Push enemies back into it.'),
 ('combustion','Combustion','Fire','ground',dict(damage=20,cooldown=8,cast_time=.35,reach=310,radius=88,tags=['consume_burn']), 'Consume Burn for 18 bonus damage per stack. Burning targets detonate.'),
 ('ice_spike','Ice Spike','Ice','projectile',dict(damage=24,cooldown=2.6,reach=380,projectile_speed=480,status='chill',tags=['pierce']), 'A piercing shard. Three Chill stacks Freeze a target.'),
 ('frost_nova','Frost Nova','Ice','self_area',dict(damage=22,cooldown=7,reach=0,radius=110,status='freeze',status_duration=1.6), 'Freeze enemies around you. Heavy Earth attacks can Shatter them.'),
 ('ice_barrier','Ice Barrier','Ice','self',dict(damage=0,cooldown=12,reach=0,duration=4,tags=['barrier']), 'Gain a 45-point barrier for 4 seconds. A moment to recover.'),
 ('icicle_rain','Icicle Rain','Ice','ground',dict(damage=23,cooldown=9,cast_time=.75,delay=.6,reach=320,radius=85,duration=2.5,tick_interval=.75,status='chill',tags=['controlled_bonus']), 'Delayed hail. Deals 35% more damage to controlled enemies.'),
 ('earth_pillar','Earth Pillar','Earth','ground',dict(damage=62,cooldown=6,cast_time=.6,delay=.25,reach=260,radius=55,status='stagger',knockback=75,tags=['heavy']), 'A heavy eruption. Shatters frozen enemies for 60% bonus damage.'),
 ('stone_fist','Stone Fist','Earth','cone',dict(damage=48,cooldown=4.5,cast_time=.25,reach=130,cone_angle=65,status='stagger',knockback=100,tags=['heavy']), 'A crushing close-range blow. Builds Stagger and breaks Freeze.'),
 ('tremor','Tremor','Earth','self_area',dict(damage=35,cooldown=8,cast_time=.5,reach=0,radius=145,status='stagger',knockback=45,tags=['heavy']), 'Send a heavy shockwave through the ground around you.'),
 ('stone_guard','Stone Guard','Earth','self',dict(damage=0,cooldown=13,reach=0,duration=5,tags=['guard']), 'Reduce incoming damage by 55% for 5 seconds. Resist pressure.'),
 ('wind_blade','Wind Blade','Air','directional',dict(damage=21,cooldown=1.8,reach=320,radius=19), 'A fast blade of air that cuts through every target in its path.'),
 ('gust','Gust','Air','cone',dict(damage=18,cooldown=4,reach=190,cone_angle=80,knockback=150,status='airborne',status_duration=.4), 'Launch and push enemies. Drive them into persistent damage zones.'),
 ('wind_dash','Wind Dash','Air','directional',dict(damage=25,cooldown=6,reach=150,radius=30,tags=['dash']), 'Surge toward the target, damaging enemies along your route.'),
 ('vortex','Vortex','Air','ground',dict(damage=7,cooldown=10,cast_time=.3,reach=300,radius=100,duration=3.5,tick_interval=.5,tags=['pull']), 'Draw enemies together for 3.5 seconds. Follow with an area spell.')]
for i,(id,name,element,target,fields,desc) in enumerate(spells):
 f=dict(id=id,display_name=name,element=element,targeting=target,description=desc,price=[60,70,90,100][i%4]);f.update(fields)
 scene='scenes/spells/projectile.tscn' if target=='projectile' else 'scenes/spells/area.tscn'
 tres('spells',id,f,scene,f'art/{element.lower()}.svg')
gear=[
 ('cinder_staff','Cinder Staff','Staff',85,{'fire_damage':.23,'burn_duration':.35},'Fire damage +23%; Burn duration +35%.','Fire'),
 ('winter_staff','Winter Branch','Staff',85,{'ice_damage':.2,'chill_strength':.2},'Ice damage +20%; Chill slow +20%.','Ice'),
 ('fault_staff','Faultline Staff','Staff',85,{'earth_damage':.2,'stagger_power':1},'Earth damage +20%; +1 Stagger buildup.','Earth'),
 ('zephyr_staff','Zephyr Rod','Staff',85,{'air_damage':.2,'cast_speed':.15},'Air damage +20%; cast times -15%.','Air'),
 ('prism_staff','Prism Staff','Staff',110,{'power':.15},'All spell damage +15%.','Air'),
 ('ember_robe','Ember Mantle','Robe',70,{'max_hp':20,'burn_duration':.25},'+20 health; Burn duration +25%.','Fire'),
 ('glacier_robe','Glacier Robe','Robe',80,{'max_hp':30,'barrier':.4},'+30 health; barriers +40%.','Ice'),
 ('granite_robe','Granite Vestment','Robe',90,{'max_hp':45,'armor':.08},'+45 health; damage taken -8%.','Earth'),
 ('silk_robe','Cloudsilk Robe','Robe',85,{'speed':.1,'cast_speed':.2},'Movement +10%; cast times -20%.','Air'),
 ('scholar_robe','Scholar Robe','Robe',80,{'max_hp':15,'cooldown':.07},'+15 health; spell cooldowns -7%.','Ice'),
 ('cinder_boots','Ashwalkers','Boots',65,{'speed':.08,'fire_damage':.1},'Movement +8%; Fire damage +10%.','Fire'),
 ('frost_boots','Rime Treads','Boots',65,{'speed':.08,'chill_strength':.15},'Movement +8%; stronger Chill.','Ice'),
 ('stone_boots','Anchor Boots','Boots',65,{'max_hp':20,'stagger_power':1},'+20 health; +1 Stagger buildup.','Earth'),
 ('wind_boots','Windrunners','Boots',85,{'speed':.15,'dodge_recharge':.2},'Movement +15%; dodge recharge -20%.','Air'),
 ('pilgrim_boots','Pilgrim Boots','Boots',70,{'speed':.07,'dodge_recharge':.12},'Movement +7%; dodge recharge -12%.','Air'),
 ('coal_ring','Coalheart','Ring',75,{'burn_duration':.5,'fire_damage':.08},'Burn duration +50%; Fire damage +8%.','Fire'),
 ('rime_ring','Rime Circle','Ring',75,{'status_duration':.25,'ice_damage':.08},'Status duration +25%; Ice damage +8%.','Ice'),
 ('quake_ring','Quake Seal','Ring',80,{'area':.2,'earth_damage':.08},'Spell area +20%; Earth damage +8%.','Earth'),
 ('tempo_ring','Tempo Loop','Ring',100,{'cooldown':.12},'All spell cooldowns -12%.','Air'),
 ('horizon_ring','Horizon Band','Ring',85,{'area':.18,'power':.05},'Spell area +18%; all damage +5%.','Air')]
for id,name,slot,price,mods,desc,element in gear:
 tres('gear',id,dict(id=id,display_name=name,slot=slot,price=price,modifiers=mods,description=desc,tags=[element]),icon=f'art/{element.lower()}.svg')
# Creature attacks are resources in the same pipeline, excluded from shops.
for id,name,target,fields in [
 ('claw','Claw','cone',dict(damage=14,cooldown=2.2,cast_time=.65,reach=64,cone_angle=90)),
 ('spit','Venom Spit','projectile',dict(damage=13,cooldown=3.4,cast_time=.7,reach=370,projectile_speed=210)),
 ('pounce','Pounce','directional',dict(damage=13,cooldown=3,cast_time=.6,reach=110,radius=23,tags=['dash'])),
 ('slam','Boulder Slam','self_area',dict(damage=29,cooldown=4,cast_time=1.15,reach=0,radius=100,status='stagger',knockback=65,tags=['heavy'])),
 ('hex','Withering Bloom','ground',dict(damage=12,cooldown=5,cast_time=.85,delay=.65,reach=440,radius=70,duration=3,tick_interval=1,status='chill'))]:
 f=dict(id=id,display_name=name,description='Creature attack.',element='Earth',targeting=target,price=0,tags=['enemy_only']); f.update(fields);f['tags']=list(set(f.get('tags',[])+['enemy_only']))
 tres('spells',id,f,'scenes/spells/projectile.tscn' if target=='projectile' else 'scenes/spells/area.tscn','art/earth.svg')
opponents=[
 ('hound','Ash Hound',95,85,'melee',['claw'],54,'hound','bf856e',15,20),
 ('spitter','Mire Spitter',75,62,'ranged',['spit'],245,'spitter','86b48b',20,23),
 ('skitter','Glass Skitter',62,135,'fast',['pounce','claw'],90,'skitter','c49ed8',18,22),
 ('golem','Basalt Golem',235,43,'tank',['slam'],83,'golem','bba98c',32,38),
 ('wisp','Hollow Oracle',90,56,'support',['hex'],250,'wisp','a4c5b9',25,28),
 ('pyromancer','Vesta · Cinder Adept',390,82,'mage',['fireball','flame_lash','burning_ground','combustion'],235,'mage','f59a63',60,85),
 ('cryomancer','Iris · Winter Adept',410,76,'mage',['ice_spike','frost_nova','icicle_rain','ice_barrier'],265,'mage','83d5f5',60,85),
 ('battlemage','Orin · Fourfold Duelist',535,95,'mage',['vortex','earth_pillar','wind_blade','stone_guard'],185,'mage','9de3c5',80,110),
 ('champion','AUREL · THE UNBROKEN',950,100,'mage',['vortex','icicle_rain','earth_pillar','fireball'],210,'champion','e8cb82',120,150)]
for id,name,hp,speed,profile,attacks,reach,visual,color,gold,xp in opponents:
 tres('enemies',id,dict(id=id,display_name=name,max_health=hp*(3.5 if id=='champion' else 3 if profile=='mage' else 2),speed={'hound':110,'spitter':82,'skitter':205,'golem':55,'wisp':80,'pyromancer':108,'cryomancer':100,'battlemage':115,'champion':125}[id],profile=profile,attacks=attacks,preferred_range=reach,visual=visual,color=color,gold=gold,xp=xp,stagger_resistance=5 if profile=='tank' or id=='champion' else 3,power=-.3 if profile=='mage' else 0,aggression=1.2 if id=='champion' else 1,dodge_interval=6 if id=='champion' else 9), 'scenes/enemies/enemy.tscn')
encounters=[
 ('01','Trial of Embers','creatures',['hound','hound','spitter'],['skitter'],1.,False,'Survive the creatures. Keep moving and read their wind-ups.'),
 ('02','The First Duel','mage',['pyromancer'],['cryomancer'],1.,False,'A rival mage enters. Bait their casts, then punish the recovery.'),
 ('03','The Menagerie','creatures',['golem','wisp','skitter','hound','spitter'],['skitter','spitter'],1.05,False,'Prioritize the Oracle. Control the pack before it surrounds you.'),
 ('04','Fourfold Trial','mage',['battlemage'],[],1.12,False,'Orin combines schools. Escape the Vortex before the heavy blow.'),
 ('05','The Crown of Ash','boss',['champion'],[],1.,True,'Aurel gains speed and a second wind below half health. Claim the Local Arena.')]
for i,(id,name,kind,ids,variants,scale,boss,desc) in enumerate(encounters):
 tres('encounters',id,dict(id=id,display_name=name,description=desc,kind=kind,enemies=ids,variants=variants,base_difficulty=scale,boss=boss,formation='ring' if kind=='creatures' else 'duel',progression_required=i,waves=2 if i==0 else 3 if i==2 else 1))
write('data/economy.json',json.dumps({'starting_gold':85,'xp_thresholds':[0,120,270,720,975],'encounter_gold':[55,75,85,95,125],'encounter_xp':[30,40,45,55,65],'difficulty':[{'name':'Easy','health':.8,'damage':.75,'reward':.85,'aggression':.85},{'name':'Normal','health':1.,'damage':1.,'reward':1.,'aggression':1.},{'name':'Hard','health':1.15,'damage':1.22,'reward':1.35,'aggression':1.15}],'spell_offers':3,'gear_offers':3,'dodge_charges':2,'dodge_recharge':4.,'player_hp':150,'player_speed':160},indent=2))
write('data/packages.json',json.dumps({'Emberweaver':{'description':'Burn, detonate, and escape. Aggressive spell combinations.','spells':['fireball','combustion','frost_nova','wind_dash']},'Winter Warden':{'description':'Freeze, shatter, and endure. Deliberate control and heavy impacts.','spells':['ice_spike','frost_nova','earth_pillar','stone_guard']},'Stormcaller':{'description':'Group, scorch, and displace. Fast attacks and battlefield control.','spells':['wind_blade','vortex','burning_ground','gust']}},indent=2))
for name,script in [('spells/projectile','combat/projectile'),('spells/area','combat/spell_effect'),('enemies/enemy','enemies/enemy'),('player/player','player/player')]:
 write(f'scenes/{name}.tscn',f'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/{script}.gd" id="1"]\n[node name="{name.split("/")[-1].capitalize()}" type="Node2D"]\nscript = ExtResource("1")\n')
# Original synthesized cues, no third-party assets.
random.seed(64)
for name,freq,dur,noise in [('fire',190,.24,.65),('ice',760,.24,.2),('earth',95,.32,.6),('air',420,.18,.45),('hit',155,.12,.65),('dodge',640,.16,.2),('ui',560,.07,0),('death',90,.5,.3),('victory',520,1.1,0),('defeat',150,.85,.1),('boss',110,1.2,.3)]:
 samples=[]
 for n in range(int(22050*dur)):
  t=n/22050; env=(1-t/dur)**2*min(1,t/.008)
  pitch=freq*(1-.5*t/dur) if name not in ['victory','ui'] else freq*(1+int(t*4)/4)
  v=(math.sin(2*math.pi*pitch*t)*(1-noise)+random.uniform(-1,1)*noise)*env*.3
  samples.append(int(v*32767))
 with wave.open(str(ROOT/f'audio/{name}.wav'),'wb') as w:w.setparams((1,2,22050,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
# Quiet eight-second ambient chord, a clean looping bed.
samples=[]
for n in range(22050*8):
 t=n/22050;env=min(1,t/1.2,(8-t)/1.2)
 samples.append(int(sum(math.sin(2*math.pi*f*t) for f in [110,164.875,220,261.625])*700*env))
with wave.open(str(ROOT/'audio/ambience.wav'),'wb') as w:w.setparams((1,2,22050,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print('Generated resources, icons, audio and scenes.')

write('data/content_index.json',json.dumps({kind:sorted(f.name for f in (ROOT/'resources'/kind).glob('*.tres')) for kind in ['spells','gear','enemies','encounters']},indent=2))
