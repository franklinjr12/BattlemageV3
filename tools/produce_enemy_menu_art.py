"""Battlemage enemy and menu art sources. Reproducible pixel designs; edit .aseprite outputs for further hand polish."""
from PIL import Image,ImageDraw
from pathlib import Path
import math,json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art'/'sprites'/'actors'
U=ROOT/'art'/'sprites'/'ui'
SRC=ROOT/'art'/'source'/'enemy_revamp'
for d in (OUT,U,SRC):d.mkdir(parents=True,exist_ok=True)
CLIPS=[('idle',6,5.0,True),('move',6,9.0,True),('cast',6,10.0,False),('hurt',3,12.0,False),('death',7,9.0,False)]
P={
'hound':['#211f31','#4b3541','#935b53','#cc8666','#f7ba78','#f2e4bf'],
'skitter':['#211a36','#47315e','#72519a','#ab7bc5','#ecd2fb','#91e9de'],
'spitter':['#142a28','#305544','#488664','#8fbc74','#d1e790','#e4f5c2'],
'wisp':['#193746','#29556a','#428a95','#79d1c7','#cdfcf0','#ffffff'],
'golem':['#1b2734','#3d4653','#64707b','#91959a','#c5ae84','#ffcf8d'],
'pyromancer':['#261d33','#54303c','#923b43','#d8654e','#ffad60','#ffe8ac'],
'cryomancer':['#1b2943','#294a70','#3875a4','#6bbcdf','#c0eeff','#ffffff'],
'battlemage':['#21283d','#3d4569','#516b88','#5ca99b','#b3dcc1','#ffdf9b'],
'champion':['#242033','#493850','#67576d','#b08b69','#f6ce85','#fff1bc']
}
def poly(d,pts,c,s=1):
 d.polygon([(round(x*s),round(y*s)) for x,y in pts],fill=c)
def box(d,x,y,w,h,c,s=1):
 d.rectangle((round(x*s),round(y*s),round((x+w)*s),round((y+h)*s)),fill=c)
def ell(d,rect,c,s=1):
 d.ellipse(tuple(round(v*s) for v in rect),fill=c)
def ln(d,points,c,w=2,s=1):
 d.line([(round(x*s),round(y*s)) for x,y in points],fill=c,width=max(1,round(w*s)),joint='curve')
def render(key,state,frame,size=64,fx=False):
 s=size/64
 im=Image.new('RGBA',(size,size));d=ImageDraw.Draw(im)
 c=P[key]
 phase=frame / max(1, {'idle':6,'move':6,'cast':6,'hurt':3,'death':7,'barrier':6,'phase':6}[state]-1)
 bob=math.sin(frame*math.pi*.7)*(1.3 if state=='idle' else 2.7 if state=='move' else 0)
 move=math.sin(frame*math.pi*2/6)*3 if state=='move' else 0
 lean= -3 if state=='cast' and frame>2 else (5 if state=='hurt' else 0)
 drop=phase*21 if state=='death' else 0
 alpha=round(255*(1.0-(max(0,phase-.55)*1.3 if state=='death' else 0)))
 layer=Image.new('RGBA',(size,size));d=ImageDraw.Draw(layer)
 # every creature has a different top down three-quarter silhouette.
 if key=='hound':
  yy=bob+drop
  # tail and rear silhouette
  poly(d,[(16,35+yy),(9,30+yy-move),(6,23+yy-move),(13,25+yy),(23,34+yy)],c[1],s)
  ln(d,[(10,24+yy),(13,22+yy),(15,26+yy)],c[4],2,s)
  # long legs, stronger forelegs
  for x,xoff in [(22,move),(31,-move),(42,move),(47,-move)]:
   ln(d,[(x,37+yy),(x+xoff,49+yy),(x+xoff-2,54+yy)],c[0],6,s)
   ln(d,[(x,37+yy),(x+xoff,49+yy)],c[2],3,s)
   box(d,x+xoff-4,52+yy,7,2,c[4],s)
  poly(d,[(16,30+yy),(23,24+yy),(39,24+yy),(47,30+yy),(43,40+yy),(22,40+yy)],c[0],s)
  poly(d,[(18,29+yy),(24,25+yy),(39,27+yy),(44,33+yy),(38,37+yy),(21,36+yy)],c[2],s)
  poly(d,[(21,28+yy),(27,26+yy),(37,27+yy),(34,30+yy)],c[3],s)
  # angular wolf head and ears
  poly(d,[(37,28+yy),(43,19+yy),(49,18+yy),(55,24+yy),(55,35+yy),(45,37+yy)],c[0],s)
  poly(d,[(40,19+yy),(41,11+yy),(48,18+yy),(51,10+yy),(54,23+yy)],c[0],s)
  poly(d,[(43,20+yy),(45,15+yy),(48,22+yy),(51,16+yy),(52,26+yy)],c[3],s)
  poly(d,[(42,26+yy),(49,21+yy),(54,26+yy),(52,31+yy)],c[2],s)
  poly(d,[(50,30+yy),(61,33+yy),(59,38+yy),(48,36+yy)],c[0],s)
  poly(d,[(52,31+yy),(60,33+yy),(57,35+yy),(51,34+yy)],c[3],s)
  box(d,52,26+yy,3,3,c[5],s);box(d,55,27+yy,1,1,c[0],s)
  box(d,59,34+yy,2,2,c[0],s)
  if state=='cast':
   dx= int(phase*7)
   poly(d,[(31+dx,35+yy),(41+dx,32+yy),(46+dx,41+yy),(40+dx,42+yy)],c[4],s)
 elif key=='skitter':
  yy=bob+drop
  # leg articulation, eight distinctly angular limbs
  for n in range(4):
   yp=21+n*7
   direction= -1 if n%2 else 1
   for side in [-1,1]:
    start=32+side*10; mid=32+side*(19+(frame+n)%3*2); end=32+side*(25+(frame+n)%3)
    ln(d,[(start,28+n*2+yy),(mid,yp+direction*3+move+yy),(end,yp+direction*7+move+yy)],c[0],4,s)
    ln(d,[(start,28+n*2+yy),(mid,yp+direction*3+move+yy)],c[3],2,s)
  poly(d,[(20,25+yy),(25,17+yy),(35,16+yy),(43,24+yy),(43,38+yy),(34,46+yy),(24,41+yy)],c[0],s)
  poly(d,[(25,22+yy),(34,19+yy),(40,26+yy),(38,37+yy),(31,40+yy),(23,33+yy)],c[2],s)
  poly(d,[(29,23+yy),(34,21+yy),(38,27+yy),(34,31+yy)],c[3],s)
  for x,y in [(27,27),(32,26),(37,27),(29,31),(35,31)]:
   box(d,x,y+yy,2,2,c[5],s)
  poly(d,[(25,40+yy),(31,50+yy),(37,42+yy)],c[1],s)
 elif key=='spitter':
  yy=bob+drop
  growth=round((math.sin(phase*math.pi)*5) if state=='cast' else 0)
  for x,v in [(17,move),(45,-move)]:
   poly(d,[(x-7,36+yy),(x+2,40+yy),(x+v+5,54+yy),(x+v-6,54+yy)],c[0],s)
   poly(d,[(x-3,40+yy),(x+1,42+yy),(x+v,50+yy)],c[3],s)
  ell(d,(12-growth,23-growth+yy,53+growth,49+yy),c[0],s)
  ell(d,(16-growth,25-growth+yy,50+growth,44+yy),c[2],s)
  ell(d,(18,30+yy,47,49+yy),c[3],s)
  ell(d,(23,35+yy,42,49+yy),c[4],s)
  # brows and telescoping eyes
  for x in [19,41]:
   ell(d,(x-4,20+yy,x+4,30+yy),c[0],s)
   box(d,x-1,22+yy,3,4,c[5],s)
   box(d,x+1,24+yy,2,2,c[0],s)
  mouth=4+growth*2
  ell(d,(31-mouth//2,27+yy,31+mouth//2,32+growth+yy),c[0],s)
  ln(d,[(25,34+yy),(32,36+yy),(39,34+yy)],c[1],2,s)
  for x in [22,43]: poly(d,[(x,39+yy),(x+5,43+yy),(x+2,45+yy)],c[4],s)
 elif key=='wisp':
  yy=bob+drop
  for j in range(6):
   a=(math.pi*2*j/6)+(phase*.35)
   x=32+math.cos(a)*(12+j%2*3);y=32+math.sin(a)*(12+j%3*3)
   ln(d,[(32,34+yy),(x,y+yy),(x+math.sin(frame+j)*5,y+8+yy)],c[1 if j%2 else 2],3,s)
  poly(d,[(29,14+yy),(36,17+yy),(46,27+yy),(43,39+yy),(34,47+yy),(23,40+yy),(18,28+yy)],c[0],s)
  ell(d,(22,19+yy,43,42+yy),c[2],s)
  ell(d,(25,22+yy,40,39+yy),c[3],s)
  ell(d,(29,25+yy,37,34+yy),c[5],s)
  for x,y in [(12,17),(50,21),(46,49),(14,42)]:
   box(d,x+(frame%3),y-(frame%4)+yy,2,2,c[4],s)
 elif key=='golem':
  yy=bob+drop
  # heavy stone legs with asymmetric foot slabs
  for x in [17,38]:
   poly(d,[(x,35+yy),(x+12,35+yy),(x+11+move,51+yy),(x-2+move,52+yy)],c[0],s)
   poly(d,[(x+1,36+yy),(x+10,36+yy),(x+9+move,48+yy),(x+move,48+yy)],c[2],s)
   box(d,x-5+move,50+yy,19,4,c[1],s)
  poly(d,[(15,17+yy),(41,13+yy),(51,22+yy),(48,40+yy),(23,43+yy),(12,33+yy)],c[0],s)
  poly(d,[(19,20+yy),(41,17+yy),(47,24+yy),(45,37+yy),(24,40+yy),(16,31+yy)],c[2],s)
  poly(d,[(21,20+yy),(39,17+yy),(43,22+yy),(26,24+yy)],c[3],s)
  for xx,offset in [(9,-2),(46,3)]:
   poly(d,[(xx,22+yy),(xx+12,22+yy),(xx+14+offset,45+yy),(xx-3+offset,45+yy)],c[0],s)
   poly(d,[(xx+1,24+yy),(xx+10,24+yy),(xx+10+offset,40+yy),(xx+offset,41+yy)],c[2],s)
   box(d,xx+offset-4,41+yy,20,8,c[1],s)
   box(d,xx+offset-1,42+yy,13,2,c[3],s)
  poly(d,[(23,9+yy),(40,9+yy),(44,19+yy),(38,27+yy),(23,26+yy),(19,19+yy)],c[0],s)
  poly(d,[(24,12+yy),(38,11+yy),(41,19+yy),(34,24+yy),(23,22+yy)],c[2],s)
  box(d,26,18+yy,4,2,c[5],s);box(d,35,18+yy,4,2,c[5],s)
  ln(d,[(30,28+yy),(34,34+yy),(28,38+yy)],c[4],2,s)
 else:
  yy=bob+drop
  # distinctive silhouette mage architecture with shoulders/robes, not a palette swap
  is_champ=key=='champion'
  is_pyro=key=='pyromancer'
  is_cryo=key=='cryomancer'
  is_multi=key=='battlemage'
  hood=key in ['pyromancer','cryomancer']
  # rear cape, different geometries
  cape=[(22,23+yy),(40,23+yy),(48+lean,52+yy),(35,56+yy),(13+lean,54+yy)]
  if is_pyro: cape=[(22,23+yy),(39,23+yy),(50+lean,52+yy),(38,48+yy),(34,59+yy),(28,53+yy),(15,57+yy)]
  if is_cryo: cape=[(21,23+yy),(41,23+yy),(44+lean,50+yy),(38,56+yy),(26,52+yy),(17+lean,57+yy),(15,47+yy)]
  if is_multi: cape=[(20,22+yy),(43,22+yy),(47,53+yy),(32,56+yy),(16,53+yy)]
  if is_champ: cape=[(17,19+yy),(45,19+yy),(51,56+yy),(40,60+yy),(31,54+yy),(21,59+yy),(12,55+yy)]
  poly(d,cape,c[0],s)
  poly(d,[(24,25+yy),(39,25+yy),(42,50+yy),(32,53+yy),(21,49+yy)],c[1],s)
  # boots visible beneath mantle
  for x,v in [(23,move),(36,-move)]:
   poly(d,[(x,46+yy),(x+6,46+yy),(x+7+v,54+yy),(x-3+v,56+yy)],c[0],s)
   box(d,x+v-3,53+yy,11,3,c[2],s)
  # unique front robe shape and seam
  poly(d,[(21,30+yy),(42,30+yy),(43+lean,50+yy),(20+lean,50+yy)],c[2],s)
  poly(d,[(28,32+yy),(34,32+yy),(35+lean,49+yy),(26+lean,49+yy)],c[1],s)
  ln(d,[(32,33+yy),(32+lean,47+yy)],c[4],2,s)
  # shoulders and gesture arm vary by cast 
  gesture=math.sin(phase*math.pi)*8 if state=='cast' else 0
  for x,sgn in [(17,-1),(43,1)]:
   arm_y=28+yy - (gesture if sgn==1 else gesture*.3)
   poly(d,[(x,24+yy),(x+sgn*4,27+yy),(x+sgn*6,40+yy-gesture*.45),(x,42+yy)],c[0],s)
   poly(d,[(x,27+yy),(x+sgn*2,29+yy),(x+sgn*4,38+yy-gesture*.45),(x+sgn,38+yy)],c[2],s)
   box(d,x+sgn*4,37+yy-gesture*.45,4,5,c[3],s)
  # collar and face
  poly(d,[(20,21+yy),(43,21+yy),(39,30+yy),(24,30+yy)],c[0],s)
  poly(d,[(23,23+yy),(40,23+yy),(36,28+yy),(27,28+yy)],c[4],s)
  ell(d,(24,12+yy,40,29+yy),c[0],s)
  ell(d,(26,14+yy,38,27+yy),('#bc927f' if is_pyro else '#b7a2a4' if is_cryo else '#ae9c8a' if is_multi else '#dcb789'),s)
  # unique mantle/helmet
  if is_pyro:
   poly(d,[(22,17+yy),(24,7+yy),(29,11+yy),(35,5+yy),(41,16+yy),(40,22+yy),(23,22+yy)],c[2],s)
   poly(d,[(26,13+yy),(30,8+yy),(31,15+yy),(35,10+yy),(38,18+yy)],c[4],s)
   poly(d,[(18,28+yy),(14,17+yy),(22,20+yy),(25,28+yy)],c[3],s)
  elif is_cryo:
   poly(d,[(19,21+yy),(26,9+yy),(32,6+yy),(39,10+yy),(44,20+yy),(38,23+yy),(25,23+yy)],c[2],s)
   poly(d,[(26,14+yy),(32,7+yy),(38,14+yy)],c[4],s)
   poly(d,[(20,28+yy),(14,17+yy),(26,21+yy)],c[3],s)
   poly(d,[(42,26+yy),(50,17+yy),(39,20+yy)],c[3],s)
  elif is_champ:
   poly(d,[(22,16+yy),(20,9+yy),(25,13+yy),(28,4+yy),(32,11+yy),(37,4+yy),(40,13+yy),(45,9+yy),(41,19+yy)],c[4],s)
   box(d,25,15+yy,15,3,c[3],s)
   box(d,31,13+yy,3,3,c[5],s)
   poly(d,[(17,27+yy),(9,23+yy),(16,18+yy),(23,23+yy)],c[4],s)
   poly(d,[(45,25+yy),(53,21+yy),(47,16+yy),(39,23+yy)],c[4],s)
  else:
   poly(d,[(22,17+yy),(23,11+yy),(31,8+yy),(40,14+yy),(40,21+yy)],c[1],s)
   box(d,26,12+yy,12,3,c[3],s)
   poly(d,[(17,28+yy),(21,22+yy),(25,27+yy),(20,33+yy)],c[4],s)
  box(d,27,20+yy,3,2,c[0],s);box(d,35,20+yy,3,2,c[0],s)
  box(d,30,24+yy,5,2,c[2],s)
  # focus held on right, not random magical body center
  staffx=48+lean
  stafftop=10-gesture*.5+yy
  ln(d,[(staffx+3,stafftop+7),(staffx,48+yy)],c[0],4,s)
  ln(d,[(staffx+3,stafftop+7),(staffx,48+yy)],c[4],2,s)
  corecol=c[5] if not is_multi else ['#ffad60','#a9eafc','#d5bd83','#84f0cd'][frame%4]
  poly(d,[(staffx+3,stafftop-6),(staffx+8,stafftop+2),(staffx+3,stafftop+10),(staffx-2,stafftop+2)],c[0],s)
  poly(d,[(staffx+3,stafftop-4),(staffx+6,stafftop+2),(staffx+3,stafftop+7),(staffx,stafftop+2)],corecol,s)
 # shared hand-authored looking highlighted contact/sparks overlay:
 if key=="champion" and state in ("barrier","phase"):
  radius=23+round(math.sin(phase*math.pi)*4)
  yy=bob+drop
  d.arc(tuple(round(v*s) for v in (32-radius,31-radius+yy,32+radius,31+radius+yy)), 10, 355, fill=c[4], width=max(1,round(2*s)))
  for j in range(8):
   a=math.pi*j/4+phase*.5
   x=32+math.cos(a)*radius
   y=31+math.sin(a)*radius+yy
   box(d,x,y,3 if state=="phase" else 2,2,c[5],s)
 if state=='cast':
  for i in range(min(6,frame+1)):
   ang=i*1.7+frame*.23
   x=50+math.cos(ang)*(4+frame*1.2)
   y=19+math.sin(ang)*(4+frame)
   box(d,x,y+bob+drop,2,2,c[5],s)
 if state=='hurt':
  box(d,round(7+frame*3),round(13+bob),3,2,c[5],s)
 if state=='death':
  for j in range(frame+1):
   x=(j*13+frame*7)%45+9
   y=25+j%4*4+drop/2
   box(d,x,y,2,2,c[4 if j%2 else 3],s)
 if alpha<255:layer.putalpha(layer.getchannel('A').point(lambda a:round(a*alpha/255)))
 return layer

def build_enemy(key):
 cell=96 if key in ('golem','champion') else 64
 clips=CLIPS + ([("barrier",6,9.0,True),("phase",6,9.0,False)] if key=="champion" else [])
 sheet=Image.new('RGBA',(cell*7,cell*len(clips)))
 metadata={'id':key,'cell':[cell,cell],'columns':7,'pivot':[cell//2,round(cell*.82)],'clips':{},'source':'art/source/enemy_revamp/'+key+'.aseprite'}
 for row,(name,count,fps,loop) in enumerate(clips):
  metadata['clips'][name]={'row':row,'frames':count,'fps':fps,'loop':loop}
  for frame in range(count):
   im=render(key,name,frame,cell)
   sheet.alpha_composite(im,(frame*cell,row*cell))
 sheet.save(OUT/f'{key}.png')
 (SRC/f'{key}.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
 return key,cell
for key in P:
 print('ENEMY',*build_enemy(key))
# Beveled 9-slice UI textures with subtle rune corner highlights and hard integer borders.
UISETS={'panel':(128,96),'modal':(128,96),'tooltip':(96,64),'portrait':(80,80),'tab':(96,34),'button_normal':(96,40),'button_hover':(96,40),'button_pressed':(96,40),'button_selected':(96,40),'button_disabled':(96,40),'button_focus':(96,40)}
for name,(w,h) in UISETS.items():
 im=Image.new('RGBA',(w,h),(0,0,0,0));d=ImageDraw.Draw(im)
 dark='#101c2b';stone='#25394b';outline='#637284'
 accent= '#f6d79a' if name.endswith(('hover','selected','focus')) else '#d5ae73' if name in ('modal','portrait') else '#8e8c7a'
 if 'disabled' in name:dark='#18232e';outline='#3b4b5b';accent='#5e6872'
 if 'pressed' in name:dark='#25364a';accent='#f4d99b'
 if name=='tooltip':dark='#121e30'
 d.rectangle((2,2,w-3,h-3),fill=dark,outline=outline,width=2)
 d.rectangle((5,5,w-6,h-6),outline='#2a4052',width=1)
 # no opaque bitmap text or full gradient, just crisp highlight corners
 for cx,cy,sgnx,sgny in [(3,3,1,1),(w-4,3,-1,1),(3,h-4,1,-1),(w-4,h-4,-1,-1)]:
  d.line((cx,cy,cx+sgnx*12,cy),fill=accent,width=2)
  d.line((cx,cy,cx,cy+sgny*11),fill=accent,width=2)
  d.point((cx+sgnx*6,cy+sgny*6),fill='#efe0b5')
 if name.startswith('button'):
  d.line((8,6,w-9,6),fill='#425b70' if name!='button_selected' else '#dec48a',width=1)
  d.line((8,h-7,w-9,h-7),fill='#0a1420',width=2)
 if name in ('modal','portrait','panel'):
  for x in range(18,w-18,19):d.point((x,9),fill='#485c68')
 im.save(U/f'{name}.png')
print('UI KIT',len(UISETS))
