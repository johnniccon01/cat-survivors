class_name Hud
extends CanvasLayer
## Run clock, kill counter, pause and game-over overlays. Built in code for
## now; will move to a proper scene once the UI grows.

var _time_label: Label
var _kills_label: Label
var _debug_label: Label
var _pause_overlay: Control
var _over_overlay: Control
var _over_stats: Label


func _ready() -> void:
	_time_label = _label(32, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_time_label.offset_top = 8
	add_child(_time_label)

	_kills_label = _label(22, HORIZONTAL_ALIGNMENT_RIGHT)
	_kills_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_kills_label.offset_top = 14
	_kills_label.offset_right = -20
	add_child(_kills_label)

	_debug_label = _label(14, HORIZONTAL_ALIGNMENT_LEFT)
	_debug_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_debug_label.offset_left = 10
	_debug_label.offset_top = -28
	_debug_label.visible = OS.is_debug_build()
	add_child(_debug_label)

	_pause_overlay = _overlay(["PAUZA", "Esc – pokračovať"])
	_over_overlay = _overlay(["Mica to zabalila!", "", "R / Enter – skúsiť znova"])
	_over_stats = _over_overlay.get_node("Box").get_child(1)


func update_stats(elapsed: float, kills: int, enemy_count: int) -> void:
	_time_label.text = _format_time(elapsed)
	_kills_label.text = "Porazení: %d" % kills
	if _debug_label.visible:
		_debug_label.text = "FPS %d · nepriatelia %d" % [Engine.get_frames_per_second(), enemy_count]


func show_pause(on: bool) -> void:
	_pause_overlay.visible = on


func show_game_over(elapsed: float, kills: int) -> void:
	_over_stats.text = "Prežila si %s a porazila %d nepriateľov." % [_format_time(elapsed), kills]
	_over_overlay.visible = true


func _format_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [floori(s / 60.0), s % 60]


func _label(size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.outline_size = maxi(size / 4, 4)
	settings.outline_color = Color("2b1d14")
	label.label_settings = settings
	label.horizontal_alignment = align
	return label


func _overlay(lines: Array[String]) -> Control:
	var root := ColorRect.new()
	root.color = Color(0.08, 0.05, 0.1, 0.6)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	for i in lines.size():
		var label := _label(48 if i == 0 else 24, HORIZONTAL_ALIGNMENT_CENTER)
		label.text = lines[i]
		box.add_child(label)
	root.add_child(box)
	add_child(root)
	return root
