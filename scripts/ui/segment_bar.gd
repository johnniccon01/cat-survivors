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
var on_color := UiStyle.GOLD
var off_color := UiStyle.SEG_EMPTY


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _resize() -> void:
	custom_minimum_size = Vector2(maxf(count * (seg_width + gap) - gap, 0.0), seg_height)
	queue_redraw()


func _draw() -> void:
	for i in count:
		var r := Rect2(Vector2(i * (seg_width + gap), 0), Vector2(seg_width, seg_height))
		draw_rect(r, on_color if i < filled else off_color)
