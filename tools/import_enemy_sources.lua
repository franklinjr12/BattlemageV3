local root=app.params["root"]; if not root then error("Missing root") end
local function path(...) local p=root;for _,v in ipairs({...}) do p=app.fs.joinPath(p,v) end;return p end
local types={"hound","skitter","spitter","wisp","golem","pyromancer","cryomancer","battlemage","champion"}
local specs={{"idle",6,200},{"move",6,111},{"cast",6,100},{"hurt",3,83},{"death",7,111}}
for _,key in ipairs(types) do
 local source=app.open(path("art","sprites","actors",key..".png"))
 if source==nil then error("Cannot open exported atlas for "..key) end
 local atlas=source.cels[1].image
 local cell=(key=="champion" or key=="golem") and 96 or 64
 local target=Sprite(cell,cell,ColorMode.RGB)
 target.layers[1].name="body_material_and_contour"
 -- Additional editable layer for later hand-placed lighting/FX; keep as an independent layer.
 local effects=target:newLayer();effects.name="accent_fx"
 local total=0
 local tagdefs={}
 local sequence=specs
 if key=="champion" then
  sequence={{"idle",6,200},{"move",6,111},{"cast",6,100},{"hurt",3,83},{"death",7,111},{"barrier",6,111},{"phase",6,111}}
 end
 for row,spec in ipairs(sequence) do
  for col=0,spec[2]-1 do
   total=total+1
   local fr=target.frames[total]
   if fr==nil then fr=target:newFrame() end
   fr.duration=spec[3]/1000
   local cel
   if total==1 then cel=target.cels[1]
   else cel=target:newCel(target.layers[1],fr) end
   if not cel then error("Failed cel "..key.." "..total) end
   local buffer=Image(cell,cell,ColorMode.RGB)
   for y=0,cell-1 do for x=0,cell-1 do
    buffer:drawPixel(x,y,atlas:getPixel(x+col*cell,y+(row-1)*cell))
   end end
   cel.image=buffer
   if col==spec[2]-1 then
    table.insert(tagdefs,{total-spec[2]+1,total,spec[1]})
   end
  end
 end
 for _,t in ipairs(tagdefs) do
  local tag=target:newTag(target.frames[t[1]],target.frames[t[2]])
  tag.name=t[3]
 end
 target:saveAs(path("art","source","enemy_revamp",key..".aseprite"))
 target:close();source:close()
 print("SOURCE "..key.." frames="..total)
end
