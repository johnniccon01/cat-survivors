class_name NightBar
extends Control
## A thin bar under the run clock: how far the night is, red marks where
## wave bosses come and a gold diamond for the final boss at the end.

var progress := 0.0:
	set(v):
		progress = clampf(v, 0.0, 1.0)
		queue_redraw()
## Boss times as shares of the night (0..1).
var marks: Array[float] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2(-1, -1), Vector2(w + 2, h + 2)), Color(0.04, 0.03, 0.06, 0.9))
	draw_rect(Rect2(Vector2.ZERO, Vector2(w * progress, h)), Color("a493e0"))
	for m in marks:
		var x := roundf(w * m)
		draw_rect(Rect2(Vector2(x - 1, -3), Vector2(2, h + 6)), Color("e9746b") if m > progress else Color("6b5a86"))
	var tip := Vector2(w, h / 2.0)
	var d := 5.0
	var pts := PackedVector2Array([tip + Vector2(0, -d - 1), tip + Vector2(d + 1, 0), tip + Vector2(0, d + 1), tip + Vector2(-d - 1, 0)])
	draw_colored_polygon(pts, Color("0a0710"))
	pts = PackedVector2Array([tip + Vector2(0, -d), tip + Vector2(d, 0), tip + Vector2(0, d), tip + Vector2(-d, 0)])
	draw_colored_polygon(pts, UiStyle.GOLD)
