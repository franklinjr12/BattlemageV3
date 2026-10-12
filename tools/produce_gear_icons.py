"""Original 48px pixel equipment icon illustrations for all existing gear IDs."""
from PIL import Image,ImageDraw
from pathlib import Path
import math
root=Path(__file__).resolve().parents[1]
out=root/'art/icons/gear';out.mkdir(parents=True,exist_ok=True)
gear=list((root/'resources/gear').glob('*.tres'))
base={'fire':('#592933','#c95940','#f5ab63'),'cinder':('#592933','#c95940','#f5ab63'),
'ember':('#592933','#c95940','#f5ab63'),'frost':('#284665','#539acb','#c1edfc'),
'winter':('#284665','#539acb','#c1edfc'),'glacier':('#284665','#539acb','#c1edfc'),
'rime':('#284665','#539acb','#c1edfc'),'stone':('#494650','#80715f','#e5d098'),
'granite':('#494650','#80715f','#e5d098'),'quake':('#494650','#80715f','#e5d098'),
'wind':('#205c62','#54ab9d','#c2efcd'),'zephyr':('#205c62','#54ab9d','#c2efcd'),
'horizon':('#205c62','#54ab9d','#c2efcd'),'tempo':('#483c65','#917ab8','#f9dcaa'),
'coal':('#3b3c4d','#989089','#ffd8a2'),'silk':('#334960','#81a0bf','#e0debf'),
'prism':('#4d3b67','#ba95db','#f8f7c0'),'fault':('#445250','#90a28b','#e4d49b'),
'pilgrim':('#524539','#9d8867','#f0dbbb'),'scholar':('#39475b','#829bb1','#dfc89a')}
def shape(d,xy,color):d.polygon(xy,fill=color)
for f in gear:
 id=f.stem
 dark,mid,light=next((v for k,v in base.items() if k in id),('#393b4d','#81919c','#ecd39c'))
 im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
 if 'staff' in id:
  d.line((12,42,32,14),fill='#121827',width=7);d.line((12,42,32,14),fill=mid,width=4)
  d.line((14,39,30,17),fill=light,width=1)
  shape(d,[(30,6),(38,14),(32,25),(25,17)],'#192330')
  shape(d,[(30,9),(35,14),(31,21),(27,17)],mid)
  shape(d,[(30,11),(33,14),(31,17),(29,15)],light)
  for x,y in [(14,11),(40,11),(39,28),(9,30)]:d.point((x,y),fill=light)
 elif 'robe' in id:
  shape(d,[(14,9),(23,6),(33,9),(41,18),(38,42),(10,42),(7,18)],'#182431')
  shape(d,[(15,12),(23,10),(32,12),(38,19),(35,39),(13,39),(10,20)],dark)
  shape(d,[(18,13),(22,19),(26,19),(30,13),(35,17),(31,25),(32,38),(17,38),(19,25),(13,17)],mid)
  shape(d,[(22,20),(27,20),(31,36),(18,36)],dark)
  d.line((24,20,24,37),fill=light,width=2)
  d.line((14,19,9,24),fill=light,width=2)
  d.line((35,19,40,24),fill=light,width=2)
  d.rectangle((22,23,26,26),fill=light)
 elif 'boots' in id:
  for off in (1,23):
   shape(d,[(off+3,10),(off+16,10),(off+17,29),(off+20,34),(off+20,40),(off,40),(off,35),(off+3,29)],'#162332')
   shape(d,[(off+5,12),(off+14,12),(off+14,30),(off+18,35),(off+17,37),(off+2,37),(off+4,31)],mid)
   d.line((off+5,14,off+15,14),fill=light,width=2)
   d.line((off+5,23,off+14,23),fill=dark,width=2)
 elif 'ring' in id:
  d.ellipse((10,14,38,42),fill='#141e2c')
  d.ellipse((14,18,34,38),fill=light)
  d.ellipse((18,22,30,35),fill='#141e2c')
  shape(d,[(23,6),(32,13),(24,24),(15,14)],dark)
  shape(d,[(23,9),(29,14),(24,21),(19,14)],mid)
  shape(d,[(23,11),(26,14),(23,17),(21,14)],light)
  for x,y in [(12,18),(35,20),(15,36)]:d.point((x,y),fill=light)
 im.save(out/f'{id}.png')
 print(id)
