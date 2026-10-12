local root=app.params.root; if not root then error("root parameter required") end
local function p(...)local t=root;for _,v in ipairs({...}) do t=app.fs.joinPath(t,v) end;return t end
local names={"panel","modal","tooltip","portrait","tab","button_normal","button_hover","button_pressed","button_selected","button_disabled","button_focus"}
for _,name in ipairs(names) do
 local image=app.open(p("art","sprites","ui",name..".png"))
 if image==nil then error("missing UI image "..name) end
 image.layers[1].name="frame_and_stone"
 local l=image:newLayer();l.name="ornament_edit_layer"
 image:saveAs(p("art","source","menu_revamp",name..".aseprite"))
 image:close()
 print("UI SOURCE "..name)
end