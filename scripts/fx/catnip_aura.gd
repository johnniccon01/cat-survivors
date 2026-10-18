class_name CatnipAura
extends Node2D
## Visual for the Šanta aura: a soft green circle with drifting leaves that
## flashes brighter on every damage tick.

var player: Player
var radius := 32.0

var _t := 0.0
var _pulse := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -2


func pulse() -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	_t += delta
	_pulse = maxf(_pulse - delta * 4.0, 0.0)
	if is_instance_valid(player):
		position = player.position
	queue_redraw()


func _draw() -> void:
	var alpha := 0.07 + _pulse * 0.12
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.85, 0.4, alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.55, 0.95, 0.5, 0.35 + _pulse * 0.4), 1.0)
	for i in 6:
		var a := _t * 0.6 + TAU * i / 6.0
		var p := Vector2.from_angle(a) * radius * (0.55 + 0.3 * sin(_t * 1.3 + i))
		var leaf := PackedVector2Array([p + Vector2(-2, 0).rotated(a), p + Vector2(0, -1.5).rotated(a), p + Vector2(2, 0).rotated(a), p + Vector2(0, 1.5).rotated(a)])
		draw_colored_polygon(leaf, Color(0.4, 0.8, 0.35, 0.7))
