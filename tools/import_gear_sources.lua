local root=app.params.root; if not root then error("Missing root") end
local function p(...)local v=root;for _,x in ipairs({...}) do v=app.fs.joinPath(v,x) end;return v end
local files=app.fs.listFiles(p("art","icons","gear"))
for _,file in ipairs(files) do
 if file:match("%.png$") then
  local name=app.fs.fileTitle(file)
  local img=app.open(p("art","icons","gear",file))
  if img then
   img.layers[1].name="item_material"
   local accents=img:newLayer();accents.name="magical_highlight_edit"
   img:saveAs(p("art","source","menu_revamp","gear",name..".aseprite"))
   print("GEAR SOURCE "..name)
   img:close()
  end
 end
end