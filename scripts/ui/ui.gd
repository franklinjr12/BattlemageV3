class_name UI extends RefCounted
const INK: Color = Color("101b2a")
const MUTED: Color = Color("91a3b7")
const GOLD: Color = Color("dfc58d")
const WHITE: Color = Color("e5e8e8")

static func box(color: Color = INK, border: Color = Color("2c4054"), radius: int = 8) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func theme() -> Theme:
	var value: Theme = Theme.new()
	value.default_font_size = 17
	value.set_color("font_color", "Label", WHITE)
	value.set_color("font_color", "Button", WHITE)
	value.set_color("font_hover_color", "Button", GOLD)
	value.set_color("font_disabled_color", "Button", Color("64778b"))
	for node_type: String in ["Button", "OptionButton"]:
		value.set_stylebox("normal", node_type, box(Color("19293b")))
		value.set_stylebox("hover", node_type, box(Color("263b4c"), GOLD))
		value.set_stylebox("pressed", node_type, box(Color("314052"), GOLD))
		value.set_stylebox("disabled", node_type, box(Color("111d2a"), Color("253448")))
		value.set_stylebox("focus", node_type, box(Color(0, 0, 0, 0), GOLD))
	value.set_stylebox("normal", "LineEdit", box(Color("0c1523"), Color("4a6275")))
	value.set_color("font_color", "LineEdit", WHITE)
	value.set_stylebox("background", "ProgressBar", box(Color("07101b"), Color("2a3e51"), 3))
	value.set_stylebox("fill", "ProgressBar", box(Color("93c7b8"), Color("93c7b8"), 3))
	value.set_stylebox("panel", "PopupMenu", box())
	value.set_stylebox("panel", "TooltipPanel", box(Color("152537"), GOLD))
	value.set_color("font_color", "TooltipLabel", WHITE)
	return value

static func panel(parent: Node, rect: Rect2, color: Color = INK) -> PanelContainer:
	var node: PanelContainer = PanelContainer.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(color))
	parent.add_child(node)
	return node

static func column(parent: Node, gap: int = 10) -> VBoxContainer:
	var node: VBoxContainer = VBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	parent.add_child(node)
	return node

static func row(parent: Node, gap: int = 12) -> HBoxContainer:
	var node: HBoxContainer = HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	parent.add_child(node)
	return node

static func label(parent: Node, text: String, font_size: int = 18, color: Color = WHITE, wrap: bool = false) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", roundi(font_size * float(GameState.settings.ui_scale)))
	node.add_theme_color_override("font_color", color)
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, action: Callable, primary: bool = false) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.custom_minimum_size.y = 43
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		node.add_theme_stylebox_override("normal", box(Color("bba370"), GOLD))
		node.add_theme_color_override("font_color", Color("111b28"))
	node.pressed.connect(func() -> void: Sound.cue("ui", -8); action.call())
	parent.add_child(node)
	return node

static func bar(parent: Node, value: float, maximum: float) -> ProgressBar:
	var node: ProgressBar = ProgressBar.new()
	node.custom_minimum_size.y = 12
	node.max_value = maximum
	node.value = value
	node.show_percentage = false
	parent.add_child(node)
	return node

static func spacer(parent: Node, height: float) -> void:
	var node: Control = Control.new()
	node.custom_minimum_size.y = height
	parent.add_child(node)
