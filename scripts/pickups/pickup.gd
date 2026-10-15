class_name Pickup
extends Node2D
## A collectible lying on the floor. Movement and collection are handled by
## Pickups.

enum Kind { XP, HEART, SARDINE, MAGNET }

const OUTLINE := Color("2b1d14")

var kind := Kind.XP
var value := 1.0
var attracted := false
var speed := 0.0

var _bob := randf() * TAU


func _init() -> void:
	z_index = -1


## Re-tint after merged XP made the kibble more valuable.
func refresh() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	# Only the special pickups bob, so they stand out from the kibble.
	if kind != Kind.XP:
		_bob += delta * 4.0
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.HEART:
			_draw_heart()
		Kind.SARDINE:
			_draw_sardine()
		Kind.MAGNET:
			_draw_magnet()
		_:
			_draw_kibble()


func _draw_kibble() -> void:
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


func _shadow_and_lift() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2(0, 6), 5, 1.5), Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, sin(_bob) * 1.5))


func _draw_heart() -> void:
	_shadow_and_lift()
	var pts := PackedVector2Array([
		Vector2(0, 5), Vector2(-5, 0), Vector2(-5, -2), Vector2(-3, -4),
		Vector2(-1, -4), Vector2(0, -2), Vector2(1, -4), Vector2(3, -4),
		Vector2(5, -2), Vector2(5, 0),
	])
	draw_colored_polygon(pts, Color("e04646"))
	draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	draw_rect(Rect2(-3, -3, 1, 1), Color(1, 1, 1, 0.9))


func _draw_sardine() -> void:
	_shadow_and_lift()
	var body := Shapes.ellipse(Vector2.ZERO, 6, 3)
	var tail := PackedVector2Array([Vector2(-5, 0), Vector2(-9, -3), Vector2(-9, 3)])
	draw_colored_polygon(tail, Color("8fa9b8"))
	draw_colored_polygon(body, Color("b8cfdc"))
	draw_polyline(Shapes.closed(body), OUTLINE, 1.0)
	draw_polyline(Shapes.closed(tail), OUTLINE, 1.0)
	draw_rect(Rect2(3, -1, 1, 1), OUTLINE)


func _draw_magnet() -> void:
	_shadow_and_lift()
	draw_arc(Vector2(0, -1), 4.0, PI, TAU, 10, OUTLINE, 5.0)
	draw_arc(Vector2(0, -1), 4.0, PI, TAU, 10, Color("d94848"), 3.0)
	draw_rect(Rect2(-5.5, -1, 3, 4), OUTLINE)
	draw_rect(Rect2(2.5, -1, 3, 4), OUTLINE)
	draw_rect(Rect2(-5, 0, 2, 2), Color("dddddd"))
	draw_rect(Rect2(3, 0, 2, 2), Color("dddddd"))
