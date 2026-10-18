class_name EnemyBullet
extends Node2D
## A laser dot spat by a rival cat. Hurts the player on contact.

const HIT_DIST := 7.0

var velocity := Vector2.ZERO
var damage := 6.0
var lifetime := 3.0
var player: Player
## "laser" (red dot), "hair" (hairball) or "spit" (green blob).
var style := "laser"

var _t := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 4


func _physics_process(delta: float) -> void:
	_t += delta
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(player):
		queue_free()
		return
	position += velocity * delta
	if position.distance_to(player.position) < HIT_DIST:
		player.take_damage(damage)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if style == "spit":
		draw_circle(Vector2.ZERO, 5.5, Color("2b1d14"))
		draw_circle(Vector2.ZERO, 4.2, Color("8fd04a"))
		draw_circle(Vector2(-1, -1), 1.0, Color("d8f0a0"))
		return
	if style == "hair":
		draw_circle(Vector2.ZERO, 5.5, Color("2b1d14"))
		draw_circle(Vector2.ZERO, 4.2, Color("8a6a4a"))
		draw_line(Vector2(-2, -1), Vector2(2, 1), Color("b8956a"), 1.0)
		return
	var pulse := 1.0 + sin(_t * 20.0) * 0.2
	draw_circle(Vector2.ZERO, 6.5 * pulse, Color(1.0, 0.15, 0.15, 0.3))
	draw_circle(Vector2.ZERO, 4.0, Color("2b1d14"))
	draw_circle(Vector2.ZERO, 3.0, Color("ff3b3b"))
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)
