class_name GoalsPanel
extends ColorRect
## List of long-term goals with progress and rewards. G / Esc closes.

signal closed

const GOLD := Color("f2c14e")
const DONE := Color("6cd48a")
const OUTLINE := Color("2b1d14")

var _list: VBoxContainer


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := _label(36, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.text = "GOALS_TITLE"
	box.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	box.add_child(_list)
	var hint := _label(16, Color("8f7ea3"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.text = "GOALS_HINT"
	box.add_child(hint)


func open() -> void:
	for child in _list.get_children():
		child.queue_free()
	for id: String in GameData.goals:
		_list.add_child(_row(id))
	visible = true


func _row(id: String) -> Control:
	var done := Goals.is_done(id)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(980, 24)
	var name_label := _label(16, DONE if done else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.text = "%s %s – %s" % ["✓" if done else "·", tr("GOAL_%s_NAME" % id), tr("GOAL_%s_DESC" % id)]
	name_label.custom_minimum_size.x = 600
	row.add_child(name_label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(150, 16)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = Goals.target(id)
	bar.value = mini(Goals.progress(id), Goals.target(id))
	row.add_child(bar)
	var count := _label(15, Color("d9cce6"), HORIZONTAL_ALIGNMENT_RIGHT)
	count.text = "%d/%d" % [mini(Goals.progress(id), Goals.target(id)), Goals.target(id)]
	count.custom_minimum_size.x = 90
	row.add_child(count)
	var reward := _label(15, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	reward.text = "  " + Goals.reward_text(id)
	row.add_child(reward)
	return row


## _input, not _unhandled_input: the panel must see keys before the GUI
## focus of the screen behind it does.
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("goals") or event.is_action_pressed("pause"):
		visible = false
		closed.emit()


func _label(size: int, font_color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 4
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = align
	return label
