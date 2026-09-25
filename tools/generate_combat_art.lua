local root = app.params["root"]
if not root or root == "" then error("missing --script-param root=<project>") end

local function path(...)
  local parts = {...}
  local out = root
  for _, p in ipairs(parts) do out = app.fs.joinPath(out, p) end
  return out
end

local function C(hex, a)
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1,2), 16)
  local g = tonumber(hex:sub(3,4), 16)
  local b = tonumber(hex:sub(5,6), 16)
  return app.pixelColor.rgba(r, g, b, a or 255)
end

local OUTLINE = C("111722")
local SHADOW = C("232c39")
local WHITE = C("fff2d3")
local SKIN = C("e3b497")

local function px(img,x,y,c)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x,y,c) end
end

local function rect(img,x,y,w,h,c)
  for yy=y,y+h-1 do for xx=x,x+w-1 do px(img,xx,yy,c) end end
end

local function line(img,x0,y0,x1,y1,c,thick)
  thick = thick or 1
  local dx = math.abs(x1-x0); local sx = x0<x1 and 1 or -1
  local dy = -math.abs(y1-y0); local sy = y0<y1 and 1 or -1
  local err = dx+dy
  while true do
    rect(img,x0-math.floor(thick/2),y0-math.floor(thick/2),thick,thick,c)
    if x0==x1 and y0==y1 then break end
    local e2=2*err
    if e2>=dy then err=err+dy; x0=x0+sx end
    if e2<=dx then err=err+dx; y0=y0+sy end
  end
end

local function circle(img,cx,cy,r,c)
  for y=-r,r do for x=-r,r do if x*x+y*y <= r*r then px(img,cx+x,cy+y,c) end end end
end

local function ring(img,cx,cy,r,c)
  local r0=(r-1)*(r-1); local r1=(r+1)*(r+1)
  for y=-r-1,r+1 do for x=-r-1,r+1 do local d=x*x+y*y; if d>=r0 and d<=r1 then px(img,cx+x,cy+y,c) end end end
end

local function diamond(img,cx,cy,r,c)
  for y=-r,r do local span=r-math.abs(y); rect(img,cx-span,cy+y,span*2+1,1,c) end
end

local palettes = {
  player={main=C("74cce8"), dark=C("315a78"), light=C("c6f3ff"), accent=C("f0cb72")},
  pyromancer={main=C("e56842"), dark=C("71343a"), light=C("ffb260"), accent=C("ffd36e")},
  cryomancer={main=C("69bde8"), dark=C("34577f"), light=C("d6f5ff"), accent=C("9be9ff")},
  battlemage={main=C("7bc4aa"), dark=C("355f58"), light=C("c9f3dc"), accent=C("d2b66f")},
  champion={main=C("d8b95f"), dark=C("65513b"), light=C("fff0b1"), accent=C("f6dd7d")},
  golem={main=C("9d876d"), dark=C("4d4542"), light=C("d7bd8c"), accent=C("ffc75f")},
  hound={main=C("b66d50"), dark=C("542f36"), light=C("ec9a63"), accent=C("ffcf6b")},
  skitter={main=C("a681c4"), dark=C("463b67"), light=C("d9baf0"), accent=C("baf4ff")},
  spitter={main=C("75a87a"), dark=C("304c42"), light=C("b6d68a"), accent=C("d9ff82")},
  wisp={main=C("77ada4"), dark=C("344c59"), light=C("b6eee0"), accent=C("ecf8c9")}
}

local function mage(img, ox, oy, key, anim, f, p)
  local bob = ({0,-1,0,1})[f+1]
  local y = oy + bob
  local cast = anim==2 and f or 0
  local hurt = anim==3 and ((f%2==0) and -2 or 2) or 0
  local dead = anim==4 and f or 0
  local x = ox + hurt
  if dead >= 3 then
    rect(img,x+10,y+34,28,4,OUTLINE); rect(img,x+12,y+33,24,3,p.dark)
    rect(img,x+28,y+28,9,7,OUTLINE); rect(img,x+29,y+29,7,5,SKIN)
    return
  end
  local sink = dead*4
  y = y + sink
  -- shadowed cloak
  rect(img,x+15,y+20,19,21,OUTLINE); rect(img,x+17,y+21,15,18,p.dark)
  rect(img,x+13,y+29,23,12,OUTLINE); rect(img,x+15,y+29,19,10,p.main)
  rect(img,x+18,y+30,3,9,p.light); rect(img,x+29,y+30,3,9,p.dark)
  -- boots / movement
  local step = (anim==1 and f%2==0) and 2 or 0
  rect(img,x+16-step,y+39,8,4,OUTLINE); rect(img,x+26+step,y+39,8,4,OUTLINE)
  rect(img,x+17-step,y+39,6,2,SHADOW); rect(img,x+27+step,y+39,6,2,SHADOW)
  -- head
  rect(img,x+19,y+13,12,10,OUTLINE); rect(img,x+20,y+14,10,8,SKIN)
  px(img,x+22,y+17,SHADOW); px(img,x+28,y+17,SHADOW)
  -- hood/hat identity
  if key=="champion" then
    rect(img,x+17,y+11,16,4,p.accent); rect(img,x+19,y+7,3,5,p.accent); rect(img,x+24,y+5,3,7,p.accent); rect(img,x+29,y+7,3,5,p.accent)
  elseif key=="cryomancer" then
    diamond(img,x+25,y+8,6,p.light); diamond(img,x+25,y+8,3,p.main)
  elseif key=="pyromancer" then
    rect(img,x+17,y+11,16,4,p.main); line(img,x+18,y+11,x+25,y+4,p.main,3); line(img,x+25,y+4,x+33,y+11,p.light,2)
  elseif key=="battlemage" then
    rect(img,x+16,y+10,18,5,p.main); rect(img,x+20,y+6,10,5,p.dark); rect(img,x+23,y+3,4,4,p.accent)
  else
    rect(img,x+17,y+10,16,5,p.main); rect(img,x+21,y+6,8,5,p.main); rect(img,x+23,y+3,4,4,p.light)
  end
  -- arms/staff
  local arm_up = cast*2
  rect(img,x+11,y+24-arm_up,7,5,OUTLINE); rect(img,x+12,y+24-arm_up,5,3,p.main)
  rect(img,x+33,y+23-arm_up,6,5,OUTLINE); rect(img,x+34,y+24-arm_up,4,3,SKIN)
  local sx=x+39; local sy=y+11-arm_up
  line(img,sx,sy,sx,y+40,OUTLINE,3); line(img,sx,sy,sx,y+40,C("856f52"),1)
  circle(img,sx,sy,5,OUTLINE); circle(img,sx,sy,3,p.accent)
  if cast>0 then ring(img,sx,sy,6+cast,p.light) end
  if key=="champion" then rect(img,x+15,y+23,3,15,p.accent); rect(img,x+32,y+23,3,15,p.accent) end
end

local function golem(img, ox, oy, anim, f, p)
  local bob=({0,-1,0,1})[f+1]; local y=oy+bob; local x=ox
  if anim==4 then y=y+f*4 end
  local swing=0
  if anim==2 then swing=f*2 elseif anim==1 then swing=(f%2)*2 end
  rect(img,x+12,y+14,26,25,OUTLINE); rect(img,x+14,y+16,22,21,p.dark)
  rect(img,x+17,y+9,20,13,OUTLINE); rect(img,x+19,y+11,16,9,p.main)
  rect(img,x+5,y+19-swing,10,19,OUTLINE); rect(img,x+7,y+20-swing,6,16,p.main)
  rect(img,x+36,y+18+swing,9,20,OUTLINE); rect(img,x+38,y+20+swing,5,16,p.main)
  rect(img,x+14,y+37,10,6,OUTLINE); rect(img,x+28,y+37,10,6,OUTLINE)
  rect(img,x+21,y+14,3,2,p.accent); rect(img,x+30,y+14,3,2,p.accent)
  line(img,x+25,y+22,x+23,y+34,p.accent,2); line(img,x+25,y+27,x+31,y+24,p.accent,1)
end

local function hound(img,ox,oy,anim,f,p)
  local x=ox; local y=oy+({0,-1,0,1})[f+1]
  if anim==4 then y=y+f*5 end
  local run=(anim==1 and f%2==0) and 3 or 0
  rect(img,x+12,y+23,25,13,OUTLINE); rect(img,x+14,y+24,21,10,p.main)
  rect(img,x+31,y+18,12,12,OUTLINE); rect(img,x+33,y+20,8,8,p.light)
  line(img,x+34,y+18,x+37,y+12,p.dark,3); line(img,x+39,y+18,x+42,y+13,p.dark,3)
  px(img,x+40,y+22,p.accent); rect(img,x+42,y+25,4,3,OUTLINE)
  line(img,x+12,y+25,x+6,y+18,p.dark,3); line(img,x+7,y+18,x+4,y+15,p.accent,2)
  rect(img,x+15-run,y+34,5,8,OUTLINE); rect(img,x+28+run,y+34,5,8,OUTLINE)
  for i=0,3 do rect(img,x+17+i*5,y+20-(i%2),3,5,p.accent) end
  if anim==2 then line(img,x+40,y+25,x+47,y+20-f,p.accent,2) end
end

local function skitter(img,ox,oy,anim,f,p)
  local x=ox; local y=oy+({0,-1,0,1})[f+1]
  if anim==4 then y=y+f*4 end
  diamond(img,x+25,y+25,10,OUTLINE); diamond(img,x+25,y+24,7,p.main); diamond(img,x+25,y+22,4,p.light)
  local spread=(anim==1 and f%2==0) and 3 or 0
  for i=0,2 do
    local yy=y+19+i*6
    line(img,x+17,yy,x+5-spread,yy-4+i*2,p.dark,2); line(img,x+33,yy,x+45+spread,yy-4+i*2,p.dark,2)
    px(img,x+5-spread,yy-4+i*2,p.accent); px(img,x+45+spread,yy-4+i*2,p.accent)
  end
  if anim==2 then ring(img,x+25,y+24,11+f,p.accent) end
end

local function spitter(img,ox,oy,anim,f,p)
  local x=ox; local y=oy+({0,-1,0,1})[f+1]
  if anim==4 then y=y+f*4 end
  rect(img,x+10,y+22,29,17,OUTLINE); rect(img,x+12,y+23,25,14,p.main)
  rect(img,x+17,y+14,22,15,OUTLINE); rect(img,x+19,y+16,18,11,p.light)
  circle(img,x+22,y+18,2,WHITE); circle(img,x+34,y+18,2,WHITE); px(img,x+22,y+18,SHADOW); px(img,x+34,y+18,SHADOW)
  local mouth=3+((anim==2) and f*2 or 0); rect(img,x+28,y+23,mouth+5,4,OUTLINE); rect(img,x+30,y+24,mouth+2,2,p.accent)
  rect(img,x+12,y+37,8,5,OUTLINE); rect(img,x+31,y+37,8,5,OUTLINE)
  if anim==2 and f>1 then circle(img,x+43+f,y+25,2+f,p.accent) end
end

local function wisp(img,ox,oy,anim,f,p)
  local x=ox; local y=oy+({0,-2,0,2})[f+1]
  if anim==4 then y=y+f*5 end
  circle(img,x+25,y+18,11,OUTLINE); circle(img,x+25,y+18,8,p.main); circle(img,x+25,y+18,4,p.light)
  px(img,x+22,y+17,WHITE); px(img,x+28,y+17,WHITE)
  line(img,x+18,y+26,x+14,y+38,p.dark,3); line(img,x+25,y+27,x+25,y+42,p.main,3); line(img,x+32,y+26,x+37,y+37,p.dark,3)
  if anim==2 then for r=12,14+f*2,3 do ring(img,x+25,y+18,r,p.accent) end end
end

local actor_keys={"player","pyromancer","cryomancer","battlemage","champion","golem","hound","skitter","spitter","wisp"}
for _,key in ipairs(actor_keys) do
  local spr=Sprite(48*4,48*5,ColorMode.RGB)
  local img=spr.cels[1].image
  local p=palettes[key]
  for anim=0,4 do for f=0,3 do
    local ox=f*48; local oy=anim*48
    if key=="golem" then golem(img,ox,oy,anim,f,p)
    elseif key=="hound" then hound(img,ox,oy,anim,f,p)
    elseif key=="skitter" then skitter(img,ox,oy,anim,f,p)
    elseif key=="spitter" then spitter(img,ox,oy,anim,f,p)
    elseif key=="wisp" then wisp(img,ox,oy,anim,f,p)
    else mage(img,ox,oy,key,anim,f,p) end
  end end
  spr:saveAs(path("art","sources","actor_"..key..".aseprite"))
  spr:saveCopyAs(path("art","sprites","actors",key..".png"))
  spr:close()
end

local spell_palette={
  fire={main=C("f06d43"), light=C("ffd06a"), pale=C("fff2b0")},
  ice={main=C("63bfe8"), light=C("b9efff"), pale=C("effcff")},
  earth={main=C("ad8b5f"), light=C("e0be7a"), pale=C("fff0b0")},
  air={main=C("70d5b1"), light=C("baf3dc"), pale=C("effff6")},
  acid={main=C("7eba68"), light=C("c7ee76"), pale=C("f1ffaf")},
  arcane={main=C("a880d6"), light=C("d8b7ff"), pale=C("f4eaff")}
}

local spell_types={
  fireball="fire", combustion="fire", burning_ground="fire", flame_lash="fire",
  ice_spike="ice", frost_nova="ice", icicle_rain="ice", ice_barrier="ice",
  earth_pillar="earth", stone_fist="earth", stone_guard="earth", tremor="earth",
  gust="air", vortex="air", wind_blade="air", wind_dash="air",
  claw="earth", pounce="earth", slam="earth", spit="acid", hex="arcane"
}

local function draw_spell(img,ox,oy,id,f,p)
  local cx=ox+16; local cy=oy+16
  if id=="fireball" then
    circle(img,cx,cy,6+f%2,p.main); circle(img,cx+1,cy-1,3,p.light); px(img,cx+2,cy-2,p.pale)
    line(img,cx-6,cy,cx-12-f,cy+3-f%2,p.main,2); line(img,cx-5,cy-3,cx-10-f,cy-7,p.light,1)
  elseif id=="combustion" then
    local r=5+f*2; for a=0,7 do local dx=math.floor(math.cos(a*math.pi/4)*r); local dy=math.floor(math.sin(a*math.pi/4)*r); line(img,cx,cy,cx+dx,cy+dy,p.main,2) end; circle(img,cx,cy,4+f,p.light)
  elseif id=="burning_ground" then
    ring(img,cx,cy,8+f,p.main); for i=0,4 do local x=cx-9+i*5; line(img,x,cy+7,x+((i+f)%3)-1,cy-1-(f+i)%5,p.light,2) end
  elseif id=="flame_lash" then
    for i=0,12 do local x=ox+4+i*2; local y=cy+math.floor(math.sin((i+f)*0.65)*6); rect(img,x,y,2,2,(i%3==0) and p.light or p.main) end
  elseif id=="ice_spike" then
    diamond(img,cx+2,cy,8,p.main); line(img,ox+5,cy,cx+10,cy,p.light,2); line(img,cx+2,cy-8,cx+11,cy,p.pale,1)
  elseif id=="frost_nova" then
    local r=6+f*2; for a=0,7 do local dx=math.floor(math.cos(a*math.pi/4)*r); local dy=math.floor(math.sin(a*math.pi/4)*r); line(img,cx,cy,cx+dx,cy+dy,p.light,1); px(img,cx+dx,cy+dy,p.pale) end; circle(img,cx,cy,2,p.main)
  elseif id=="icicle_rain" then
    for i=0,3 do local x=ox+6+i*7; local y=oy+3+((i*5+f*4)%14); line(img,x,y,x-3,y+10,p.light,2); px(img,x-2,y+10,p.pale) end
  elseif id=="ice_barrier" then
    line(img,cx,oy+3,cx-11,cy-3,p.main,2); line(img,cx-11,cy-3,cx-7,cy+10,p.light,2); line(img,cx-7,cy+10,cx,oy+29,p.pale,2); line(img,cx,oy+29,cx+7,cy+10,p.light,2); line(img,cx+7,cy+10,cx+11,cy-3,p.main,2); line(img,cx+11,cy-3,cx,oy+3,p.pale,2); if f%2==1 then ring(img,cx,cy,13,p.light) end
  elseif id=="earth_pillar" then
    local top=oy+18-f*3; rect(img,cx-6,top,13,oy+29-top,p.main); rect(img,cx-4,top+2,4,oy+27-top,p.light); diamond(img,cx,top,7,p.pale); rect(img,ox+5,oy+27,22,3,p.main)
  elseif id=="stone_fist" then
    rect(img,cx-7,cy-2,14,11,p.main); for i=0,3 do rect(img,cx-8+i*5,cy-8-(i%2),5,7,p.light) end; line(img,cx-8,cy+7,cx-12-f,cy+11,p.main,3)
  elseif id=="stone_guard" then
    diamond(img,cx,cy,12,p.main); diamond(img,cx,cy,8,p.light); rect(img,cx-2,cy-8,4,16,p.main); rect(img,cx-7,cy-2,14,4,p.main); if f%2==0 then ring(img,cx,cy,14,p.pale) end
  elseif id=="tremor" then
    ring(img,cx,cy,5+f*2,p.main); line(img,cx-2,cy,cx-9-f,cy+7,p.light,2); line(img,cx+2,cy,cx+11+f,cy+5,p.light,2)
  elseif id=="gust" then
    for i=0,2 do local yy=oy+9+i*7; line(img,ox+5+f,yy,ox+24-f,yy,p.light,2); line(img,ox+20,yy,ox+26,yy-4,p.main,1) end
  elseif id=="vortex" then
    ring(img,cx,cy,4+f,p.main); ring(img,cx,cy,9+((f+1)%3),p.light); line(img,cx,cy,cx+10,cy-7-f,p.pale,2)
  elseif id=="wind_blade" then
    for i=0,10 do local y=oy+5+i*2; local x=cx+math.floor(math.sin((i+f)*0.35)*6); rect(img,x,y,2,2,p.light) end; line(img,cx-5,oy+7,cx+8,oy+25,p.main,2)
  elseif id=="wind_dash" then
    line(img,ox+4,cy,cx+10,cy,p.light,3); line(img,cx+10,cy,cx+3,cy-7,p.main,2); line(img,cx+10,cy,cx+3,cy+7,p.main,2); for i=0,2 do line(img,ox+4-i*2,cy-5+i*5,ox+11+f,cy-5+i*5,p.pale,1) end
  elseif id=="claw" then
    for i=0,2 do line(img,ox+8+i*5,oy+6,ox+4+i*5-f,oy+25,p.light,2) end
  elseif id=="pounce" then
    line(img,ox+5,cy+7,cx+9,cy-7,p.main,3); line(img,cx+9,cy-7,cx+2,cy-7,p.light,2); line(img,cx+9,cy-7,cx+9,cy,p.light,2)
  elseif id=="slam" then
    local r=5+f*2; ring(img,cx,cy+4,r,p.main); for i=0,5 do local a=i*math.pi/3; line(img,cx,cy+4,cx+math.floor(math.cos(a)*r),cy+4+math.floor(math.sin(a)*r),p.light,2) end
  elseif id=="spit" then
    circle(img,cx+f,cy,6,p.main); circle(img,cx+2+f,cy-2,3,p.light); circle(img,cx-5-f,cy+3,2,p.main); px(img,cx+4+f,cy-3,p.pale)
  elseif id=="hex" then
    diamond(img,cx,cy,9,p.main); ring(img,cx,cy,11+f%2,p.light); circle(img,cx-3,cy-2,2,p.pale); circle(img,cx+3,cy-2,2,p.pale); line(img,cx-4,cy+4,cx+4,cy+4,p.pale,1)
  end
end

local spell_ids={"fireball","combustion","burning_ground","flame_lash","ice_spike","frost_nova","icicle_rain","ice_barrier","earth_pillar","stone_fist","stone_guard","tremor","gust","vortex","wind_blade","wind_dash","claw","pounce","slam","spit","hex"}
for _,id in ipairs(spell_ids) do
  local spr=Sprite(32*4,32,ColorMode.RGB)
  local img=spr.cels[1].image
  local p=spell_palette[spell_types[id]]
  for f=0,3 do draw_spell(img,f*32,0,id,f,p) end
  spr:saveAs(path("art","sources","spell_"..id..".aseprite"))
  spr:saveCopyAs(path("art","sprites","spells",id..".png"))
  spr:close()
end

print("generated combat art: "..#actor_keys.." actors, "..#spell_ids.." spells")
