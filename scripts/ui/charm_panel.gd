class_name CharmPanel
extends ColorRect
## Charm collection: pick up to Profile.CHARM_SLOTS charms to wear on the
## collar for the next runs. Arrows choose, Enter equips/unequips, C / Esc
## closes. Charms you haven't found yet show as "???".

signal closed

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")
const RARITY_COLORS := {"common": Color("d9cce6"), "rare": Color("8fd3ff"), "epic": Color("c77dff")}

var _ids: Array[String] = []
var _index := 0
var _rows: Array[PanelContainer] = []
var _header: Label
var _desc: Label


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	for id: String in GameData.charms:
		_ids.append(id)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var title := _label(38, GOLD)
	title.text = "CHARMS_TITLE"
	box.add_child(title)
	_header = _label(20, GOLD)
	box.add_child(_header)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for id in _ids:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(430, 34)
		var label := _label(18, Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(label)
		grid.add_child(row)
		_rows.append(row)

	_desc = _label(18, Color("d9cce6"))
	_desc.custom_minimum_size = Vector2(860, 50)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_desc)
	var hint := _label(16, Color("8f7ea3"))
	hint.text = "CHARMS_HINT"
	box.add_child(hint)


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	_header.text = tr("CHARMS_EQUIPPED") % [Profile.equipped_charms.size(), Profile.CHARM_SLOTS]
	for i in _ids.size():
		var id := _ids[i]
		var owned := Profile.has_charm(id)
		var worn := id in Profile.equipped_charms
		var label := _rows[i].get_child(0) as Label
		label.text = "  %s %s" % ["◆" if worn else "◇", tr("CHARM_%s_NAME" % id) if owned else "???"]
		label.label_settings.font_color = RARITY_COLORS[GameData.charms[id]["rarity"]] if owned else Color("6a5a7a")
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("5b4470") if i == _index else Color("3b2a4a")
		sb.border_color = GOLD if worn else (Color("8f7ea3") if i == _index else Color("3b2a4a"))
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		_rows[i].add_theme_stylebox_override("panel", sb)
	var sel := _ids[_index]
	_desc.text = CharmPanel.describe(sel) if Profile.has_charm(sel) else tr("CHARMS_UNKNOWN")


## "Rare – +6 % faster attacks" style description of a charm.
static func describe(id: String) -> String:
	var data: Dictionary = GameData.charms[id]
	return "%s – %s" % [TranslationServer.translate("RARITY_" + String(data["rarity"]).to_upper()), TranslationServer.translate("CHARM_%s_DESC" % id)]


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton) or not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_index = (_index - 2 + _ids.size()) % _ids.size()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_index = (_index + 2) % _ids.size()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_index = (_index - 1 + _ids.size()) % _ids.size()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_index = (_index + 1) % _ids.size()
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		if Profile.toggle_charm(_ids[_index]):
			Audio.play("select", -6.0, 0.0)
		else:
			Audio.play("hurt", -10.0, 0.0)
	elif event.is_action_pressed("charms") or event.is_action_pressed("pause"):
		visible = false
		closed.emit()
		return
	else:
		return
	Audio.play("click", -10.0, 0.0)
	_refresh()


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
