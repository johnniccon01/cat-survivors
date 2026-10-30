class_name ItemPanel
extends ColorRect
## Gear (see Items): the five slots across the top with what is worn in each,
## below them every item you own for the chosen slot. ← → choose the slot,
## ↑ ↓ an item, Enter puts it on or takes it off (at most
## Profile.LEGENDARY_WORN legendaries), X twice melts it into gold,
## I / Esc closes.

signal closed

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")
const ROWS := 8

var _slot := 0
var _index := 0
## First list row shown (the list scrolls when there are more than ROWS).
var _top := 0
## The item X was pressed on once: a second X melts it.
var _melt_uid := 0
var _slot_boxes: Array[PanelContainer] = []
var _rows: Array[PanelContainer] = []
var _slot_icons: Array[ItemIcon] = []
var _row_icons: Array[ItemIcon] = []
var _cat: CatPreview
var _header: Label
var _desc: Label
var _note: Label


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 6)
	UiStyle.board(self, box)
	var title := _label(38, GOLD)
	title.text = "ITEMS_TITLE"
	box.add_child(title)
	_header = _label(18, Color("d9cce6"))
	box.add_child(_header)

	# The cat wearing it all, beside the five slots.
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)
	_cat = CatPreview.new()
	_cat.gear = true
	_cat.zoom = 3.2
	_cat.walking = true
	_cat.custom_minimum_size = Vector2(150, 110)
	top.add_child(_cat)
	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 6)
	top.add_child(slots)
	for i in Items.slots().size():
		var slot_box := PanelContainer.new()
		slot_box.custom_minimum_size = Vector2(150, 62)
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 4)
		slot_box.add_child(inner)
		var icon := ItemIcon.new(30.0)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inner.add_child(icon)
		_slot_icons.append(icon)
		var label := _label(14, Color.WHITE)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 104
		inner.add_child(label)
		slot_box.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_box.gui_input.connect(_on_slot_input.bind(i))
		slots.add_child(slot_box)
		_slot_boxes.append(slot_box)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.custom_minimum_size = Vector2(700, ROWS * 32)
	box.add_child(list)
	for i in ROWS:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(700, 28)
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		row.add_child(inner)
		var icon := ItemIcon.new(22.0)
		inner.add_child(icon)
		_row_icons.append(icon)
		var label := _label(17, Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.custom_minimum_size.x = 650
		inner.add_child(label)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_input.bind(i))
		list.add_child(row)
		_rows.append(row)

	_desc = _label(17, Color("d9cce6"))
	_desc.custom_minimum_size = Vector2(860, 64)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_desc)
	_note = _label(16, GOLD)
	box.add_child(_note)
	var hint := _label(15, Color("8f7ea3"))
	hint.text = "ITEMS_HINT"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 900
	box.add_child(hint)
	var back := UiStyle.click_button("SET_BACK", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	box.add_child(back)


func open() -> void:
	visible = true
	_index = 0
	_top = 0
	_note.text = ""
	_melt_uid = 0
	_refresh()


func _slot_id() -> String:
	return Items.slots()[_slot]


## Items for the chosen slot, best first.
func _list() -> Array:
	var slot := _slot_id()
	var found := Profile.items.filter(func(item: Dictionary) -> bool: return item["slot"] == slot)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Items.worth(a) > Items.worth(b) if Items.worth(a) != Items.worth(b) else int(a["uid"]) > int(b["uid"]))
	return found


func _refresh() -> void:
	_header.text = tr("ITEMS_COUNT") % [Profile.items.size(), Profile.ITEM_STASH]
	for i in _slot_boxes.size():
		var slot: String = Items.slots()[i]
		var worn := Profile.worn_item(slot)
		_slot_icons[i].show_item(worn, slot)
		var label := _slot_boxes[i].get_child(0).get_child(1) as Label
		label.text = "%s\n%s" % [tr("ITEM_SLOT_" + slot), Items.item_name(worn) if not worn.is_empty() else tr("ITEMS_EMPTY_SLOT")]
		label.label_settings.font_color = Items.rarity_color(worn) if not worn.is_empty() else Color("8f7ea3")
		_slot_boxes[i].add_theme_stylebox_override("panel", _box(i == _slot, not worn.is_empty()))
	var list := _list()
	_index = clampi(_index, 0, maxi(list.size() - 1, 0))
	_top = clampi(_top, maxi(_index - ROWS + 1, 0), _index)
	var worn_uid := int(Profile.equipped_items.get(_slot_id(), 0))
	for i in ROWS:
		var n := _top + i
		var row := _rows[i]
		var label := row.get_child(0).get_child(1) as Label
		row.visible = n < list.size()
		if n >= list.size():
			continue
		var item: Dictionary = list[n]
		var worn := int(item["uid"]) == worn_uid
		_row_icons[i].show_item(item)
		label.text = "  %s %s%s" % ["◆" if worn else "◇", Items.item_name(item), "   (%s)" % tr("ITEMS_WORN") if worn else ""]
		label.label_settings.font_color = Items.rarity_color(item)
		row.add_theme_stylebox_override("panel", _box(n == _index, worn))
	_cat.cat_id = Profile.selected_cat
	_cat.queue_redraw()
	if list.is_empty():
		_desc.text = tr("ITEMS_EMPTY")
	else:
		_desc.text = Items.describe(list[_index])


func _box(selected: bool, highlight: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("5b4470") if selected else Color("3b2a4a")
	sb.border_color = GOLD if highlight else (Color("8f7ea3") if selected else Color("3b2a4a"))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	return sb


## _input, not _unhandled_input: the panel must see keys before the GUI
## focus of the screen behind it does.
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	var count := _list().size()
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_slot = (_slot - 1 + _slot_boxes.size()) % _slot_boxes.size()
		_index = 0
		_top = 0
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_slot = (_slot + 1) % _slot_boxes.size()
		_index = 0
		_top = 0
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_index = (_index - 1 + count) % count if count > 0 else 0
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_index = (_index + 1) % count if count > 0 else 0
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		_melt_uid = 0
		_note.text = ""
		_activate()
		_refresh()
		return
	elif event is InputEventKey and event.physical_keycode == KEY_X:
		_melt()
		_refresh()
		return
	elif event.is_action_pressed("items") or event.is_action_pressed("pause"):
		_close()
		return
	else:
		return
	_melt_uid = 0
	_note.text = ""
	Audio.play("click", -10.0, 0.0)
	_refresh()


func _selected() -> Dictionary:
	var list := _list()
	return list[_index] if _index < list.size() else {}


## What Enter (or a click) does on the selected item.
func _activate() -> void:
	var item := _selected()
	if item.is_empty():
		Audio.play("hurt", -10.0, 0.0)
		return
	if not Profile.toggle_item(int(item["uid"])):
		_note.text = tr("ITEMS_LEGENDARY_LIMIT") % Profile.LEGENDARY_WORN
		Audio.play("hurt", -10.0, 0.0)
		return
	Audio.play("select", -6.0, 0.0)


## X once asks, X again on the same item melts it into gold.
func _melt() -> void:
	var item := _selected()
	if item.is_empty():
		return
	var uid := int(item["uid"])
	if _melt_uid != uid:
		_melt_uid = uid
		_note.text = tr("ITEMS_MELT_ASK") % [Items.item_name(item), Items.salvage_gold(item)]
		Audio.play("click", -10.0, 0.0)
		return
	_melt_uid = 0
	_note.text = tr("ITEMS_MELTED") % Profile.salvage_item(uid)
	Audio.play("chest", -6.0, 0.0)


func _on_slot_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_slot = i
		_index = 0
		_top = 0
		Audio.play("click", -10.0, 0.0)
		_refresh()


## Mouse: hovering a row selects it, clicking it does what Enter does.
func _on_row_input(event: InputEvent, i: int) -> void:
	var n := _top + i
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_index = n
			_activate()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_index = mini(_index + 1, _list().size() - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_index = maxi(_index - 1, 0)
		_refresh()
	elif event is InputEventMouseMotion and _index != n:
		_index = n
		_refresh()


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
