"""Pixel-perfect enemy proof sheets and short multi-clip animation previews."""
from pathlib import Path
from PIL import Image, ImageDraw
import json,subprocess,io
root=Path(__file__).resolve().parents[1]
out=root/'docs/revamp_validation/enemies'
out.mkdir(parents=True,exist_ok=True)
names=['hound','skitter','spitter','wisp','golem','pyromancer','cryomancer','battlemage','champion']
sheet=Image.new('RGBA',(860,len(names)*132),'#0a111c')
labels=ImageDraw.Draw(sheet)
for row,key in enumerate(names):
 atlas=Image.open(root/'art/sprites/actors'/f'{key}.png').convert('RGBA')
 metadata=json.loads((root/'art/source/enemy_revamp'/f'{key}.json').read_text(encoding='utf8'))
 w,h=metadata['cell']
 old=subprocess.run(['git','show',f'HEAD:art/sprites/actors/{key}.png'],cwd=root,capture_output=True)
 if old.returncode==0 and old.stdout:
  original=Image.open(io.BytesIO(old.stdout)).convert('RGBA').crop((0,0,64,64))
 else:
  original=Image.new('RGBA',(64,64))
 frames=[]
 for state_index,state in enumerate(['idle','move','cast','hurt','death']):
  spec=metadata['clips'][state]
  new=atlas.crop((min(2,spec['frames']-1)*w,spec['row']*h,(min(2,spec['frames']-1)+1)*w,(spec['row']+1)*h))
  canvas=Image.new('RGBA',(100,100),'#122333')
  new.thumbnail((95,95))
  canvas.alpha_composite(new,((100-new.width)//2,(100-new.height)//2))
  frames.append(canvas)
 y=row*132+12
 labels.text((8,y+34),key.upper(),fill='#d9bc80')
 small=Image.new('RGBA',(100,100),'#172536');small.alpha_composite(original,((100-original.width)//2,(100-original.height)//2))
 sheet.alpha_composite(small,(145,y))
 for col,tile in enumerate(frames):sheet.alpha_composite(tile,(260+col*118,y))
 if row==0:
  for c,txt in enumerate(['BEFORE','IDLE','MOVE','CAST','HURT','DEATH']):
   labels.text((151 if c==0 else 265+(c-1)*118,2),txt,fill='#a2b1bf')
 # six-frame animated collage, each column corresponds to clip type
 clip_frames=[]
 count=max(v['frames'] for v in metadata['clips'].values())
 for index in range(count):
  canvas=Image.new('RGBA',(580,134),'#101c2b')
  d=ImageDraw.Draw(canvas)
  for col,state in enumerate(['idle','move','cast','hurt','death']):
   spec=metadata['clips'][state];fid=index%spec['frames']
   crop=atlas.crop((fid*w,spec['row']*h,(fid+1)*w,(spec['row']+1)*h))
   crop.thumbnail((96,96))
   x=col*115+(115-crop.width)//2;y2=(110-crop.height)//2
   canvas.alpha_composite(crop,(x,y2))
   d.text((col*115+12,115),state,fill='#d9bc80')
  clip_frames.append(canvas.resize((1160,268),Image.Resampling.NEAREST).convert('RGB'))
 clip_frames[0].save(out/f'{key}.gif',save_all=True,append_images=clip_frames[1:],duration=125,loop=0,optimize=True)
sheet.convert('RGB').save(out/'before_after_contact_sheet.png')
sheet.resize((1720,len(names)*264),Image.Resampling.NEAREST).convert('RGB').save(out/'before_after_contact_sheet_2x.png')
print(f'Validated previews for {len(names)} enemies; {len(names)} animations, 1x and 2x contact sheets.')
