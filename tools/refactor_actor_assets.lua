local root=app.params["root"]; if not root then error("missing root") end
local function path(...) local p=root; for _,q in ipairs({...}) do p=app.fs.joinPath(p,q) end return p end
local function C(s,a) return app.pixelColor.rgba(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16),a or 255) end
local function px(img,x,y,c) if x>=0 and y>=0 and x<img.width and y<img.height then img:drawPixel(x,y,c) end end
local function rect(img,x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(img,xx,yy,c) end end end
local function line(img,x0,y0,x1,y1,c)
 local dx=math.abs(x1-x0);local sx=x0<x1 and 1 or -1;local dy=-math.abs(y1-y0);local sy=y0<y1 and 1 or -1;local er=dx+dy
 while true do px(img,x0,y0,c); if x0==x1 and y0==y1 then break end;local e=2*er;if e>=dy then er=er+dy;x0=x0+sx end;if e<=dx then er=er+dx;y0=y0+sy end end
end
local accent={
 player={C("ffe3a0"),C("6aafd5")},pyromancer={C("ffb75d"),C("ffd875")},
 cryomancer={C("d3faff"),C("7ab9f2")},battlemage={C("d9f3c9"),C("74d8ae")},
 champion={C("fff5ac"),C("f1c36c")},golem={C("ffe09d"),C("718d9e")},
 hound={C("ffb96b"),C("ea9065")},skitter={C("e8caff"),C("b493e5")},
 spitter={C("e9ff96"),C("8dcc70")},wisp={C("ffffff"),C("8cebc9")}
}
local keys={"player","pyromancer","cryomancer","battlemage","champion","golem","hound","skitter","spitter","wisp"}
for _,key in ipairs(keys) do
 local src=app.open(path("art","sources","actor_"..key..".aseprite"))
 if not src then error("missing actor source "..key) end
 local raw=src.cels[1].image
 local out=Sprite(64*4,64*5,ColorMode.RGB)
 local dest=out.cels[1].image
 local a=accent[key]
 for row=0,4 do for frame=0,3 do
  local x0=frame*64; local y0=row*64
  for py0=0,47 do for px0=0,47 do
   local color=raw:getPixel(frame*48+px0,row*48+py0)
   if app.pixelColor.rgbaA(color)>0 then px(dest,x0+px0+8,y0+py0+8,color) end
  end end
  local mage=(key=="player" or key=="pyromancer" or key=="cryomancer" or key=="battlemage" or key=="champion")
  if mage and row<4 then
   -- Collar, contrasting ornamental hem and shoulder-trim create readable identity.
   rect(dest,x0+25,y0+33,14,2,a[2]);rect(dest,x0+21,y0+43,3,8,a[1])
   rect(dest,x0+35,y0+43,3,8,a[1])
   rect(dest,x0+24,y0+47,12,2,a[2])
   px(dest,x0+29,y0+37,a[1]);px(dest,x0+32,y0+38,a[1])
   px(dest,x0+24,y0+25,a[1]);px(dest,x0+36,y0+25,a[1])
   if key=="champion" then
    line(dest,x0+21,y0+42,x0+18,y0+51,a[1])
    line(dest,x0+38,y0+42,x0+42,y0+51,a[1])
    rect(dest,x0+25,y0+14,12,2,a[1])
   elseif key=="cryomancer" then
    px(dest,x0+30,y0+13,a[1]);px(dest,x0+28,y0+17,a[2]);px(dest,x0+32,y0+17,a[2])
   elseif key=="pyromancer" then
    line(dest,x0+32,y0+13,x0+34,y0+9,a[1]);px(dest,x0+34,y0+8,a[2])
   end
  elseif not mage and row<4 then
   px(dest,x0+26,y0+29,a[1]);px(dest,x0+35,y0+29,a[1])
   px(dest,x0+30,y0+33,a[2])
  end
  if row==2 then
   local ix=x0+48;local iy=y0+28-frame*2
   if mage then
    for k=0,4 do
     local q=k*math.pi*2/5 + frame*.4
     px(dest,ix+math.floor(math.cos(q)*(5+frame)),iy+math.floor(math.sin(q)*(5+frame)),a[1])
    end
    rect(dest,ix-1,iy-1,3,3,a[2])
   else
    for k=0,3 do px(dest,x0+16+k*9,y0+17-(frame+k)%4,a[1]) end
   end
  end
  if row==1 then
   px(dest,x0+12-frame,y0+47,a[2]);px(dest,x0+44+frame,y0+49,a[1])
  end
 end end
 out:saveAs(path("art","source","visual_refactor","actor_"..key..".aseprite"))
 out:saveCopyAs(path("art","sprites","actors",key..".png"))
 out:close();src:close()
end
print("Aseprite upgraded "..#keys.." actor sheets to 64x64 source cells")
