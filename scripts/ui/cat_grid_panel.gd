class_name CatGridPanel
extends ColorRect
## Every cat at once in a grid (the strip on the neighbourhood screen only
## shows a part of them and scrolls). Click a cat to choose it; Esc closes.

signal picked(index: int)

const COLUMNS := 8

var _grid: GridContainer


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.9)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	UiStyle.board(self, box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiStyle.label("SELECT_ALL_CATS", 28, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UiStyle.click_button("SET_BACK", 0, 15)
	UiStyle.add_key(close, "Esc", 11)
	close.pressed.connect(func() -> void: visible = false)
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(COLUMNS * 128 + 20, 520)
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)


## Shows `ids` (the strip's order); `current` is the chosen one, `home` the
## cats whose home is the chosen map.
func open(ids: Array[String], current: int, home: Array) -> void:
	for child in _grid.get_children():
		child.queue_free()
	for i in ids.size():
		var id := ids[i]
		var unlocked := Profile.is_unlocked(id)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(120, 118)
		b.clip_contents = true
		for state in ["normal", "hover", "pressed"]:
			var sb := UiStyle.card(i == current)
			if state == "hover" and i != current:
				sb.border_color = Color("6a5784")
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func() -> void:
			visible = false
			picked.emit(i))
		var col := VBoxContainer.new()
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.offset_top = 4
		col.offset_bottom = -6
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(col)
		var preview := CatPreview.new()
		preview.cat_id = id
		preview.locked = not unlocked
		preview.zoom = 1.7
		preview.custom_minimum_size = Vector2(110, 80)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(preview)
		var name_label := UiStyle.plain(TranslationServer.translate("CAT_%s_NAME" % id) if unlocked else "???", 14, UiStyle.GOLD if i == current else (UiStyle.TEXT if unlocked else UiStyle.MUTED))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.custom_minimum_size.x = 110
		col.add_child(name_label)
		if id in home:
			var mark := UiStyle.tag("⌂", UiStyle.GOLD, 12)
			mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			mark.offset_left = -26
			mark.offset_right = -4
			mark.offset_top = 4
			mark.offset_bottom = 22
			b.add_child(mark)
		_grid.add_child(b)
	visible = true


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_pressed() and not event.is_echo() and event.is_action_pressed("pause"):
		visible = false
