local root=app.params.root; if not root then error("missing root") end
local function p(...)local a=root;for _,v in ipairs({...}) do a=app.fs.joinPath(a,v) end;return a end
local ids={"hound","skitter","spitter","wisp","golem","pyromancer","cryomancer","battlemage","champion"}
local specs={{"idle",6},{"move",6},{"cast",6},{"hurt",3},{"death",7}}
for _,id in ipairs(ids) do
 local file=p("art","source","enemy_revamp",id..".aseprite")
 local sprite=app.open(file)
 if not sprite then error("cannot open "..file) end
 local index=1;local count=0
 local wanted={}
 for _,entry in ipairs(specs) do table.insert(wanted,entry) end
 if id=="champion" then table.insert(wanted,{"barrier",6});table.insert(wanted,{"phase",6}) end
 local tags={}
 for _,tag in ipairs(sprite.tags) do tags[tag.name]=tag end
 for _,entry in ipairs(wanted) do
  local tag=tags[entry[1]]
  if not tag then error("missing tag "..id.." "..entry[1]) end
  if tag.fromFrame.frameNumber~=index or tag.toFrame.frameNumber~=index+entry[2]-1 then
   error(string.format("bad tag %s %s: %d..%d expected %d..%d",id,entry[1],tag.fromFrame.frameNumber,tag.toFrame.frameNumber,index,index+entry[2]-1))
  end
  index=index+entry[2];count=count+1
 end
 if #sprite.frames~=index-1 then error("wrong frame total "..id) end
 if #sprite.layers<2 then error("missing editable accent layer "..id) end
 print(string.format("OK %s %d frames %d clips %d layers",id,#sprite.frames,count,#sprite.layers))
 sprite:close()
end