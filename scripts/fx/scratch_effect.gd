class_name ScratchEffect
extends Node2D
## Three claw marks that sweep across the hit area and fade out.

const DURATION := 0.2

var size := Vector2(56, 20)
var side := 1

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
	for i in 3:
		var y := (i - 1) * size.y * 0.3
		var pts := PackedVector2Array()
		for s in 9:
			var u := float(s) / 8.0 * reveal
			var x := lerpf(-size.x * 0.5, size.x * 0.5, u) * side
			pts.append(Vector2(x, y - sin(u * PI) * size.y * 0.25))
		draw_polyline(pts, Color(1.0, 0.55, 0.65, alpha * 0.5), 4.0)
		draw_polyline(pts, Color(1, 1, 1, alpha), 2.0)
