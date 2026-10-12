local root=app.params["root"]
if not root or root=="" then error("root script parameter required") end
local function path(...) local s=root for _,p in ipairs({...}) do s=app.fs.joinPath(s,p) end return s end
local function color(h,a) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255) end
local function dot(i,x,y,c) if x>=0 and y>=0 and x<i.width and y<i.height then i:drawPixel(math.floor(x),math.floor(y),c) end end
local function rect(i,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do dot(i,xx,yy,c) end end end
local function line(i,x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y)) for k=0,n do dot(i,x+math.floor((xx-x)*k/math.max(1,n)+.5),y+math.floor((yy-y)*k/math.max(1,n)+.5),c) end end
local function ring(i,x,y,r,c)
 for t=0,47 do local a=(t/48)*math.pi*2;dot(i,x+math.floor(math.cos(a)*r+.5),y+math.floor(math.sin(a)*r+.5),c) end
end
local groups={
 fire={color("f16a36"),color("ffd171"),color("fff2c2")},
 ice={color("3dabe3"),color("92e6ff"),color("effbff")},
 earth={color("88694b"),color("d5ad69"),color("fff0bd")},
 air={color("30ac92"),color("91e8cb"),color("e7fff6")},
 acid={color("509054"),color("b6df6f"),color("e9ffa8")},
 arcane={color("935ac8"),color("cc9bf2"),color("f8e0ff")}
}
local ids={
 {"fireball","fire"},{"combustion","fire"},{"burning_ground","fire"},{"flame_lash","fire"},
 {"ice_spike","ice"},{"frost_nova","ice"},{"icicle_rain","ice"},{"ice_barrier","ice"},
 {"earth_pillar","earth"},{"stone_fist","earth"},{"stone_guard","earth"},{"tremor","earth"},
 {"gust","air"},{"vortex","air"},{"wind_blade","air"},{"wind_dash","air"},
 {"claw","earth"},{"pounce","earth"},{"slam","earth"},{"spit","acid"},{"hex","arcane"}
}
local function glow_details(img,ox,oy,f,key,g)
 local x=ox+24;local y=oy+24
 local radial=key=="frost_nova" or key=="combustion" or key=="tremor" or key=="vortex" or key=="burning_ground" or key=="icicle_rain"
 local shield=key=="stone_guard" or key=="ice_barrier"
 if radial or shield then
  local r=14+(f%3)*2
  for a=0,11 do
   local q=a*math.pi/6 + f*.14
   local px=x+math.floor(math.cos(q)*r);local py=y+math.floor(math.sin(q)*r)
   if (a+f)%3==0 then rect(img,px-1,py-1,3,3,g[2]) else dot(img,px,py,g[1]) end
  end
  if f%2==0 then ring(img,x,y,20,g[1]) end
 else
  for a=0,8 do
   local xx=ox+8+(a*11+f*3)%34
   local yy=oy+7+(a*a*5+f*7)%31
   if a%3==0 then rect(img,xx,yy,2,2,g[2]) else dot(img,xx,yy,g[1]) end
  end
 end
 if key=="fireball" or key=="flame_lash" then
  for k=0,4 do line(img,ox+10+k*5,oy+29+((k+f)%3),ox+14+k*5,oy+18-k%4,g[(k%2)+1]) end
 elseif key=="ice_spike" then
  line(img,ox+8,oy+25,ox+36,oy+20,g[3]);line(img,ox+26,oy+12,ox+41,oy+21,g[2])
 elseif key=="earth_pillar" or key=="stone_fist" then
  rect(img,ox+11,oy+36,6,2,g[2]);rect(img,ox+35,oy+38,3,3,g[1])
 elseif key=="wind_blade" or key=="wind_dash" or key=="gust" then
  for k=0,2 do line(img,ox+7,oy+13+k*9,ox+21+f,oy+11+k*9,g[2]) end
 end
end
local count=0
for _,item in ipairs(ids) do
 local id=item[1];local g=groups[item[2]]
 local src=app.open(path("art","sources","spell_"..id..".aseprite"))
 if not src then error("missing spell source "..id) end
 local original=src.cels[1].image
 local out=Sprite(48*4,48,ColorMode.RGB)
 local dest=out.cels[1].image
 for f=0,3 do
  for y=0,31 do for x=0,31 do
   local px=original:getPixel(f*32+x,y)
   if app.pixelColor.rgbaA(px)>0 then dot(dest,f*48+x+8,y+8,px) end
  end end
  glow_details(dest,f*48,0,f,id,g)
 end
 out:saveAs(path("art","source","visual_refactor","spell_"..id..".aseprite"))
 out:saveCopyAs(path("art","sprites","spells",id..".png"))
 local icon=Sprite(48,48,ColorMode.RGB)
 local im=icon.cels[1].image
 local bg=color("101b2a");local edge=color("3d4a5c")
 rect(im,0,0,48,48,bg)
 rect(im,0,0,48,2,edge);rect(im,0,46,48,2,edge);rect(im,0,0,2,48,edge);rect(im,46,0,2,48,edge)
 rect(im,3,3,42,2,g[1]);rect(im,3,43,42,2,g[1])
 for y=0,31 do for x=0,31 do
  local pp=dest:getPixel(48+x+8,y+8)
  if app.pixelColor.rgbaA(pp)>0 then dot(im,x+8,y+8,pp) end
 end end
 for j=0,3 do dot(im,4+j*2,40-j,g[2]);dot(im,42-j*2,7+j,g[1]) end
 icon:saveAs(path("art","source","visual_refactor","icon_"..id..".aseprite"))
 icon:saveCopyAs(path("art","icons","spells",id..".png"))
 icon:close(); out:close();src:close(); count=count+1
end
-- Larger low-contrast, irregular stonework modules. Aseprite exports the atlas
-- while Godot composes a static floor image once instead of painting thousands of tiles.
local T=64
local floor=Sprite(T*8,T,ColorMode.RGB)
local im=floor.cels[1].image
local slate={"303d4a","344151","394654","354351","384756","333f4c","344550","394552"}
local mortar=color("1f2b39"); local light=color("51616d");local dark=color("293646")
for n=0,7 do
 local xx=n*T
 rect(im,xx,0,T,T,mortar)
 for row=0,3 do
  local y=row*16
  local shift=((row+n)%2)*22-18
  for column=-1,2 do
   local x=xx+column*43+shift
   local w=40+((n+row+column)%3)*2
   rect(im,x+1,y+1,w-2,13,color(slate[1+((n+row+column*2)%8)]))
   line(im,x+2,y+2,x+w-4,y+2,light)
   line(im,x+3,y+13,x+w-3,y+13,dark)
   if (n+row+column)%3==0 then
    line(im,x+16,y+8,x+24,y+8,dark)
    dot(im,x+25,y+9,light)
   elseif (n+row+column)%4==0 then
    dot(im,x+9,y+6,color("506254"))
    dot(im,x+11,y+6,color("506254"))
   end
  end
 end
 if n==4 or n==7 then
  for k=0,5 do
   local a=k*math.pi/3
   dot(im,xx+31+math.floor(math.cos(a)*12),31+math.floor(math.sin(a)*12),color("657978"))
  end
 end
end
floor:saveAs(path("art","source","visual_refactor","arena_floor.aseprite"))
floor:saveCopyAs(path("art","sprites","tiles","arena_floor.png"))
floor:close()
print("Refactor Aseprite export: "..count.." spells, "..count.." icons, 8 floor tiles (64px)")
