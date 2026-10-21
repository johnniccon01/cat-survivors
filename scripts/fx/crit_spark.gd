class_name CritSpark
extends Node2D
## A small yellow star burst where a critical hit lands.

const DURATION := 0.16
const MAX_ALIVE := 40

static var alive := 0

var _t := 0.0
var _angle := randf() * TAU


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 5


func _enter_tree() -> void:
	alive += 1


func _exit_tree() -> void:
	alive -= 1


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var r := 4.0 + 10.0 * k
	var c := Color(1.0, 0.9, 0.35, 1.0 - k)
	for i in 4:
		var d := Vector2.from_angle(_angle + i * PI * 0.5)
		Blit.line(self, d * r * 0.3, d * r, c, 2.0)
	for i in 4:
		var d := Vector2.from_angle(_angle + PI * 0.25 + i * PI * 0.5)
		Blit.line(self, d * r * 0.2, d * r * 0.6, c, 1.0)
	Blit.disc(self, Vector2.ZERO, 2.5 * (1.0 - k), Color(1, 1, 1, 1.0 - k))
