class_name ChainBolt
extends Node2D
## A short-lived jagged lightning line through `points` (world positions).

const LIFE := 0.18

var points := PackedVector2Array()
var color := Color("9ae0ff")

var _age := 0.0
var _jagged := PackedVector2Array()


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 6


func _ready() -> void:
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var side := (b - a).orthogonal().normalized()
		_jagged.append(a)
		for k in range(1, 5):
			_jagged.append(a.lerp(b, k / 5.0) + side * randf_range(-6.0, 6.0))
	_jagged.append(points[points.size() - 1])


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - _age / LIFE
	draw_polyline(_jagged, Color(color, 0.35 * a), 5.0)
	draw_polyline(_jagged, Color(color, a), 2.0)
	draw_polyline(_jagged, Color(1, 1, 1, a), 1.0)
	for p in points:
		Blit.disc(self, p, 3.0, Color(1, 1, 1, 0.8 * a))
