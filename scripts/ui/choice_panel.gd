class_name ChoicePanel
extends ColorRect
## A story choice: a question and two answers. Left/right pick, Enter (or A)
## confirms. The game is paused while it is open (main.gd queues it like a
## level-up).

signal chosen(index: int)

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _title: Label
var _prompt: Label
var _cards: Array[PanelContainer] = []
var _labels: Array[Label] = []
var _index := 0


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.8)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 20)
	add_child(box)
	_title = _label(40, GOLD)
	box.add_child(_title)
	_prompt = _label(22, Color("e8dcf0"))
	_prompt.custom_minimum_size = Vector2(860, 0)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_prompt)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	for i in 2:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(400, 120)
		var label := _label(22, Color.WHITE)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(label)
		row.add_child(card)
		_cards.append(card)
		_labels.append(label)
	var hint := _label(18, Color("8f7ea3"))
	hint.text = "CHOICE_HINT"
	box.add_child(hint)


func open(title: String, prompt: String, options: Array) -> void:
	_title.text = title
	_prompt.text = prompt
	for i in 2:
		_labels[i].text = options[i]
	_index = 0
	visible = true
	_refresh()


func _refresh() -> void:
	for i in 2:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("5b4470") if i == _index else Color("3b2a4a")
		sb.border_color = GOLD if i == _index else Color("8f7ea3")
		sb.set_border_width_all(3 if i == _index else 2)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(14)
		_cards[i].add_theme_stylebox_override("panel", sb)


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left") or event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_index = 1 - _index
		Audio.play("click", -10.0, 0.0)
		_refresh()
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		visible = false
		Audio.play("select", -6.0, 0.0)
		chosen.emit(_index)


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
