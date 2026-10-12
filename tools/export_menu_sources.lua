local root=app.params.root; if not root then error("missing root") end
local function p(...)local a=root;for _,v in ipairs({...}) do a=app.fs.joinPath(a,v) end;return a end
local controls={"panel","modal","tooltip","portrait","tab","button_normal","button_hover","button_pressed","button_selected","button_disabled","button_focus"}
for _,name in ipairs(controls) do
 local sprite=app.open(p("art","source","menu_revamp",name..".aseprite"))
 if not sprite then error("missing menu source "..name) end
 sprite:saveCopyAs(p("art","sprites","ui",name..".png"))
 sprite:close()
 print("UI EXPORT "..name)
end
local dir=p("art","source","menu_revamp","gear")
for _,name in ipairs(app.fs.listFiles(dir)) do
 if name:match("%.aseprite$") then
  local asset=app.fs.fileTitle(name)
  local sprite=app.open(p("art","source","menu_revamp","gear",name))
  if not sprite then error("missing gear source "..asset) end
  sprite:saveCopyAs(p("art","icons","gear",asset..".png"))
  sprite:close()
  print("GEAR EXPORT "..asset)
 end
end