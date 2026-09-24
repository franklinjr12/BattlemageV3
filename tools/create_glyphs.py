from pathlib import Path
import re
p=Path(__file__).resolve().parents[1]
# Distinct silhouettes at a 16-pixel working grid; SVG stays code-native and crisp.
patterns={
'fireball':['......XX........','.....XXXX.......','....XXXXXX......','..XXYYYYXXX.....','.XXXYYYYYXXX....','XXXXXYYYYXXXX...','.XXXYYYXXXXX....','..XXXXXXX.......'],
'flame_lash':['...........X....','...........XX...','.......XX..XX...','....XXXXXXXXX...','..XXXXXYYXXX....','.XXXXYYYXXX.....','..XXXXXXX.......','....XXXX........'],
'burning_ground':['...X....X...X...','..XXX..XXX.XXX..','...XX..XXX..XX..','....XXXXXXXX....','..XXXXXXXXXXXX..','.XXXXXXXXXXXXXX.','..YYYYYYYYYYYY..','................'],
'combustion':['.......X........','..X....X....X...','...X..XXX..X....','....XXYYYXX.....','XXXXXXYYYXXXXXX.','....XXYYYXX.....','...X..XXX..X....','..X....X....X...'],
'ice_spike':['...........XX...','.........XXXX...','.......XXYYXX...','.....XXYYXX.....','...XXYYXX.......','.XXYYXX.........','..XXX...........','...X............'],
'frost_nova':['.......XX.......','..X....XX....X..','...XX..XX..XX...','.....XXXXXX.....','XXXXXXYYXXXXXXX.','.....XXXXXX.....','...XX..XX..XX...','..X....XX....X..'],
'ice_barrier':['.....XXXXXX.....','..XXXXXXXXXXXX..','..XX........XX..','..XX..YYYY..XX..','...XX.YYYY.XX...','...XX......XX...','....XXXXXXXX....','......XXXX......'],
'icicle_rain':['...XX..XX..XX...','...XY..XY..XY...','...XX..XX..XX...','....X...X...X...','................','..X...X...X.....','..Y...Y...Y.....','..X...X...X.....'],
'earth_pillar':['.....XXXXXX.....','.....XYYYYX.....','.....XXYYXX.....','.....XXYYXX.....','....XXXYYXXX....','...XXXXXXXXXX...','..XXXXXXXXXXXX..','.XXX........XXX.'],
'stone_fist':['.....XX.XX.XX...','....XXXXXXXXXX..','...XXXYYYYXXXX..','..XXXXYYYYXXXX..','...XXXXXXXXXXX..','....XXXXXXXXX...','.....XXXXXXX....','.....XXXXXXX....'],
 'tremor':['.......XX.......','....X.XXXX.X....','...XX..XX..XX...','..XX........XX..','.XX..XXXXXX..XX.','XX..XX....XX..XX','....X......X....','................'],
 'stone_guard':['....XXXXXXXX....','...XXXYYYYXXX...','...XX..YY..XX...','...XX..YY..XX...','...XXX.YY.XXX...','....XXXXXXXX....','.....XXXXXX.....','.......XX.......'],
 'wind_blade':['............XX..','..........XXX...','........XXXX....','......XXYYX.....','....XXYYXX......','..XXXXXX........','.XXXXX..........','XXX.............'],
 'gust':['...XXXXXXXXXX...','............XX..','.....XXXXXXXX...','................','.XXXXXXXXXXXXX..','.............XX.','......XXXXXXXX..','................'],
 'wind_dash':['........X.......','........XXX.....','..XXXXXXXYYYX...','....XXXXXYYYYXX.','..XXXXXXXYYYX...','........XXX.....','........X.......','................'],
 'vortex':['.....XXXXXX.....','...XXX....XXX...','..XX..XXXX..XX..','..XX.XX..XX.XX..','..XX.XX..XX.XX..','...XX..XXXX.XX..','....XXX....XX...','......XXXXXX....']}
colors={'Fire':'f59a63','Ice':'83d5f5','Earth':'d4ba7a','Air':'9de3c5'}
for id,rows in patterns.items():
 f=p/f'resources/spells/{id}.tres';s=f.read_text(encoding='utf-8')
 element=re.search('element = "(.*?)"',s).group(1)
 rects=''.join(f'<rect x="{x*2}" y="{y*3+4}" width="2" height="3" fill="#{colors[element] if c=="X" else "f7e9bd"}"/>' for y,row in enumerate(rows) for x,c in enumerate(row) if c!='.')
 (p/f'art/{id}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><rect width="32" height="32" rx="3" fill="#152231"/>{rects}</svg>',encoding='utf-8')
 s=re.sub(r'path="res://art/\w+.svg"',f'path="res://art/{id}.svg"',s)
 f.write_text(s,encoding='utf-8')
# Slot-specific equipment glyphs.
gear_patterns={'Staff':['...XXXX...','...XYYX...','...XXXX...','.....X....','....X.....','...X......','..X.......','.X........'], 'Robe':['...XXXX...','..XXXXXX..','.XXXYYXXX.','..XXYYXX..','..XXYYXX..','..XXYYXX..','.XXXYYXXX.','XXXXXXXXXX'], 'Boots':['..XX..XX..','..XX..XX..','..XX..XX..','..XX..XX..','..XXX.XXX.','.XXXX.XXXX','YYYYY.YYYY','..........'], 'Ring':['..XXXXXX..','.XX....XX.','XX..YY..XX','XX.YYYY.XX','XX..YY..XX','.XX....XX.','..XXXXXX..','..........']}
for f in (p/'resources/gear').glob('*.tres'):
 s=f.read_text(encoding='utf-8');slot=re.search('slot = "(.*?)"',s).group(1);element=re.search(r'PackedStringArray\("(.*?)"',s).group(1)
 rects=''.join(f'<rect x="{x*3+1}" y="{y*3+4}" width="3" height="3" fill="#{colors[element] if c=="X" else "f7e9bd"}"/>' for y,row in enumerate(gear_patterns[slot]) for x,c in enumerate(row) if c!='.')
 (p/f'art/{f.stem}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><rect width="32" height="32" rx="3" fill="#152231"/>{rects}</svg>',encoding='utf-8')
 f.write_text(re.sub(r'path="res://art/\w+.svg"',f'path="res://art/{f.stem}.svg"',s),encoding='utf-8')
