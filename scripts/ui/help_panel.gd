class_name HelpPanel
extends ColorRect
## "What the map means": how a night is won, and what every sign on the
## neighbourhood map (defence, hunt, golden night, rescue, trip) and the
## conquest flags ask of you. Any key or click closes it.

signal closed

var _ready_for_input := false


func _ready() -> void:
	color = Color(0.09, 0.055, 0.03, 0.96)
	theme = UiStyle.panel_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	UiStyle.board(self, box)
	box.add_child(UiStyle.label("HELP_TITLE", 34, UiStyle.GOLD))
	# HELP_TEXT: first how a night is won, then one line per sign in this
	# order; each line gets the sign as the map draws it.
	var lines := tr("HELP_TEXT").split("\n")
	var kinds := ["", "defend", "hunt", "gold", "rescue", "trip", "flag", "moon"]
	for i in lines.size():
		var kind: String = kinds[i] if i < kinds.size() else ""
		var text := lines[i]
		# The old text starts the offer lines with their glyph: the icon says it.
		if kind != "" and text.length() > 2 and text[1] == " ":
			text = text.substr(2)
		box.add_child(_row(kind, text, i == 0))
	box.add_child(_row("kidnapped", tr("LEGEND_KIDNAPPED"), false))
	box.add_child(UiStyle.label("NEWS_HINT", 15, UiStyle.MUTED))


## One line of the help: the sign (or a gold bullet) and its text.
func _row(kind: String, text: String, lead: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var icon := SignIcon.new(kind, 11.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if kind == "":
		icon.custom_minimum_size = Vector2(28, 0)
	row.add_child(icon)
	var label := UiStyle.label(text, 17 if lead else 16, UiStyle.GOLD if lead else UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(940, 0)
	row.add_child(label)
	return row


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
