class_name Poof
extends Node2D
## Little dust cloud left behind when an enemy dies.

const DURATION := 0.3

var color := Color(0.92, 0.9, 0.86)

var _t := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 4


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	for i in 5:
		var dir := Vector2.from_angle(TAU * i / 5.0)
		draw_circle(dir * (3.0 + 10.0 * k), 3.0 * (1.0 - k), Color(color, 1.0 - k))
