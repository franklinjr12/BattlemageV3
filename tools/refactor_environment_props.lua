local root=app.params["root"];if not root then error("root")end
local function path(...)local p=root;for _,x in ipairs({...})do p=app.fs.joinPath(p,x)end return p end
local function C(h,a)return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),a or 255)end
local function px(im,x,y,col)if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,col)end end
local function rect(im,x,y,w,h,col)for yy=y,y+h-1 do for xx=x,x+w-1 do px(im,xx,yy,col)end end end
local function line(im,x,y,xx,yy,c)local n=math.max(math.abs(xx-x),math.abs(yy-y));for j=0,n do px(im,math.floor(x+(xx-x)*j/math.max(1,n)),math.floor(y+(yy-y)*j/math.max(1,n)),c)end end
local dark=C("202838");local mid=C("576475");local pale=C("9ca79b");local gold=C("d8ba79")
local function save(id,s)
 s:saveAs(path("art","source","visual_refactor","prop_"..id..".aseprite"))
 s:saveCopyAs(path("art","sprites","props",id..".png"));s:close()
end
for v=0,1 do
 local id=v==0 and "column" or "broken_column"
 local s=Sprite(48,96,ColorMode.RGB);local im=s.cels[1].image
 rect(im,5,79,38,12,dark);rect(im,8,82,32,7,mid);rect(im,9,80,30,2,pale)
 local top=v==0 and 12 or 34
 rect(im,10,top,28,70-top,dark);rect(im,12,top+1,24,69-top,mid);rect(im,14,top+3,5,65-top,pale)
 for k=0,3 do rect(im,21+k*4,top+4,1,62-top,C("3a4b5b"))end
 rect(im,6,72,36,8,dark);rect(im,9,73,30,5,pale);rect(im,8,75,32,3,mid)
 if v==0 then
  rect(im,6,8,36,9,dark);rect(im,9,10,30,5,pale);rect(im,8,17,32,5,mid)
  rect(im,20,43,8,2,gold);rect(im,23,39,2,11,gold)
 else
  line(im,11,35,20,27,pale);line(im,20,27,30,34,mid);line(im,30,34,38,23,pale)
  line(im,22,46,16,57,dark);line(im,16,57,25,63,dark)
 end
 save(id,s)
end
local banners={
 fire=C("d87650"),ice=C("6abbde"),earth=C("b69a6c"),air=C("65b6a7")
}
for id,c in pairs(banners) do
 local s=Sprite(32,64,ColorMode.RGB);local im=s.cels[1].image
 rect(im,2,6,28,4,gold);rect(im,5,10,22,38,dark);rect(im,7,12,18,31,c)
 rect(im,5,40,6,5,c);rect(im,21,40,6,5,c);rect(im,10,43,12,5,c)
 rect(im,15,18,2,18,gold);rect(im,11,24,10,2,gold)
 rect(im,13,20,6,2,C("ffefb8"))
 save("banner_"..id,s)
end
do
 local s=Sprite(48,72,ColorMode.RGB);local im=s.cels[1].image
 rect(im,5,57,38,10,dark);rect(im,9,59,30,5,mid);rect(im,11,52,26,6,gold)
 rect(im,12,29,24,23,dark);rect(im,16,32,16,20,mid);rect(im,19,31,10,13,C("ffaf66"))
 line(im,24,15,19,33,C("ffd176"));line(im,24,15,28,34,C("ffd176"))
 rect(im,22,22,5,15,C("fff0b0"));rect(im,18,36,12,9,C("ee914a"))
 save("brazier",s)
end
do
 local s=Sprite(48,72,ColorMode.RGB);local im=s.cels[1].image
 rect(im,9,58,30,9,dark);rect(im,12,59,24,6,mid)
 line(im,24,7,12,26,C("80d6f9"));line(im,24,7,36,26,C("b4e9ff"))
 line(im,12,26,24,51,C("2a95c5"));line(im,36,26,24,51,C("2a95c5"))
 line(im,24,7,24,51,C("ecfaff"));line(im,15,25,33,25,C("a9eaff"))
 rect(im,20,29,5,7,C("d6f6ff"))
 save("crystal",s)
end
print("Aseprite environment props: 2 columns, 4 banners, brazier, crystal")
