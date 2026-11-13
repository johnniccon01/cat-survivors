class_name NightBar
extends Control
## A thin bar under the run clock: how far the night is, red marks where
## wave bosses come and a gold diamond for the final boss at the end. A dark
## trough with a cream edge; redrawn only when the fill moves a whole pixel.

var progress := 0.0:
	set(v):
		v = clampf(v, 0.0, 1.0)
		var px := roundi(v * size.x)
		if px != _px:
			_px = px
			queue_redraw()
		progress = v
## Boss times as shares of the night (0..1).
var marks: Array[float] = []:
	set(v):
		marks = v
		queue_redraw()

var _px := -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2(-2, -2), Vector2(w + 4, h + 4)), BoxStyle.CREAM)
	draw_rect(Rect2(Vector2(-1, -1), Vector2(w + 2, h + 2)), BoxStyle.DARK)
	draw_rect(Rect2(Vector2.ZERO, Vector2(w * progress, h)), Color("8fb4f0"))
	for m in marks:
		var x := roundf(w * m)
		draw_rect(Rect2(Vector2(x - 2, -4), Vector2(4, h + 8)), BoxStyle.DARK)
		draw_rect(Rect2(Vector2(x - 1, -3), Vector2(2, h + 6)), Color("ff6a5c") if m > progress else Color("8d849c"))
	var tip := Vector2(w, h / 2.0)
	var d := 6.0
	var pts := PackedVector2Array([tip + Vector2(0, -d - 1.5), tip + Vector2(d + 1.5, 0), tip + Vector2(0, d + 1.5), tip + Vector2(-d - 1.5, 0)])
	draw_colored_polygon(pts, BoxStyle.DARK)
	pts = PackedVector2Array([tip + Vector2(0, -d), tip + Vector2(d, 0), tip + Vector2(0, d), tip + Vector2(-d, 0)])
	draw_colored_polygon(pts, UiStyle.GOLD)
