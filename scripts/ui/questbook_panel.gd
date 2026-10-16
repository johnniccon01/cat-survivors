class_name QuestBookPanel
extends ColorRect
## The quest book screen: every quest line by chapter with its current step,
## progress and reward. Arrows or the mouse wheel scroll, Q / Esc closes.

signal closed

const GOLD := Color("f2c14e")
const DONE := Color("6cd48a")
const MUTED := Color("8f7ea3")
const OUTLINE := Color("2b1d14")
const LIST_HEIGHT := 540.0
const SCROLL_STEP := 54

var _list: VBoxContainer
var _scroll: ScrollContainer


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
	title.text = "QB_TITLE"
	box.add_child(title)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(1100, LIST_HEIGHT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)
	var hint := _label(16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint.text = "QB_HINT"
	box.add_child(hint)


func open() -> void:
	for child in _list.get_children():
		child.queue_free()
	for chapter: String in GameData.questbook.get("chapters", []):
		var head := _label(22, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		head.text = tr("QB_CHAPTER_%s" % chapter.to_upper())
		_list.add_child(head)
		for id: String in QuestBook.lines():
			if QuestBook.lines()[id]["chapter"] == chapter:
				_list.add_child(_row(id))
	_scroll.scroll_vertical = 0
	visible = true


func _row(id: String) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var top := HBoxContainer.new()
	row.add_child(top)
	var done := QuestBook.is_complete(id)
	var n := QuestBook.step_count(id)
	var name_label := _label(18, DONE if done else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.custom_minimum_size.x = 640
	top.add_child(name_label)
	var dots := _label(16, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	dots.custom_minimum_size.x = 120
	top.add_child(dots)
	var count := _label(15, Color("d9cce6"), HORIZONTAL_ALIGNMENT_RIGHT)
	count.custom_minimum_size.x = 110
	top.add_child(count)
	var reward := _label(15, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	top.add_child(reward)
	var desc := _label(15, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	row.add_child(desc)

	if QuestBook.is_hidden(id):
		name_label.text = "  ???"
		desc.text = "      " + tr("QB_SECRET")
		return row
	var steps := QuestBook.steps_done(id)
	name_label.text = "%s %s" % ["✓" if done else "·", tr("QB_%s_NAME" % id)]
	dots.text = "●".repeat(steps) + "○".repeat(n - steps)
	if done:
		desc.text = "      " + tr("QB_DONE")
		return row
	var step := QuestBook.current(id)
	var have := mini(QuestBook.progress(step), QuestBook.target(step))
	count.text = "%d/%d" % [have, QuestBook.target(step)]
	reward.text = "  " + QuestBook.reward_text(step["reward"])
	desc.text = "      %s  %s" % [tr("QB_STEP") % [steps + 1, n], tr("QB_%s_%d" % [id, steps + 1])]
	return row


## _input, not _unhandled_input: the panel must see keys before the GUI
## focus of the screen behind it does.
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed():
		return
	if event.is_action_pressed("move_down", true) or event.is_action_pressed("ui_down", true):
		_scroll.scroll_vertical += SCROLL_STEP
		return
	if event.is_action_pressed("move_up", true) or event.is_action_pressed("ui_up", true):
		_scroll.scroll_vertical -= SCROLL_STEP
		return
	if event.is_echo():
		return
	if event.is_action_pressed("questbook") or event.is_action_pressed("pause"):
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
