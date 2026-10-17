class_name DeathFx
extends Node2D
## A defeated enemy's last moment: its sprite squashes flat, hops up, turns
## white and fades away. At most MAX_ALIVE play at once so big crowds stay
## cheap; the rest just get the dust poof.

const DURATION := 0.28
const MAX_ALIVE := 60

static var alive := 0

var sprite: Dictionary
var frame := 0
var facing := 1.0
var size := 1.0
var tint := Color.WHITE

var _t := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 3


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
	if sprite.is_empty():
		return
	var k := _t / DURATION
	# Squash, then a little hop with a spin, fading to white.
	var squash := Vector2(1.0 + 0.4 * (1.0 - k), 1.0 - 0.55 * minf(k * 2.0, 1.0)) * size
	var hop := -sin(k * PI) * 6.0
	draw_set_transform(Vector2(0, hop), k * 0.6 * facing, Vector2(facing * squash.x, squash.y))
	var c := tint.lerp(Color(3, 3, 3), k)
	c.a = 1.0 - k
	Sprites.draw_frame(self, sprite, frame, 1 if k > 0.5 else 0, c)
	draw_set_transform(Vector2.ZERO)
