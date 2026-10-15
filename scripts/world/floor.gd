extends Node2D
## Endless wooden floor drawn around the camera (placeholder until real tiles).

const PLANK := Vector2(96, 16)
const WOOD := Color("8a5a3b")
const SEAM := Color("5e3b26")
const KNOT := Color("6d4530")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	var half := get_viewport_rect().size / camera.zoom * 0.5 + PLANK
	var row0 := floori((center.y - half.y) / PLANK.y)
	var row1 := floori((center.y + half.y) / PLANK.y)
	for row in range(row0, row1 + 1):
		var shift := fposmod(row * 37.0, PLANK.x)
		var col0 := floori((center.x - half.x - shift) / PLANK.x)
		var col1 := floori((center.x + half.x - shift) / PLANK.x)
		for col in range(col0, col1 + 1):
			var pos := Vector2(col * PLANK.x + shift, row * PLANK.y)
			var h := hash(Vector2i(col, row))
			draw_rect(Rect2(pos, PLANK), WOOD.darkened((h % 9) * 0.015))
			draw_line(pos, pos + Vector2(0, PLANK.y), SEAM, 1.0)
			draw_line(pos + Vector2(0, PLANK.y - 1), pos + Vector2(PLANK.x, PLANK.y - 1), SEAM, 1.0)
			if h % 7 == 0:
				var knot := pos + Vector2(12 + (h >> 4) % 70, PLANK.y * 0.5)
				draw_colored_polygon(Shapes.ellipse(knot, 3, 1.5, 8), KNOT)
