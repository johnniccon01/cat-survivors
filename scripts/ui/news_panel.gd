class_name NewsPanel
extends ColorRect
## "What's new": shown once in the main menu after an update (the flag
## "news:<VERSION>" remembers it). Any key or click closes it.

signal closed

const VERSION := 10

var _ready_for_input := false


## True when this version's news hasn't been shown yet (never in tests).
static func should_show() -> bool:
	return not GameData.no_save() and not Profile.has_flag("news:%d" % VERSION)


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.94)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	box.add_child(UiStyle.label("NEWS_TITLE", 40, UiStyle.GOLD))
	var text := UiStyle.label("NEWS_TEXT", 19, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(900, 0)
	box.add_child(text)
	box.add_child(UiStyle.label("NEWS_HINT", 17, UiStyle.MUTED))


func open() -> void:
	visible = true
	Profile.set_flag("news:%d" % VERSION)
	# Ignore the key that may still be held from starting the game.
	await get_tree().create_timer(0.4).timeout
	_ready_for_input = true


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if _ready_for_input and event.is_pressed() and not event.is_echo():
			visible = false
			closed.emit()
