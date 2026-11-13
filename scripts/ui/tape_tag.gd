class_name TapeTag
extends Control
## A small badge: ink text on a strip of coloured paper tape, a little crooked.
## Used for the labels on the place picture (new map, your territory...).

var text := ""
var tape := BoxStyle.TAPE
var font_size := 15
var look_seed := 5
var tilt := -2.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_tag(text_: String, tape_: Color, max_w: float = 236.0, size_: int = 15) -> void:
	text = text_
	tape = tape_
	var font := BoxStyle.head_font()
	var fs := BoxStyle.fit_size(text, font, size_, max_w, 11)
	font_size = fs
	custom_minimum_size = Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28.0, fs * 1.75)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	rotation_degrees = tilt
	queue_redraw()


func _draw() -> void:
	BoxStyle.draw_tape(self, size, look_seed, tape)
	var font := BoxStyle.head_font()
	var y := size.y * 0.5 + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(14, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BoxStyle.INK)
