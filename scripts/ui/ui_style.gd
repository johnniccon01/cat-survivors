class_name UiStyle
## Shared look for menu widgets (buttons, labels, overlays) so every screen
## matches.

const BG := Color("1d1626")
const PANEL := Color("3b2a4a")
const PANEL_HOVER := Color("5b4470")
const BORDER := Color("6b5480")
const GOLD := Color("f2c14e")
const TEXT := Color("eee6f3")
const MUTED := Color("8f7ea3")
const OUTLINE := Color("2b1d14")


static func label(text: String, size: int = 20, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = maxi(size / 5, 3)
	settings.outline_color = OUTLINE
	l.label_settings = settings
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, width: float = 320.0, size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 44)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_color_override("font_outline_color", OUTLINE)
	b.add_theme_stylebox_override("normal", box(PANEL, BORDER))
	b.add_theme_stylebox_override("hover", box(PANEL_HOVER, GOLD))
	b.add_theme_stylebox_override("focus", box(PANEL_HOVER, GOLD))
	b.add_theme_stylebox_override("pressed", box(PANEL_HOVER, GOLD))
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(func() -> void: Audio.play("click", -14.0, 0.0))
	return b


static func box(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6)
	return sb


## Full-screen dimmed backdrop with a centred vertical box; returns the box.
static func overlay(parent: Control, alpha: float = 0.92) -> VBoxContainer:
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if parent is ColorRect:
		(parent as ColorRect).color = Color(BG, alpha)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	parent.add_child(vbox)
	return vbox
