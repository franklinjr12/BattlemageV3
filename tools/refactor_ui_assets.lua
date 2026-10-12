local root=app.params["root"]; if not root then error("root missing") end
local function path(...) local p=root;for _,q in ipairs({...}) do p=app.fs.joinPath(p,q) end return p end
local function C(h,a) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255) end
local function p(i,x,y,c)if x>=0 and y>=0 and x<i.width and y<i.height then i:drawPixel(x,y,c)end end
local function rect(i,x,y,w,h,c)for yy=y,y+h-1 do for xx=x,x+w-1 do p(i,xx,yy,c)end end end
local function line(i,x,y,xx,yy,c)local n=math.max(math.abs(xx-x),math.abs(yy-y));for j=0,n do p(i,math.floor(x+(xx-x)*j/math.max(1,n)+.5),math.floor(y+(yy-y)*j/math.max(1,n)+.5),c)end end
local names={
 normal={"182738","3c5366","a88e5d"},hover={"263d50","9db6c5","ecd39b"},
 pressed={"334455","dec893","f8e9bf"},disabled={"16212c","354454","66778b"},
 focus={"182738","ffe8aa","fff6d0"},selected={"3d3645","e0be77","fff5c9"}
}
for id,c in pairs(names) do
 local s=Sprite(96,40,ColorMode.RGB);local i=s.cels[1].image
 local bg=C(c[1]);local edge=C(c[2]);local gold=C(c[3])
 rect(i,0,0,96,40,bg)
 rect(i,0,0,96,2,edge);rect(i,0,38,96,2,edge);rect(i,0,0,2,40,edge);rect(i,94,0,2,40,edge)
 rect(i,3,3,90,1,C("4b5966"));rect(i,3,36,90,1,C("101926"))
 for x=2,9 do p(i,x,2,gold);p(i,95-x,2,gold);p(i,x,37,gold);p(i,95-x,37,gold)end
 for y=2,9 do p(i,2,y,gold);p(i,93,y,gold);p(i,2,39-y,gold);p(i,93,39-y,gold)end
 p(i,7,7,gold);p(i,88,7,gold);p(i,7,32,gold);p(i,88,32,gold)
 s:saveAs(path("art","source","visual_refactor","ui_button_"..id..".aseprite"))
 s:saveCopyAs(path("art","sprites","ui","button_"..id..".png"));s:close()
end
local types={
 {"burn","ec693c","flame"},{"chill","8ec9f0","flake"},{"freeze","d1faff","crystal"},
 {"stagger","f1bb72","star"},{"airborne","91e4c3","swirl"},{"barrier","b3e5ff","shield"},
 {"guard","e4c17d","shield"},{"invulnerable","e6ccff","star"}
}
for _,entry in ipairs(types) do
 local id=entry[1];local fg=C(entry[2]);local s=Sprite(24,24,ColorMode.RGB);local im=s.cels[1].image
 local dark=C("172333"); local pale=C("fff8dc")
 rect(im,2,2,20,20,dark)
 rect(im,2,2,20,1,fg);rect(im,2,21,20,1,fg);rect(im,2,2,1,20,fg);rect(im,21,2,1,20,fg)
 if entry[3]=="flame" then
  line(im,12,4,8,13,fg);line(im,12,4,16,13,fg);line(im,8,13,10,19,fg);line(im,16,13,14,19,fg)
  rect(im,11,12,3,7,pale)
 elseif entry[3]=="flake" then
  line(im,12,4,12,20,pale);line(im,5,12,19,12,pale);line(im,7,7,17,17,fg);line(im,7,17,17,7,fg)
 elseif entry[3]=="crystal" then
  for y=5,19 do local span=7-math.abs(12-y);rect(im,12-span,y,span*2+1,1,fg)end
  line(im,12,5,12,19,pale)
 elseif entry[3]=="shield" then
  line(im,7,5,17,5,fg);line(im,7,5,7,15,fg);line(im,17,5,17,15,fg);line(im,7,15,12,20,fg);line(im,17,15,12,20,fg)
  line(im,12,8,12,17,pale)
 elseif entry[3]=="star" then
  line(im,12,4,12,20,fg);line(im,4,12,20,12,fg);line(im,7,7,17,17,pale);line(im,7,17,17,7,pale)
 else
  for j=0,12 do local t=j*.5;local rad=2+j*.48;p(im,12+math.floor(math.cos(t)*rad),12+math.floor(math.sin(t)*rad),fg)end
 end
 s:saveAs(path("art","source","visual_refactor","status_"..id..".aseprite"))
 s:saveCopyAs(path("art","sprites","status",id..".png"));s:close()
end
print("Aseprite UI kit: 6 button states and 8 status icons")
