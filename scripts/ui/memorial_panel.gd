class_name MemorialPanel
extends ColorRect
## The memorial stones on the Cemetery: every cat that retired after losing
## its nine lives, with its generation, wins, nights and the day it retired.
## Opened from the stone sign by the Cemetery on the town map. Esc closes.

signal closed

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")
const COLUMNS := 4

var _header: Label
var _grid: GridContainer
var _empty: Label


func _ready() -> void:
	color = Color(0.06, 0.05, 0.09, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	UiStyle.board(self, box)
	var title := _label(34, GOLD)
	title.text = "MEMORIALS_TITLE"
	box.add_child(title)
	_header = _label(17, Color("d9d4e6"))
	_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_header.custom_minimum_size = Vector2(820, 0)
	box.add_child(_header)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(840, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)
	_empty = _label(17, Color("9a92ac"))
	_empty.text = "MEMORIALS_EMPTY"
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.custom_minimum_size = Vector2(820, 0)
	box.add_child(_empty)
	var back := UiStyle.click_button("SET_BACK", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	box.add_child(back)


func open() -> void:
	visible = true
	for child in _grid.get_children():
		child.queue_free()
	var list: Array = Profile.retired
	_header.text = tr("MEMORIALS_HEADER") % list.size()
	_empty.visible = list.is_empty()
	# Newest first: the last one to retire stands at the front.
	for i in range(list.size() - 1, -1, -1):
		_grid.add_child(_card(list[i]))


## One stone: the cat (greyed a little, like an old photo), its name and
## what it did in its generation.
func _card(data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 0)
	card.add_theme_stylebox_override("panel", UiStyle.box(Color(0.16, 0.15, 0.2, 0.95), Color("6a6878")))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	var cat := CatPreview.new()
	cat.cat_id = String(data["cat"])
	cat.zoom = 2.0
	cat.custom_minimum_size = Vector2(190, 84)
	cat.modulate = Color(0.85, 0.82, 0.9)
	v.add_child(cat)
	var name := _label(18, Color("f4ecd4"))
	name.text = tr("CAT_%s_NAME" % String(data["cat"]))
	v.add_child(name)
	var gen := _label(13, Color("c8c0d8"))
	gen.text = tr("MEMORIALS_GEN") % [int(data["gen"]), String(data.get("date", ""))]
	v.add_child(gen)
	var stats := _label(13, Color("b8f0a0"))
	stats.text = tr("MEMORIALS_STATS") % [int(data.get("wins", 0)), int(data.get("nights", 0)), int(data.get("best_rank", 0))]
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.custom_minimum_size = Vector2(188, 0)
	v.add_child(stats)
	return card


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_pressed() and not event.is_echo() and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_close()


func _close() -> void:
	visible = false
	closed.emit()


func _label(size: int, font_color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 4
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
