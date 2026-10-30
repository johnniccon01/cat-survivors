class_name ArtifactPanel
extends ColorRect
## Artifacts: permanent items earned in the quest book. Take up to
## Profile.ARTIFACT_SLOTS into the night. Arrows choose, Enter takes / leaves,
## V / Esc closes. Artifacts not earned yet show as "???" with where to get
## them.

signal closed

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")
const COLUMNS := 3

var _ids: Array[String] = []
var _index := 0
var _rows: Array[PanelContainer] = []
var _header: Label
var _desc: Label


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	for id: String in GameData.artifacts:
		_ids.append(id)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	UiStyle.board(self, box)

	var title := _label(38, GOLD)
	title.text = "ARTIFACTS_TITLE"
	box.add_child(title)
	_header = _label(20, GOLD)
	box.add_child(_header)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	for id in _ids:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(300, 30)
		var label := _label(16, Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(label)
		grid.add_child(row)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_input.bind(_rows.size()))
		_rows.append(row)

	_desc = _label(18, Color("d9cce6"))
	_desc.custom_minimum_size = Vector2(920, 60)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_desc)
	var hint := _label(16, Color("8f7ea3"))
	hint.text = "ARTIFACTS_HINT"
	box.add_child(hint)
	var back := UiStyle.click_button("SET_BACK", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	box.add_child(back)


func open() -> void:
	# Quest steps done before artifacts existed pay out now.
	QuestBook.check()
	visible = true
	_refresh()


func _refresh() -> void:
	_header.text = tr("ARTIFACTS_EQUIPPED") % [Profile.artifacts.size(), _ids.size()]
	for i in _ids.size():
		var id := _ids[i]
		var owned := Profile.has_artifact(id)
		var worn: bool = Profile.careers.has(Profile.selected_cat) and ("art:" + id) in Profile.careers[Profile.selected_cat]["talents"]
		var label := _rows[i].get_child(0) as Label
		label.text = "  %s %s" % ["◆" if worn else "◇", tr("ARTIFACT_%s_NAME" % id) if owned else "???"]
		label.label_settings.font_color = Color(GameData.artifacts[id]["color"]) if owned else Color("6a5a7a")
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("5b4470") if i == _index else Color("3b2a4a")
		sb.border_color = GOLD if worn else (Color("8f7ea3") if i == _index else Color("3b2a4a"))
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		_rows[i].add_theme_stylebox_override("panel", sb)
	var sel := _ids[_index]
	if Profile.has_artifact(sel):
		_desc.text = tr("ARTIFACT_%s_DESC" % sel)
	else:
		_desc.text = "%s\n%s" % [tr("ARTIFACTS_UNKNOWN"), QuestBook.artifact_source(sel)]


## _input, not _unhandled_input: the panel must see keys before the GUI
## focus of the screen behind it does.
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	# Swallow every key while open (releases too), so the menu behind can't
	# react to it.
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_index = (_index - COLUMNS + _ids.size()) % _ids.size()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_index = (_index + COLUMNS) % _ids.size()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_index = (_index - 1 + _ids.size()) % _ids.size()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_index = (_index + 1) % _ids.size()
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		_activate()
	elif event.is_action_pressed("artifacts") or event.is_action_pressed("pause"):
		visible = false
		closed.emit()
		return
	else:
		return
	Audio.play("click", -10.0, 0.0)
	_refresh()


## What Enter (or a click) does on the selected row.
## Artifacts are talents now: they are picked in the cat's talents.
func _activate() -> void:
	Audio.play("hurt", -12.0, 0.0)


## Mouse: hovering a row selects it, clicking it does what Enter does.
func _on_row_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_index = i
		_activate()
		_refresh()
	elif event is InputEventMouseMotion and _index != i:
		_index = i
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
