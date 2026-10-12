class_name UI extends RefCounted
const INK: Color = Color("111d2d")
const MUTED: Color = Color("a7b1c0")
const GOLD: Color = Color("e0c28a")
const WHITE: Color = Color("e8e8e3")

static func box(color: Color = INK, border: Color = Color("465163"), radius: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = false
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func pixel_button(state: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load("res://art/sprites/ui/button_%s.png" % state)
	style.set_texture_margin_all(10.0)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

static func progress_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	style.anti_aliasing = false
	style.set_content_margin_all(0)
	return style

static func theme() -> Theme:
	var value := Theme.new()
	value.default_font_size = 17
	value.set_color("font_color", "Label", WHITE)
	value.set_color("font_color", "Button", WHITE)
	value.set_color("font_hover_color", "Button", GOLD)
	value.set_color("font_pressed_color", "Button", Color("fff4d5"))
	value.set_color("font_disabled_color", "Button", Color("718092"))
	for node_type: String in ["Button", "OptionButton"]:
		value.set_stylebox("normal", node_type, pixel_button("normal"))
		value.set_stylebox("hover", node_type, pixel_button("hover"))
		value.set_stylebox("pressed", node_type, pixel_button("pressed"))
		value.set_stylebox("disabled", node_type, pixel_button("disabled"))
		value.set_stylebox("focus", node_type, pixel_button("focus"))
	value.set_stylebox("normal", "LineEdit", box(Color("0c1622"), Color("7f846c")))
	value.set_color("font_color", "LineEdit", WHITE)
	value.set_stylebox("background", "ProgressBar", progress_style(Color("07111d")))
	value.set_stylebox("fill", "ProgressBar", progress_style(Color("c76c65")))
	value.set_stylebox("panel", "PopupMenu", box())
	value.set_stylebox("panel", "TooltipPanel", box(Color("17283b"), GOLD))
	value.set_color("font_color", "TooltipLabel", WHITE)
	return value

static func panel(parent: Node, rect: Rect2, color: Color = INK) -> PanelContainer:
	var node := PanelContainer.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(color))
	parent.add_child(node)
	return node

static func column(parent: Node, gap: int = 10) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	parent.add_child(node)
	return node

static func row(parent: Node, gap: int = 12) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	parent.add_child(node)
	return node

static func label(parent: Node, text: String, font_size: int = 18, color: Color = WHITE, wrap: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", roundi(font_size * float(GameState.settings.ui_scale)))
	node.add_theme_color_override("font_color", color)
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, action: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 43
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		node.add_theme_stylebox_override("normal", pixel_button("selected"))
		node.add_theme_color_override("font_color", Color("f9e2b4"))
	node.pressed.connect(func() -> void: Sound.cue("ui", -8); action.call())
	parent.add_child(node)
	return node

static func bar(parent: Node, value: float, maximum: float, fill_color: Color = Color("c76c65")) -> ProgressBar:
	var node := ProgressBar.new()
	node.custom_minimum_size.y = 12
	node.max_value = maximum
	node.value = value
	node.show_percentage = false
	node.add_theme_stylebox_override("fill", progress_style(fill_color))
	parent.add_child(node)
	return node

static func spacer(parent: Node, height: float) -> void:
	var node := Control.new()
	node.custom_minimum_size.y = height
	parent.add_child(node)
