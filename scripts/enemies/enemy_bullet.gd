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
	# Above enemies, pickups and effects: a shot coming at you is never hidden.
	z_index = 8


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
	# Every shot gets a bright rim and a short tail along its flight, so it
	# stands out from a crowd of enemies and you can see where it's going.
	var rim := Color(1, 1, 1, 0.95 if Settings.high_contrast else 0.75)
	if velocity != Vector2.ZERO:
		var back := -velocity.normalized()
		for k in 3:
			Blit.disc(self, back * (5.0 + k * 4.0), 3.5 - k, Color(1.0, 0.9, 0.8, 0.35 - k * 0.1))
	Blit.ring(self, Vector2.ZERO, 8.25, 1.5, rim)
	if style == "spit":
		Blit.disc(self, Vector2.ZERO, 5.5, Color("2b1d14"))
		Blit.disc(self, Vector2.ZERO, 4.2, Color("8fd04a"))
		Blit.disc(self, Vector2(-1, -1), 1.0, Color("d8f0a0"))
		return
	if style == "hair":
		Blit.disc(self, Vector2.ZERO, 5.5, Color("2b1d14"))
		Blit.disc(self, Vector2.ZERO, 4.2, Color("8a6a4a"))
		Blit.line(self, Vector2(-2, -1), Vector2(2, 1), Color("b8956a"), 1.0)
		return
	var pulse := 1.0 + sin(_t * 20.0) * 0.2
	Blit.disc(self, Vector2.ZERO, 6.5 * pulse, Color(1.0, 0.15, 0.15, 0.3))
	Blit.disc(self, Vector2.ZERO, 4.0, Color("2b1d14"))
	Blit.disc(self, Vector2.ZERO, 3.0, Color("ff3b3b"))
	Blit.disc(self, Vector2.ZERO, 1.0, Color.WHITE)
