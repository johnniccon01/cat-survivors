class_name ItemPanel
extends ColorRect
## Gear (see Items, shared by all cats): the eight slots across the top with
## what is worn in each; below, on the left every item you own for the
## chosen slot, on the right the chosen item, how it compares with the one
## worn, and the buttons. ← → slot, ↑ ↓ item, Enter puts it on or takes it
## off (at most Profile.LEGENDARY_WORN legendaries), L locks it (a locked
## item is never melted), X twice melts it into gold, S changes the order,
## I / Esc closes.

signal closed

const ROWS := 9
const SORTS := ["rarity", "level", "new"]

var _slot := 0
var _index := 0
## First list row shown (the list scrolls when there are more than ROWS).
var _top := 0
var _sort := 0
## The item X was pressed on once: a second X melts it.
var _melt_uid := 0
var _slot_boxes: Array[PanelContainer] = []
var _slot_icons: Array[ItemIcon] = []
var _slot_names: Array[Label] = []
var _slot_counts: Array[Label] = []
var _rows: Array[PanelContainer] = []
var _row_icons: Array[ItemIcon] = []
var _row_names: Array[Label] = []
var _row_tags: Array[Label] = []
var _stash: Label
var _detail_icon: ItemIcon
var _detail_name: Label
var _detail_desc: Label
var _compare: VBoxContainer
var _note: Label
var _wear: Button
var _lock: Button
var _melt_button: Button
var _sort_button: Button


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size.x = 1180
	UiStyle.board(self, box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiStyle.label("ITEMS_TITLE", 32, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_stash = UiStyle.plain("", 16, UiStyle.MUTED)
	_stash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_stash)

	# The eight slots.
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	box.add_child(slots)
	for i in Items.slots().size():
		var slot_box := PanelContainer.new()
		slot_box.custom_minimum_size = Vector2(142, 62)
		slot_box.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_box.gui_input.connect(_on_slot_input.bind(i))
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 5)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_box.add_child(inner)
		var icon := ItemIcon.new(30.0)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inner.add_child(icon)
		_slot_icons.append(icon)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_child(col)
		var top := HBoxContainer.new()
		col.add_child(top)
		var slot_name := UiStyle.plain(tr("ITEM_SLOT_" + String(Items.slots()[i])), 11, UiStyle.MUTED)
		slot_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(slot_name)
		var count := UiStyle.plain("", 12, UiStyle.GOLD)
		top.add_child(count)
		_slot_counts.append(count)
		var worn_name := UiStyle.plain("", 12, Color.WHITE, true)
		worn_name.custom_minimum_size.x = 92
		worn_name.max_lines_visible = 2
		worn_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(worn_name)
		_slot_names.append(worn_name)
		slots.add_child(slot_box)
		_slot_boxes.append(slot_box)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	box.add_child(cols)
	# Left: the items of the slot.
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.custom_minimum_size = Vector2(560, ROWS * 38 - 4)
	cols.add_child(list)
	for i in ROWS:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(560, 34)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_input.bind(i))
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(inner)
		var icon := ItemIcon.new(22.0)
		inner.add_child(icon)
		_row_icons.append(icon)
		var label := UiStyle.plain("", 15)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.custom_minimum_size.x = 300
		inner.add_child(label)
		_row_names.append(label)
		var tag := UiStyle.plain("", 12, UiStyle.MUTED)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		inner.add_child(tag)
		_row_tags.append(tag)
		list.add_child(row)
		_rows.append(row)
	# Right: the chosen item.
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", UiStyle.card())
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(detail)
	var dcol := VBoxContainer.new()
	dcol.add_theme_constant_override("separation", 6)
	detail.add_child(dcol)
	var dhead := HBoxContainer.new()
	dhead.add_theme_constant_override("separation", 10)
	dcol.add_child(dhead)
	_detail_icon = ItemIcon.new(40.0)
	dhead.add_child(_detail_icon)
	_detail_name = UiStyle.plain("", 19, Color.WHITE, true)
	_detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dhead.add_child(_detail_name)
	_detail_desc = UiStyle.plain("", 14, Color("e7def2"), true)
	_detail_desc.custom_minimum_size = Vector2(560, 120)
	dcol.add_child(_detail_desc)
	dcol.add_child(UiStyle.plain(tr("ITEMS_COMPARE"), 13, UiStyle.GOLD))
	_compare = VBoxContainer.new()
	_compare.add_theme_constant_override("separation", 0)
	_compare.custom_minimum_size.y = 96
	dcol.add_child(_compare)

	_note = UiStyle.plain("", 15, UiStyle.GOLD)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.custom_minimum_size.y = 20
	box.add_child(_note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	_wear = _button(buttons, "Enter", func() -> void:
		_activate()
		_refresh())
	_lock = _button(buttons, "L", func() -> void:
		_toggle_lock()
		_refresh())
	_melt_button = _button(buttons, "X", func() -> void:
		_melt()
		_refresh())
	_sort_button = _button(buttons, "S", func() -> void:
		_sort = (_sort + 1) % SORTS.size()
		_index = 0
		_top = 0
		_refresh())
	var back := _button(buttons, "Esc", _close)
	back.text = tr("SET_BACK")


func _button(row: HBoxContainer, key: String, action: Callable) -> Button:
	var b := UiStyle.click_button("", 0, 15)
	b.custom_minimum_size = Vector2(150, 40)
	UiStyle.add_key(b, key, 11)
	b.pressed.connect(action)
	row.add_child(b)
	return b


func open() -> void:
	visible = true
	_index = 0
	_top = 0
	_note.text = ""
	_melt_uid = 0
	_refresh()


func _slot_id() -> String:
	return Items.slots()[_slot]


## Items for the chosen slot in the chosen order.
func _list() -> Array:
	var slot := _slot_id()
	var found := Profile.items.filter(func(item: Dictionary) -> bool: return item["slot"] == slot)
	var by: String = SORTS[_sort]
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		match by:
			"level":
				if int(a.get("ilvl", 1)) != int(b.get("ilvl", 1)):
					return int(a.get("ilvl", 1)) > int(b.get("ilvl", 1))
			"new":
				return int(a["uid"]) > int(b["uid"])
		if Items.worth(a) != Items.worth(b):
			return Items.worth(a) > Items.worth(b)
		return int(a["uid"]) > int(b["uid"]))
	return found


func _refresh() -> void:
	_stash.text = tr("ITEMS_STASH") % [Profile.items.size(), Profile.ITEM_STASH]
	for i in _slot_boxes.size():
		var slot: String = Items.slots()[i]
		var worn := Profile.worn_item(slot)
		var owned := Profile.items.filter(func(item: Dictionary) -> bool: return item["slot"] == slot).size()
		_slot_icons[i].show_item(worn, slot)
		_slot_names[i].text = Items.item_name(worn) if not worn.is_empty() else tr("ITEMS_EMPTY_SLOT")
		_slot_names[i].add_theme_color_override("font_color", Items.rarity_color(worn) if not worn.is_empty() else UiStyle.MUTED)
		_slot_counts[i].text = str(owned) if owned > 0 else ""
		_slot_boxes[i].add_theme_stylebox_override("panel", UiStyle.card(i == _slot))
	var list := _list()
	_index = clampi(_index, 0, maxi(list.size() - 1, 0))
	_top = clampi(_top, maxi(_index - ROWS + 1, 0), _index)
	var worn_uid := int(Profile.equipped_items.get(_slot_id(), 0))
	for i in ROWS:
		var n := _top + i
		var row := _rows[i]
		# An empty row stays in place (just faded out), so the panel never moves.
		var on := n < list.size()
		row.modulate.a = 1.0 if on else 0.0
		row.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
		if not on:
			continue
		var item: Dictionary = list[n]
		var worn := int(item["uid"]) == worn_uid
		_row_icons[i].show_item(item)
		_row_names[i].text = "%s%s%s" % ["◆ " if worn else "", "🔒 " if item.get("locked", false) else "", Items.item_name(item)]
		_row_names[i].add_theme_color_override("font_color", Items.rarity_color(item))
		_row_tags[i].text = "" if item["rarity"] == "legendary" else tr("ITEM_LEVEL") % int(item.get("ilvl", 1))
		var sb := UiStyle.card(n == _index)
		sb.set_content_margin_all(5)
		sb.content_margin_left = 8
		sb.content_margin_right = 10
		if worn and n != _index:
			sb.border_color = UiStyle.GOLD.darkened(0.35)
		row.add_theme_stylebox_override("panel", sb)
	var item := _selected()
	_detail_icon.show_item(item, _slot_id())
	for child in _compare.get_children():
		child.queue_free()
	if item.is_empty():
		_detail_name.text = tr("ITEMS_EMPTY")
		_detail_name.add_theme_color_override("font_color", UiStyle.MUTED)
		_detail_desc.text = ""
	else:
		_detail_name.text = Items.item_name(item)
		_detail_name.add_theme_color_override("font_color", Items.rarity_color(item))
		_detail_desc.text = Items.describe(item)
		_fill_compare(item)
	var is_worn := not item.is_empty() and int(item["uid"]) == worn_uid
	_wear.text = tr("ITEMS_TAKE_OFF" if is_worn else "ITEMS_WEAR")
	_lock.text = tr("ITEMS_UNLOCK" if item.get("locked", false) else "ITEMS_LOCK")
	_melt_button.text = tr("ITEMS_MELT")
	_sort_button.text = tr("ITEMS_SORT") % tr("ITEMS_SORT_" + String(SORTS[_sort]).to_upper())
	for b: Button in [_wear, _lock, _melt_button]:
		b.disabled = item.is_empty()
	_melt_button.disabled = item.is_empty() or item.get("locked", false)


## The chosen item against the one worn in its slot: a line per stat, green
## where it is better, red where it is worse.
func _fill_compare(item: Dictionary) -> void:
	var worn := Profile.worn_item(_slot_id())
	if worn.is_empty() or int(worn["uid"]) == int(item["uid"]):
		_compare.add_child(UiStyle.plain(tr("ITEMS_COMPARE_NONE") if worn.is_empty() else "–", 13, UiStyle.MUTED))
		return
	for pair: Array in Items.compare(item, worn):
		var stat: String = pair[0]
		var d: float = pair[1]
		if absf(d) < 0.0005:
			continue
		# Attack rate is a negative cooldown: less is better.
		var better := d < 0.0 if stat == "cooldown" else d > 0.0
		var text := Items.stat_text(stat, absf(d) if stat != "cooldown" else -absf(d))
		if not better:
			text = "−" + text.trim_prefix("+")
		_compare.add_child(UiStyle.plain(text, 13, UiStyle.GREEN if better else Color("ff8a80")))


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
		_activate()
		_refresh()
		return
	elif event is InputEventKey and event.physical_keycode == KEY_X:
		_melt()
		_refresh()
		return
	elif event is InputEventKey and event.physical_keycode == KEY_L:
		_toggle_lock()
		_refresh()
		return
	elif event is InputEventKey and event.physical_keycode == KEY_S:
		_sort = (_sort + 1) % SORTS.size()
		_index = 0
		_top = 0
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
	_melt_uid = 0
	_note.text = ""
	var item := _selected()
	if item.is_empty():
		Audio.play("hurt", -10.0, 0.0)
		return
	if not Profile.toggle_item(int(item["uid"])):
		_note.text = tr("ITEMS_LEGENDARY_LIMIT") % Profile.LEGENDARY_WORN
		Audio.play("hurt", -10.0, 0.0)
		return
	Audio.play("select", -6.0, 0.0)


func _toggle_lock() -> void:
	var item := _selected()
	if item.is_empty():
		return
	Profile.toggle_lock(int(item["uid"]))
	_melt_uid = 0
	_note.text = ""
	Audio.play("click", -8.0, 0.0)


## X once asks, X again on the same item melts it into gold.
func _melt() -> void:
	var item := _selected()
	if item.is_empty():
		return
	if item.get("locked", false):
		_note.text = tr("ITEMS_LOCKED_NO_MELT")
		Audio.play("hurt", -10.0, 0.0)
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
		_melt_uid = 0
		_note.text = ""
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
		_melt_uid = 0
		_note.text = ""
		_refresh()


func _close() -> void:
	visible = false
	closed.emit()
