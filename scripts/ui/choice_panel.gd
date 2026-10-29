class_name ChoicePanel
extends ColorRect
## A story or shrine choice: a question and its answers (more than four wrap
## into rows). An answer is a text or {"title", "desc"}. Arrows or the mouse
## pick, Enter, A or a click confirms; with a back button, Esc or B cancels
## (emits -1). The game is paused while it is open (main.gd queues it like a
## level-up).

signal chosen(index: int)

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")
const COLUMNS := 4

var _title: Label
var _prompt: Label
var _grid: GridContainer
var _cards: Array[PanelContainer] = []
var _labels: Array[Label] = []
var _descs: Array[Label] = []
var _back: Button
var _index := 0
var _count := 2
var _cancel := false


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.8)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	_title = _label(40, GOLD)
	box.add_child(_title)
	_prompt = _label(22, Color("e8dcf0"))
	_prompt.custom_minimum_size = Vector2(860, 0)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_prompt)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 16)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_grid)
	_back = UiStyle.button("SET_BACK", 260)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.focus_mode = Control.FOCUS_NONE
	_back.pressed.connect(_cancel_choice)
	_back.mouse_entered.connect(func() -> void:
		_index = _count
		_refresh())
	box.add_child(_back)
	var hint := _label(18, Color("8f7ea3"))
	hint.text = "CHOICE_HINT"
	box.add_child(hint)


func _add_card() -> void:
	var i := _cards.size()
	var card := PanelContainer.new()
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inner)
	var label := _label(22, Color.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner.add_child(label)
	var desc := _label(16, Color("cfc2dc"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(desc)
	_grid.add_child(card)
	card.mouse_entered.connect(func() -> void:
		if _index != i:
			_index = i
			_refresh())
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_index = i
			_confirm())
	_cards.append(card)
	_labels.append(label)
	_descs.append(desc)


func open(title: String, prompt: String, options: Array, cancel: bool = false) -> void:
	_title.text = title
	_prompt.text = prompt
	_count = maxi(options.size(), 1)
	_cancel = cancel
	while _cards.size() < _count:
		_add_card()
	var columns := mini(_count, COLUMNS)
	_grid.columns = columns
	var many := _count > COLUMNS
	var width: float = [400, 400, 400, 300, 270][columns]
	for i in _cards.size():
		_cards[i].visible = i < _count
		if i >= _count:
			continue
		var option: Variant = options[i] if i < options.size() else ""
		var desc := ""
		if option is Dictionary:
			desc = String(option.get("desc", ""))
			option = option.get("title", "")
		_labels[i].text = String(option)
		_labels[i].label_settings.font_size = 20 if many else 22
		_descs[i].text = desc
		_descs[i].visible = desc != ""
		_cards[i].custom_minimum_size = Vector2(width, 96 if many else 120)
	_back.visible = cancel
	_index = 0
	visible = true
	_refresh()


func _refresh() -> void:
	_back.add_theme_color_override("font_color", GOLD if _cancel and _index == _count else UiStyle.TEXT)
	for i in _cards.size():
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("5b4470") if i == _index else Color("3b2a4a")
		sb.border_color = GOLD if i == _index else Color("8f7ea3")
		sb.set_border_width_all(3 if i == _index else 2)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(14)
		_cards[i].add_theme_stylebox_override("panel", sb)


func _confirm() -> void:
	if not visible:
		return
	if _cancel and _index == _count:
		_cancel_choice()
		return
	visible = false
	Audio.play("select", -6.0, 0.0)
	chosen.emit(_index)


func _cancel_choice() -> void:
	if not visible or not _cancel:
		return
	visible = false
	Audio.play("click", -6.0, 0.0)
	chosen.emit(-1)


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	if _cancel and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		_cancel_choice()
		return
	var slots := _count + (1 if _cancel else 0)
	var step := 0
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		step = -1
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		step = 1
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		step = -_grid.columns
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		step = _grid.columns
	if step == 0:
		if event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
			_confirm()
		return
	if absi(step) == 1:
		_index = posmod(_index + step, slots)
	elif _index == _count:
		# From the back button, up goes to the last row.
		_index = _count - 1 if step < 0 else _index
	elif _index + step >= _count:
		# Down past the last row lands on the back button.
		_index = _count if _cancel else _index
	else:
		_index = maxi(_index + step, 0) if _index + step >= 0 else _index
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
