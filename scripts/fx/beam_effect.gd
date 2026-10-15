class_name BeamEffect
extends Node2D
## A laser beam that flashes and fades, ending in a bright dot.

const DURATION := 0.18

var from := Vector2.ZERO
var to := Vector2.ZERO
var width := 3.0
var color := Color("ff3b3b")

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
	var a := 1.0 - _t / DURATION
	draw_line(from, to, Color(color, 0.35 * a), width * 2.5)
	draw_line(from, to, Color(color, a), width)
	draw_line(from, to, Color(1, 1, 1, a), maxf(width * 0.35, 1.0))
	draw_circle(to, width * 1.3, Color(color, a))
	draw_circle(to, width * 0.6, Color(1, 1, 1, a))
