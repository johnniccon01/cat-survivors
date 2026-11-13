class_name UiStyle
## Shared look for menu widgets (buttons, labels, overlays) so every screen
## matches: the "shoe box" look (dark cardboard boards with cream text, kraft
## cardboard buttons with ink text, a red marker for the chosen thing). All of
## it is plain StyleBoxFlat with uneven edges, so it costs nothing per frame.

## The dim backdrop behind a menu (a very dark brown).
const BG := Color("1c120a")
## Dark cardboard: panels and buttons' neighbours.
const PANEL := Color("5b3b21")
const PANEL_HOVER := Color("7a5230")
## Light edge of a cardboard piece (the cut paper edge).
const BORDER := Color("a47646")
## The dark lip under panels and buttons that gives them depth.
const DEPTH := Color("120b06")
const GOLD := Color("f2b84a")
const TEXT := Color("f4e8cb")
## Quiet text on dark cardboard.
const MUTED := Color("c4a27a")
## Softer cream for descriptions.
const SOFT := Color("e6d3ab")
const OUTLINE := Color("1a0f07")
const INK := Color("2b1d12")
const RED := Color("d3261f")
## Kraft cardboard of the buttons.
const KRAFT := Color("c99a64")
const KRAFT_HOVER := Color("fbf1d6")

static var _theme: Theme


## A theme whose default font is the Krabica text font; set on a menu panel's
## root so every label inside that has no font of its own uses it.
static func panel_theme() -> Theme:
	if _theme == null:
		_theme = Theme.new()
		_theme.default_font = BoxStyle.body_font()
	return _theme


static func label(text: String, size: int = 20, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	var settings := LabelSettings.new()
	settings.font = BoxStyle.bold_font()
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
	_cardboard_button(b, size, true)
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(func() -> void: Audio.play("click", -14.0, 0.0))
	return b


## A piece of kraft cardboard with ink text; hovered or focused it turns
## light cream with a red marker edge.
static func _cardboard_button(b: Button, size: int, head: bool) -> void:
	b.add_theme_font_override("font", BoxStyle.head_font() if head else BoxStyle.body_font())
	b.add_theme_font_size_override("font_size", size + (2 if head else 0))
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, INK)
	b.add_theme_color_override("font_disabled_color", Color(INK, 0.45))
	b.add_theme_constant_override("outline_size", 0)
	b.add_theme_stylebox_override("normal", cardboard(KRAFT, Color("8c5f36"), 1))
	b.add_theme_stylebox_override("hover", cardboard(KRAFT_HOVER, RED, 1))
	b.add_theme_stylebox_override("focus", cardboard(KRAFT_HOVER, RED, 1))
	b.add_theme_stylebox_override("pressed", cardboard(Color("ecdcb2"), RED, 1))
	b.add_theme_stylebox_override("hover_pressed", cardboard(Color("ecdcb2"), RED, 1))
	b.add_theme_stylebox_override("disabled", cardboard(Color("a98558"), Color("8c5f36"), 1))


## A flat piece of cardboard with uneven edges: borders of different widths
## and corners of different roundness make it look cut by hand. `variant`
## (0..3) turns the unevenness around so neighbours do not look stamped.
static func cardboard(fill: Color, edge: Color, variant: int = 0, margin: float = 6.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	var w: Array = [[2, 3, 2, 4], [3, 2, 4, 2], [2, 2, 3, 4], [3, 3, 2, 3]][variant % 4]
	sb.border_width_left = w[0]
	sb.border_width_top = w[1]
	sb.border_width_right = w[2]
	sb.border_width_bottom = w[3]
	var r: Array = [[6, 3, 7, 4], [3, 7, 4, 6], [5, 5, 3, 7], [7, 4, 6, 3]][variant % 4]
	sb.corner_radius_top_left = r[0]
	sb.corner_radius_top_right = r[1]
	sb.corner_radius_bottom_right = r[2]
	sb.corner_radius_bottom_left = r[3]
	sb.set_content_margin_all(margin)
	sb.shadow_color = Color(DEPTH, 0.6 * fill.a)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(2, 3)
	return sb


## A button for the mouse only: it never takes keyboard focus, so the arrow
## keys keep driving the screen it sits on.
static func click_button(text: String, width: float = 160.0, size: int = 17) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 36)
	b.focus_mode = Control.FOCUS_NONE
	_cardboard_button(b, size, false)
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


## Hides the key caps on a row's buttons (when even a smaller font doesn't
## make the row fit), giving their room back to the text.
static func drop_keys(row: BoxContainer) -> void:
	for child in row.get_children():
		if child is Button and child.has_meta("key_cap"):
			var cap: Control = child.get_meta("key_cap")
			if not cap.visible:
				continue
			cap.visible = false
			for state in ["normal", "hover", "focus", "pressed", "disabled"]:
				if child.has_theme_stylebox_override(state):
					var sb := child.get_theme_stylebox(state).duplicate() as StyleBox
					sb.content_margin_right = 10.0
					sb.content_margin_left = 10.0
					child.add_theme_stylebox_override(state, sb)


static func row_width(row: BoxContainer) -> float:
	return _row_width(row)


static func _row_width(row: BoxContainer) -> float:
	var total := 0.0
	var shown := 0
	for child in row.get_children():
		if child is Control and child.visible:
			total += (child as Control).get_combined_minimum_size().x
			shown += 1
	return total + row.get_theme_constant("separation") * maxi(shown - 1, 0)


static func box(fill: Color, border: Color) -> StyleBoxFlat:
	# A dark lip underneath, like the signs on the neighbourhood map.
	var sb := cardboard(fill, border, 0, 6.0)
	sb.shadow_size = 1
	return sb


## A big panel of the menus (map frame, side panel, bars): a dark plum
## board with a soft border, a gold hairline inside and a dark lip.
static func frame(fill: Color = Color("3a2412"), border: Color = Color("8c5f36"), width: int = 2) -> StyleBoxFlat:
	var sb := cardboard(fill, border, 2, 8 + width - 2)
	sb.border_width_left = width
	sb.border_width_top = width + 1
	sb.border_width_right = width + 1
	sb.border_width_bottom = width + 2
	sb.shadow_color = Color(DEPTH, 0.7)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(3, 6)
	return sb


## The gold Play button: bright face, darker rim, a deep lip underneath.
static func gold_button(hover: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ffcf5e") if hover else Color("f2b33a")
	sb.border_color = RED if hover else Color("5b3b21")
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
	var sb := frame(Color("3a2412", 0.97), Color("8c5f36"), 2)
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


# --- Shared pieces of the newer screens: cards, key caps, tags, segments ---

const CARD := Color("4a2f1a")
const CARD_BORDER := Color("7a5434")
const CARD_SELECTED := Color("6b4527")
const GREEN := Color("9ad77a")
const SEG_EMPTY := Color("3a2412")


## A small card inside a panel (list rows, tiles); `selected` gets the gold edge.
static func card(selected: bool = false, fill: Color = CARD) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_SELECTED if selected else fill
	sb.border_color = RED if selected else CARD_BORDER
	sb.set_border_width_all(3 if selected else 2)
	sb.border_width_bottom += 1
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 5
	sb.anti_aliasing = true
	sb.set_content_margin_all(10)
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


## A keyboard key drawn as a little key cap ("Esc", "R"…).
static func key_cap(text: String, size: int = 12) -> PanelContainer:
	var cap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4e8cb")
	sb.border_color = Color("8c5f36")
	sb.set_border_width_all(1)
	sb.border_width_bottom = 3
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	cap.add_theme_stylebox_override("panel", sb)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_font_override("font", BoxStyle.bold_font())
	l.add_theme_color_override("font_color", INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = size + 4
	cap.add_child(l)
	return cap


## Puts key cap `key` at the right end of button `b` (its text moves over
## to make room), so the key is shown on what it does.
static func add_key(b: Button, key: String, size: int = 12) -> PanelContainer:
	var cap := key_cap(key, size)
	b.add_child(cap)
	b.set_meta("key_cap", cap)
	var font := b.get_theme_font("font")
	var width := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 14.0
	width = maxf(width, size + 14.0)
	cap.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	cap.offset_left = -width - 10.0
	cap.offset_right = -10.0
	cap.offset_top = -11.0
	cap.offset_bottom = 11.0
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		if b.has_theme_stylebox_override(state):
			var sb := b.get_theme_stylebox(state).duplicate() as StyleBox
			sb.content_margin_right = width + 16.0
			sb.content_margin_left = maxf(sb.content_margin_left, 12.0)
			b.add_theme_stylebox_override(state, sb)
	return cap


## A quiet note at the right end of button `b` ("2 left"), with the same
## room left on the other side so the button's own text stays centred.
static func side_note(b: Button, note: String, size: int = 13) -> Label:
	var l := Label.new()
	l.text = note
	l.add_theme_font_override("font", BoxStyle.body_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", MUTED)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	l.offset_left = -96.0
	l.offset_right = -14.0
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		if b.has_theme_stylebox_override(state):
			var sb := b.get_theme_stylebox(state).duplicate() as StyleBox
			sb.content_margin_right = 92.0
			sb.content_margin_left = 92.0
			b.add_theme_stylebox_override(state, sb)
	return l


## A short label on a dark chip ("legendary", "not started"…).
static func tag(text: String, color: Color = Color("e6d3ab"), size: int = 13, border: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("3a2412")
	sb.border_color = border
	sb.set_border_width_all(1 if border.a > 0.0 else 0)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", sb)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", BoxStyle.bold_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	chip.add_child(l)
	return chip


## A row of `count` little segments, the first `filled` gold (levels, steps).
static func segments(count: int, filled: int, seg_width: float = 16.0, height: float = 6.0) -> SegmentBar:
	var bar := SegmentBar.new()
	bar.count = count
	bar.filled = filled
	bar.seg_width = seg_width
	bar.seg_height = height
	return bar


## Plain text in the game's look without an outline (on panels), left aligned.
static func plain(t: String, size: int = 15, color: Color = TEXT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", BoxStyle.body_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
