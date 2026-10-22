class_name DroneFx
extends Node2D
## The look of one helper drone: a small body with four spinning rotors.

const OUTLINE := Color("2b1d14")

var _t := randf() * 10.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for d: Vector2 in [Vector2(-6, -4), Vector2(6, -4), Vector2(-6, 4), Vector2(6, 4)]:
		Blit.line(self, Vector2.ZERO, d, OUTLINE, 1.5)
		var spin := sin(_t * 40.0 + d.x)
		draw_line(d + Vector2(-3.0 * spin, -1), d + Vector2(3.0 * spin, 1), Color(0.85, 0.9, 1.0, 0.8), 1.5)
	Blit.disc(self, Vector2.ZERO, 4.5, OUTLINE)
	Blit.disc(self, Vector2.ZERO, 3.5, Color("3a3e44"))
	Blit.disc(self, Vector2(0, 1), 1.3, Color("5ad1e6") if fmod(_t, 1.0) < 0.8 else Color("e04646"))
