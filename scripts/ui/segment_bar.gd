class_name SegmentBar
extends Control
## A row of small segments: `filled` gold ones, the rest empty (levels of an
## upgrade, steps of a story). See UiStyle.segments.

var count := 5:
	set(v):
		count = v
		_resize()
var filled := 0:
	set(v):
		filled = v
		queue_redraw()
var seg_width := 16.0:
	set(v):
		seg_width = v
		_resize()
var seg_height := 6.0:
	set(v):
		seg_height = v
		_resize()
var gap := 3.0
var on_color := BoxStyle.RED
var off_color := UiStyle.SEG_EMPTY


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _resize() -> void:
	custom_minimum_size = Vector2(maxf(count * (seg_width + gap) - gap, 0.0), seg_height)
	queue_redraw()


func _draw() -> void:
	# Marker strokes: a short thick line per step, a little crooked.
	for i in count:
		var x := i * (seg_width + gap)
		var tilt := (float(i % 3) - 1.0) * 0.6
		var col := on_color if i < filled else off_color
		var r := seg_height * 0.5
		draw_line(Vector2(x + r, seg_height * 0.5 - tilt), Vector2(x + seg_width - r, seg_height * 0.5 + tilt), col, seg_height + 1.0, true)
		draw_circle(Vector2(x + r, seg_height * 0.5 - tilt), r + 0.5, col)
		draw_circle(Vector2(x + seg_width - r, seg_height * 0.5 + tilt), r + 0.5, col)
