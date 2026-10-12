class_name UI extends RefCounted
## Battlemage Arena UI kit: explicit hierarchy and 9-slice pixel-art surfaces.
const INK: Color = Color("#101c2b")
const MUTED: Color = Color("#a2b1bf")
const GOLD: Color = Color("#d9bc80")
const WHITE: Color = Color("#e9e9e1")
const FIRE: Color = Color("#f59a63")
const ICE: Color = Color("#83d5f5")
const EARTH: Color = Color("#d4ba7a")
const AIR: Color = Color("#9de3c5")
const SOURCE := "res://art/sprites/ui/"

static func box(color: Color = INK, border: Color = Color("#526674"), radius: int = 2) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.border_color = border
 style.set_border_width_all(2)
 style.set_corner_radius_all(radius)
 style.anti_aliasing = false
 style.content_margin_left = 16
 style.content_margin_right = 16
 style.content_margin_top = 12
 style.content_margin_bottom = 12
 return style

static func texture_skin(name: String, inset: int = 16) -> StyleBoxTexture:
 var style := StyleBoxTexture.new()
 style.texture = load(SOURCE + name + ".png")
 style.set_texture_margin_all(inset)
 style.content_margin_left = 18
 style.content_margin_right = 18
 style.content_margin_top = 14
 style.content_margin_bottom = 14
 return style

static func pixel_button(state: String) -> StyleBoxTexture:
 var style := texture_skin("button_" + state, 12)
 style.content_margin_left = 19
 style.content_margin_right = 19
 style.content_margin_top = 11
 style.content_margin_bottom = 11
 return style

static func progress_style(color: Color) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.set_corner_radius_all(1)
 style.anti_aliasing = false
 style.set_content_margin_all(0)
 return style

static func _body_font() -> Font:
 return load("res://art/fonts/NotoSans.ttf") as Font

static func _display_font() -> Font:
 return load("res://art/fonts/Cinzel.ttf") as Font

static func theme() -> Theme:
 var value := Theme.new()
 value.default_font = _body_font()
 value.default_font_size = 17
 value.set_color("font_color","Label",WHITE)
 value.set_color("font_color","Button",WHITE)
 value.set_color("font_hover_color","Button",Color("#fff1c9"))
 value.set_color("font_pressed_color","Button",Color("#fff4d5"))
 value.set_color("font_disabled_color","Button",Color("#798996"))
 for node_type: String in ["Button","OptionButton"]:
  value.set_stylebox("normal",node_type,pixel_button("normal"))
  value.set_stylebox("hover",node_type,pixel_button("hover"))
  value.set_stylebox("pressed",node_type,pixel_button("pressed"))
  value.set_stylebox("disabled",node_type,pixel_button("disabled"))
  value.set_stylebox("focus",node_type,pixel_button("focus"))
 value.set_stylebox("panel","PanelContainer",texture_skin("panel"))
 value.set_stylebox("panel","TabContainer",texture_skin("panel"))
 value.set_stylebox("tab_selected","TabBar",pixel_button("selected"))
 value.set_stylebox("tab_unselected","TabBar",pixel_button("normal"))
 value.set_stylebox("tab_hovered","TabBar",pixel_button("hover"))
 value.set_stylebox("normal","LineEdit",box(Color("#0b1825"),Color("#657585")))
 value.set_stylebox("focus","LineEdit",box(Color.TRANSPARENT,GOLD))
 value.set_color("font_color","LineEdit",WHITE)
 value.set_stylebox("background","ProgressBar",progress_style(Color("#07111d")))
 value.set_stylebox("fill","ProgressBar",progress_style(Color("#c76c65")))
 value.set_stylebox("panel","PopupMenu",texture_skin("tooltip"))
 value.set_stylebox("panel","TooltipPanel",texture_skin("tooltip"))
 value.set_color("font_color","TooltipLabel",WHITE)
 value.set_stylebox("slider","HSlider",box(Color("#1e3342")))
 value.set_stylebox("grabber_area","HSlider",box(Color("#384d5e"),GOLD))
 value.set_stylebox("grabber_area_highlight","HSlider",box(Color("#445d71"),Color("#f4d49a")))
 value.set_color("font_color","CheckButton",WHITE)
 value.set_color("font_hover_color","CheckButton",GOLD)
 value.set_stylebox("scroll","VScrollBar",box(Color("#132535")))
 value.set_stylebox("grabber","VScrollBar",box(Color("#64798a"),Color("#8794a0")))
 value.set_stylebox("grabber_highlight","VScrollBar",box(Color("#d9bc80"),GOLD))
 value.set_stylebox("grabber_pressed","VScrollBar",box(Color("#9e8255"),GOLD))
 return value

static func panel(parent: Node, rect: Rect2, color: Color = INK) -> PanelContainer:
 var node := PanelContainer.new()
 node.position = rect.position
 node.size = rect.size
 node.add_theme_stylebox_override("panel",texture_skin("panel"))
 node.mouse_filter = Control.MOUSE_FILTER_STOP
 parent.add_child(node)
 return node

static func featured(parent: Node, rect: Rect2, modal: bool = false) -> PanelContainer:
 var node := panel(parent,rect)
 node.add_theme_stylebox_override("panel",texture_skin("modal" if modal else "portrait"))
 return node

static func column(parent: Node, gap: int = 10) -> VBoxContainer:
 var node := VBoxContainer.new()
 node.add_theme_constant_override("separation",gap)
 parent.add_child(node)
 return node

static func row(parent: Node, gap: int = 12) -> HBoxContainer:
 var node := HBoxContainer.new()
 node.add_theme_constant_override("separation",gap)
 parent.add_child(node)
 return node

static func label(parent: Node, text: String, font_size: int = 18, color: Color = WHITE, wrap: bool = false) -> Label:
 var node := Label.new()
 node.text = text
 node.add_theme_font_size_override("font_size",roundi(font_size * float(GameState.settings.ui_scale)))
 node.add_theme_color_override("font_color",color)
 if font_size >= 24:
  node.add_theme_font_override("font",_display_font())
 if wrap:
  node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(node)
 return node

static func section(parent: Node, title: String) -> void:
 var title_row := row(parent,10)
 label(title_row,"◆",13,GOLD)
 var title_label := label(title_row,title.to_upper(),15,GOLD)
 title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 title_row.add_child(HSeparator.new())

static func rule(parent: Node) -> HSeparator:
 var separator := HSeparator.new()
 separator.add_theme_constant_override("separation",6)
 separator.modulate = Color("#526674")
 parent.add_child(separator)
 return separator

static func button(parent: Node, text: String, action: Callable, primary: bool = false) -> Button:
 var node := Button.new()
 node.text = text
 node.custom_minimum_size.y = 48
 node.focus_mode = Control.FOCUS_ALL
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.add_theme_font_size_override("font_size",16)
 if primary:
  node.add_theme_stylebox_override("normal",pixel_button("selected"))
  node.add_theme_color_override("font_color",Color("#fff1c9"))
 node.pressed.connect(func() -> void:
  Sound.cue("ui",-8)
  action.call())
 parent.add_child(node)
 return node

static func bar(parent: Node, value: float, maximum: float, fill_color: Color = Color("#c76c65")) -> ProgressBar:
 var node := ProgressBar.new()
 node.custom_minimum_size.y = 13
 node.max_value = maximum
 node.value = value
 node.show_percentage = false
 node.add_theme_stylebox_override("fill",progress_style(fill_color))
 parent.add_child(node)
 return node

static func spacer(parent: Node, height: float) -> void:
 var node := Control.new()
 node.custom_minimum_size.y = height
 parent.add_child(node)

static func actor_portrait(parent: Node, key: String, size: int = 112) -> TextureRect:
 var image := TextureRect.new()
 var texture := load("res://art/sprites/actors/" + key + ".png") as Texture2D
 if texture != null:
  var atlas := AtlasTexture.new()
  atlas.atlas = texture
  var dim := 96 if key in ["golem","champion"] else 64
  atlas.region = Rect2(3*dim,0,dim,dim)
  image.texture = atlas
 image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size=Vector2(size,size)
 parent.add_child(image)
 return image

static func item_icon(parent: Node, texture: Texture2D, size: int = 56) -> TextureRect:
 var image := TextureRect.new()
 image.texture=texture
 image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size=Vector2(size,size)
 parent.add_child(image)
 return image

static func detail_card(parent: Node, name: String, detail: String, color: Color = GOLD) -> VBoxContainer:
 var card := PanelContainer.new()
 card.add_theme_stylebox_override("panel",texture_skin("tooltip"))
 card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(card)
 var col := column(card,6)
 label(col,name,20,color,true)
 label(col,detail,14,MUTED,true)
 return col

static func color_for_school(school: String) -> Color:
 match school:
  "Fire": return FIRE
  "Ice": return ICE
  "Earth": return EARTH
  "Air": return AIR
 return GOLD
