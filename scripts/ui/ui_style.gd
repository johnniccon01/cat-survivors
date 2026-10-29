class_name UiStyle
## Shared look for menu widgets (buttons, labels, overlays) so every screen
## matches.

const BG := Color("161019")
const PANEL := Color("2c2338")
const PANEL_HOVER := Color("43355a")
const BORDER := Color("57496e")
## The dark lip under panels and buttons that gives them depth.
const DEPTH := Color("0a0810")
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


## A button for the mouse only: it never takes keyboard focus, so the arrow
## keys keep driving the screen it sits on.
static func click_button(text: String, width: float = 160.0, size: int = 17) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 36)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_color_override("font_outline_color", OUTLINE)
	b.add_theme_stylebox_override("normal", box(PANEL, BORDER))
	b.add_theme_stylebox_override("hover", box(PANEL_HOVER, GOLD))
	b.add_theme_stylebox_override("pressed", box(PANEL_HOVER, GOLD))
	b.pressed.connect(func() -> void: Audio.play("click", -8.0, 0.0))
	return b


## The biggest font size up to `size` at which `text` fits in `width`, so
## long names in other languages shrink instead of getting cut off.
static func fit_size(font: Font, text: String, width: float, size: int, smallest: int = 8) -> int:
	while size > smallest and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	return size


## Shrinks the font of every button in `row` until the row fits in
## `width` (longer words in some languages would push it off the screen).
static func fit_row(row: BoxContainer, width: float, smallest: int = 11) -> void:
	var buttons: Array[Button] = []
	for child in row.get_children():
		if child is Button:
			buttons.append(child)
	if buttons.is_empty():
		return
	# All shrink by the same share, so a bigger button stays bigger.
	var sizes: Array[int] = []
	for b in buttons:
		sizes.append(b.get_theme_font_size("font_size"))
	var k := 1.0
	while k > 0.4 and _row_width(row) > width:
		k -= 0.04
		for i in buttons.size():
			buttons[i].add_theme_font_size_override("font_size", maxi(roundi(sizes[i] * k), smallest))


static func _row_width(row: BoxContainer) -> float:
	var total := 0.0
	var shown := 0
	for child in row.get_children():
		if child is Control and child.visible:
			total += (child as Control).get_combined_minimum_size().x
			shown += 1
	return total + row.get_theme_constant("separation") * maxi(shown - 1, 0)


static func box(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(6)
	# A dark lip underneath, like the signs on the neighbourhood map.
	sb.shadow_color = Color(DEPTH, 0.55 * fill.a)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 3)
	return sb


## A big panel of the menus (map frame, side panel, bars): a dark plum
## board with a soft border, a gold hairline inside and a dark lip.
static func frame(fill: Color = Color("211b2b"), border: Color = Color("4a3f5c"), width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(11)
	sb.set_content_margin_all(8 + width - 2)
	sb.shadow_color = Color(DEPTH, 0.7)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(0, 5)
	return sb


## The gold Play button: bright face, darker rim, a deep lip underneath.
static func gold_button(hover: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ffcf5e") if hover else Color("f2b33a")
	sb.border_color = Color("7a4d0c")
	sb.set_border_width_all(2)
	sb.border_width_bottom = 6
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(10)
	sb.shadow_color = Color(GOLD, 0.45 if hover else 0.28)
	sb.shadow_size = 10 if hover else 6
	return sb


## A framed, scrollable "your weapons" box under the level-up cards or a
## chest; fill its RichTextLabel (the panel's meta "text") with Hud.weapons_text.
static func inventory_panel(width: float, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box(Color(BG, 0.9), BORDER))
	panel.custom_minimum_size = Vector2(width, height)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var vbox := VBoxContainer.new()
	vbox.add_child(label(TranslationServer.translate("PAUSE_WEAPONS"), 16, GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("normal_font_size", 13)
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(text)
	panel.add_child(vbox)
	panel.set_meta("text", text)
	return panel


## Puts a menu's centred content box on a framed board (the same plum board
## with a gold hairline as the neighbourhood screen), centred in `parent`.
static func board(parent: Control, box: Control) -> PanelContainer:
	var sb := frame(Color(0.13, 0.1, 0.17, 0.96), Color("5a4a6e"), 2)
	sb.set_content_margin_all(16)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	parent.add_child(panel)
	panel.add_child(box)
	return panel


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
