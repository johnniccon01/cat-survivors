class_name ScratchEffect
extends Node2D
## A swoosh with three claw marks that sweep across the hit area and fade
## out. `color` tints the glow (evolved claws burn orange).

const DURATION := 0.26

var size := Vector2(56, 20)
var side := 1
var color := Color(1.0, 0.55, 0.65)

var _t := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var alpha := 1.0 - k
	var reveal := minf(0.25 + k * 4.0, 1.0)
	# The swoosh: a crescent behind the claws.
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for s in 13:
		var u := float(s) / 12.0 * reveal
		var x := lerpf(-size.x * 0.55, size.x * 0.55, u) * side
		outer.append(Vector2(x, -sin(u * PI) * size.y * 0.75 - size.y * 0.1))
		inner.append(Vector2(x, -sin(u * PI) * size.y * 0.25 + size.y * 0.15))
	inner.reverse()
	draw_colored_polygon(outer + inner, Color(color, 0.22 * alpha))
	for i in 3:
		var y := (i - 1) * size.y * 0.3
		var pts := PackedVector2Array()
		for s in 9:
			var u := float(s) / 8.0 * reveal
			var x := lerpf(-size.x * 0.5, size.x * 0.5, u) * side
			pts.append(Vector2(x, y - sin(u * PI) * size.y * 0.25))
		draw_polyline(pts, Color(color, alpha * 0.5), 7.0)
		draw_polyline(pts, Color(1, 1, 1, alpha), 3.0)
		if reveal >= 1.0:
			Blit.disc(self, pts[pts.size() - 1], 3.0 * alpha, Color(1, 1, 1, alpha))
