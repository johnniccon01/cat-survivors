class_name Pickup
extends Node2D
## A collectible lying on the floor: XP kibble or a healing sardine.
## Movement and collection are handled by Pickups.

enum Kind { XP, HEAL }

const OUTLINE := Color("2b1d14")

var kind := Kind.XP
var value := 1.0
var attracted := false
var speed := 0.0


func _init() -> void:
	z_index = -1


## Re-tint after merged XP made the kibble more valuable.
func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if kind == Kind.HEAL:
		_draw_sardine()
		return
	var color := Color("5aa9e6")
	var size := 3.0
	if value >= 10.0:
		color = Color("e05a5a")
		size = 4.5
	elif value >= 3.0:
		color = Color("6cc46c")
		size = 3.5
	var pts := PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])
	draw_colored_polygon(pts, color)
	draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	draw_rect(Rect2(-1, -size + 1, 1, 1), Color(1, 1, 1, 0.8))


func _draw_sardine() -> void:
	var body := Shapes.ellipse(Vector2.ZERO, 6, 3)
	var tail := PackedVector2Array([Vector2(-5, 0), Vector2(-9, -3), Vector2(-9, 3)])
	draw_colored_polygon(tail, Color("8fa9b8"))
	draw_colored_polygon(body, Color("b8cfdc"))
	draw_polyline(Shapes.closed(body), OUTLINE, 1.0)
	draw_polyline(Shapes.closed(tail), OUTLINE, 1.0)
	draw_rect(Rect2(3, -1, 1, 1), OUTLINE)
