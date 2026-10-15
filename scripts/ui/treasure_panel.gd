class_name TreasurePanel
extends ColorRect
## Shows what a treasure chest gave. Any key, button or click closes it
## once the items have been revealed.

signal closed

const REVEAL_STEP := 0.25
const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _title: Label
var _list: VBoxContainer
var _hint: Label
var _ready_for_input := false


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.75)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	_title = _label(48, GOLD)
	_title.text = "TREASURE_TITLE"
	box.add_child(_title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	box.add_child(_list)
	_hint = _label(20, Color("b9a8c9"))
	_hint.text = "TREASURE_HINT"
	box.add_child(_hint)


func open(results: Array[Dictionary]) -> void:
	for child in _list.get_children():
		child.queue_free()
	_hint.modulate.a = 0.0
	_ready_for_input = false
	visible = true
	for offer in results:
		await get_tree().create_timer(REVEAL_STEP, true).timeout
		var line := _label(26, GOLD if offer.get("evolved", false) else Color.WHITE)
		if offer.get("evolved", false):
			line.text = "%s  %s" % [tr("TREASURE_EVOLVED"), Upgrades.title(offer)]
		elif offer["kind"] == "heal":
			line.text = Upgrades.title(offer)
		else:
			line.text = "%s → %d" % [Upgrades.title(offer), offer["level"]]
		_list.add_child(line)
	await get_tree().create_timer(REVEAL_STEP, true).timeout
	_hint.modulate.a = 1.0
	_ready_for_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _ready_for_input:
		return
	var pressed := (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) \
		and event.is_pressed() and not event.is_echo()
	if pressed:
		get_viewport().set_input_as_handled()
		visible = false
		_ready_for_input = false
		closed.emit()


func _label(size: int, font_color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 5
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
