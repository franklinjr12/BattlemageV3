local root=app.params.root; if not root then error("missing root") end
local only=app.params.only
local function p(...)local a=root;for _,v in ipairs({...}) do a=app.fs.joinPath(a,v) end;return a end
local ids={"hound","skitter","spitter","wisp","golem","pyromancer","cryomancer","battlemage","champion"}
local sequence={"idle","move","cast","hurt","death","barrier","phase"}
for _,id in ipairs(ids) do
 if not only or id==only then
  local src=app.open(p("art","source","enemy_revamp",id..".aseprite"))
  if not src then error("missing source for "..id) end
  local size=(id=="champion" or id=="golem") and 96 or 64
  local rows=id=="champion" and 7 or 5
  local target=Sprite(size*7,size*rows,ColorMode.RGB)
  local atlas=target.cels[1].image
  local tags={}
  for _,tag in ipairs(src.tags) do tags[tag.name]=tag end
  for row=1,rows do
   local tag=tags[sequence[row]]
   if not tag then error("missing tag "..sequence[row].." for "..id) end
   local count=tag.toFrame.frameNumber-tag.fromFrame.frameNumber+1
   if count>7 then error("clip too many frames "..id) end
   for index=0,count-1 do
    local frame_number=tag.fromFrame.frameNumber+index
    for _,cel in ipairs(src.cels) do
     if cel.frame.frameNumber==frame_number then
      -- Compose all authored layers onto the runtime sprite grid.
      atlas:drawImage(cel.image,index*size+cel.position.x,(row-1)*size+cel.position.y)
     end
    end
   end
  end
  target:saveCopyAs(p("art","sprites","actors",id..".png"))
  print("EXPORT "..id.." "..(size*7).."x"..(size*rows))
  target:close();src:close()
 end
end