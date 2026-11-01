class_name HelpPanel
extends ColorRect
## "What the map means": how a night is won, and what every sign on the
## neighbourhood map (defence, hunt, golden night, rescue, trip) and the
## conquest flags ask of you. Any key or click closes it.

signal closed

var _ready_for_input := false


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	UiStyle.board(self, box)
	box.add_child(UiStyle.label("HELP_TITLE", 34, UiStyle.GOLD))
	var text := UiStyle.label("HELP_TEXT", 16, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(980, 0)
	text.label_settings.line_spacing = 4
	box.add_child(text)
	box.add_child(UiStyle.label("NEWS_HINT", 15, UiStyle.MUTED))


func open() -> void:
	visible = true
	_ready_for_input = false
	# Ignore the key or click that opened it.
	await get_tree().create_timer(0.25).timeout
	_ready_for_input = true


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if _ready_for_input and event.is_pressed() and not event.is_echo():
			visible = false
			closed.emit()
