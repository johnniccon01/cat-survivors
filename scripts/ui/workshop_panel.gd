class_name WorkshopPanel
extends ColorRect
## The workshops (Items.WORKSHOPS), one in every district, where building
## material goes into gear: the sewing room re-sews one stat, the smith
## raises the item level, the herbalist adds a stat and the laboratory raises
## the rarity. Each works only in its own district (the others show what
## they do and where they are); every one takes items apart for material.
## ↑ ↓ item, ← → workshop, Enter works on it, X twice takes it apart,
## Esc closes.

signal closed

const ROWS := 10
const ORDER := ["cats", "dogs", "wild", "company"]

var _tab := 0
var _index := 0
var _top := 0
var _take_uid := 0
var _tabs: Array[PanelContainer] = []
var _tab_labels: Array[Label] = []
var _rows: Array[PanelContainer] = []
var _row_icons: Array[ItemIcon] = []
var _row_names: Array[Label] = []
var _row_tags: Array[Label] = []
var _materials: Label
var _about: Label
var _icon: ItemIcon
var _name: Label
var _desc: Label
var _preview: Label
var _note: Label
var _do: Button
var _take: Button


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size.x = 1140
	UiStyle.board(self, box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiStyle.label("WORKSHOP_TITLE", 32, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_materials = UiStyle.plain("", 18, Color("e8c48a"))
	_materials.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_materials)

	# The four workshops: the one of this district works.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	for i in ORDER.size():
		var tab := PanelContainer.new()
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size.y = 52
		tab.mouse_filter = Control.MOUSE_FILTER_STOP
		tab.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_tab = i
				_refresh())
		var l := UiStyle.plain("", 14, Color.WHITE, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tab.add_child(l)
		tabs.add_child(tab)
		_tabs.append(tab)
		_tab_labels.append(l)
	_about = UiStyle.plain("", 15, Color("cfc3dd"), true)
	_about.custom_minimum_size = Vector2(1100, 44)
	box.add_child(_about)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	box.add_child(cols)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.custom_minimum_size = Vector2(520, ROWS * 34 - 4)
	cols.add_child(list)
	for i in ROWS:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(520, 30)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_input.bind(i))
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(inner)
		var icon := ItemIcon.new(20.0)
		inner.add_child(icon)
		_row_icons.append(icon)
		var label := UiStyle.plain("", 14)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.custom_minimum_size.x = 280
		inner.add_child(label)
		_row_names.append(label)
		var tag := UiStyle.plain("", 12, UiStyle.MUTED)
		inner.add_child(tag)
		_row_tags.append(tag)
		list.add_child(row)
		_rows.append(row)
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
	_icon = ItemIcon.new(40.0)
	dhead.add_child(_icon)
	_name = UiStyle.plain("", 18, Color.WHITE, true)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dhead.add_child(_name)
	_desc = UiStyle.plain("", 14, Color("e7def2"), true)
	_desc.custom_minimum_size = Vector2(560, 110)
	dcol.add_child(_desc)
	_preview = UiStyle.plain("", 15, UiStyle.GREEN, true)
	_preview.custom_minimum_size = Vector2(560, 60)
	dcol.add_child(_preview)

	_note = UiStyle.plain("", 15, UiStyle.GOLD)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.custom_minimum_size.y = 20
	box.add_child(_note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	_do = _button(buttons, "Enter", _work)
	_take = _button(buttons, "X", _take_apart)
	var back := _button(buttons, "Esc", _close)
	back.text = tr("SET_BACK")


func _button(row: HBoxContainer, key: String, action: Callable) -> Button:
	var b := UiStyle.click_button("", 0, 15)
	b.custom_minimum_size = Vector2(200, 40)
	UiStyle.add_key(b, key, 11)
	b.pressed.connect(func() -> void:
		action.call()
		_refresh())
	row.add_child(b)
	return b


func open() -> void:
	visible = true
	_tab = maxi(ORDER.find(Profile.district), 0)
	_index = 0
	_top = 0
	_take_uid = 0
	_note.text = ""
	_refresh()


func _action() -> String:
	return Items.WORKSHOPS[ORDER[_tab]]


## Works here: this district's workshop.
func _here() -> bool:
	return ORDER[_tab] == Profile.district


func _list() -> Array:
	var all := Profile.items.duplicate()
	all.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Items.worth(a) > Items.worth(b) if Items.worth(a) != Items.worth(b) else int(a["uid"]) > int(b["uid"]))
	return all


func _selected() -> Dictionary:
	var list := _list()
	return list[_index] if _index < list.size() else {}


func _refresh() -> void:
	_materials.text = tr("WORKSHOP_MATERIALS") % Profile.materials
	for i in ORDER.size():
		var d: String = ORDER[i]
		var open := DistrictMap.district_open(d)
		var w: String = Items.WORKSHOPS[d]
		_tab_labels[i].text = "%s\n%s" % [tr("WORKSHOP_%s_NAME" % w), ("🔒 " if not open else "") + tr("DISTRICT_NAME_" + d.to_upper())]
		_tab_labels[i].add_theme_color_override("font_color", UiStyle.GOLD if d == Profile.district else (Color.WHITE if open else UiStyle.MUTED))
		_tabs[i].add_theme_stylebox_override("panel", UiStyle.card(i == _tab))
	var d_now: String = ORDER[_tab]
	_about.text = tr("WORKSHOP_%s_DESC" % _action())
	if not DistrictMap.district_open(d_now):
		_about.text += "  " + tr("WORKSHOP_LOCKED")
	elif not _here():
		_about.text += "  " + tr("WORKSHOP_ELSEWHERE") % tr("DISTRICT_NAME_" + d_now.to_upper())
	var list := _list()
	_index = clampi(_index, 0, maxi(list.size() - 1, 0))
	_top = clampi(_top, maxi(_index - ROWS + 1, 0), _index)
	for i in ROWS:
		var n := _top + i
		var on := n < list.size()
		_rows[i].modulate.a = 1.0 if on else 0.0
		_rows[i].mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
		if not on:
			continue
		var item: Dictionary = list[n]
		_row_icons[i].show_item(item)
		_row_names[i].text = ("🔒 " if item.get("locked", false) else "") + Items.item_name(item)
		_row_names[i].add_theme_color_override("font_color", Items.rarity_color(item))
		_row_tags[i].text = "%s · %s" % [tr("ITEM_SLOT_" + String(item["slot"])), tr("ITEM_LEVEL") % int(item.get("ilvl", 1))]
		var sb := UiStyle.card(n == _index)
		sb.set_content_margin_all(4)
		sb.content_margin_left = 8
		sb.content_margin_right = 10
		_rows[i].add_theme_stylebox_override("panel", sb)
	var item := _selected()
	_icon.show_item(item)
	if item.is_empty():
		_name.text = tr("ITEMS_EMPTY")
		_name.add_theme_color_override("font_color", UiStyle.MUTED)
		_desc.text = ""
		_preview.text = ""
	else:
		_name.text = Items.item_name(item)
		_name.add_theme_color_override("font_color", Items.rarity_color(item))
		_desc.text = Items.describe(item)
		var problem := Items.work_problem(item, _action())
		_preview.text = tr(problem) if problem != "" else _preview_text(item)
		_preview.add_theme_color_override("font_color", UiStyle.MUTED if problem != "" else UiStyle.GREEN)
	var cost := Items.work_cost(item, _action()) if not item.is_empty() else 0
	_do.text = tr("WORKSHOP_DO") % cost
	_do.disabled = item.is_empty() or not _here() or Items.work_problem(item, _action()) != "" or Profile.materials < cost
	_take.text = tr("WORKSHOP_TAKE_APART") % (Items.salvage_materials(item) if not item.is_empty() else 0)
	_take.disabled = item.is_empty() or item.get("locked", false)


## What the work will do to this item.
func _preview_text(item: Dictionary) -> String:
	match _action():
		"SMITH":
			var lv := int(item.get("ilvl", 1))
			return tr("WORKSHOP_PREVIEW_SMITH") % [lv, lv + 1, roundi(Items.LEVEL_STEP * 100.0)]
		"SEW":
			return tr("WORKSHOP_PREVIEW_SEW")
		"HERBS":
			return tr("WORKSHOP_PREVIEW_HERBS")
		"LAB":
			var to: String = Items.RAISE[Items.RAISE.find(String(item["rarity"])) + 1]
			return tr("WORKSHOP_PREVIEW_LAB") % [tr("RARITY_" + String(item["rarity"]).to_upper()), tr("RARITY_" + to.to_upper())]
	return ""


func _work() -> void:
	_take_uid = 0
	var item := _selected()
	if item.is_empty():
		return
	if not _here():
		_note.text = tr("WORKSHOP_ELSEWHERE") % tr("DISTRICT_NAME_" + String(ORDER[_tab]).to_upper())
		Audio.play("hurt", -10.0, 0.0)
		return
	if Profile.materials < Items.work_cost(item, _action()):
		_note.text = tr("WORKSHOP_NOT_ENOUGH")
		Audio.play("hurt", -10.0, 0.0)
		return
	if Profile.workshop(int(item["uid"]), _action()):
		_note.text = tr("WORKSHOP_DONE")
		Audio.play("chest", -6.0, 0.0)
	else:
		Audio.play("hurt", -10.0, 0.0)


## X once asks, X again takes the item apart for material.
func _take_apart() -> void:
	var item := _selected()
	if item.is_empty():
		return
	if item.get("locked", false):
		_note.text = tr("ITEMS_LOCKED_NO_MELT")
		return
	var uid := int(item["uid"])
	if _take_uid != uid:
		_take_uid = uid
		_note.text = tr("WORKSHOP_TAKE_ASK") % [Items.item_name(item), Items.salvage_materials(item)]
		Audio.play("click", -10.0, 0.0)
		return
	_take_uid = 0
	_note.text = tr("WORKSHOP_TAKEN") % Profile.salvage_for_materials(uid)
	Audio.play("chest", -6.0, 0.0)


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	var count := _list().size()
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_index = (_index - 1 + count) % count if count > 0 else 0
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_index = (_index + 1) % count if count > 0 else 0
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_tab = (_tab - 1 + ORDER.size()) % ORDER.size()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_tab = (_tab + 1) % ORDER.size()
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		_work()
		_refresh()
		return
	elif event is InputEventKey and event.physical_keycode == KEY_X:
		_take_apart()
		_refresh()
		return
	elif event.is_action_pressed("pause") or (event is InputEventKey and event.physical_keycode == KEY_K):
		_close()
		return
	else:
		return
	_take_uid = 0
	_note.text = ""
	Audio.play("click", -10.0, 0.0)
	_refresh()


func _on_row_input(event: InputEvent, i: int) -> void:
	var n := _top + i
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_index = n
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_index = mini(_index + 1, _list().size() - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_index = maxi(_index - 1, 0)
		_take_uid = 0
		_note.text = ""
		_refresh()


func _close() -> void:
	visible = false
	closed.emit()
