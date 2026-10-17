class_name ChampionBomb
extends Node2D
## Left behind by a defeated Bomber champion: a red ring shrinks for a moment
## (time to step away), then it blows up and hurts the cat if it is close.

const FUSE := 0.8
const RADIUS := 46.0

var player: Player
var damage := 10.0

var _t := 0.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 4


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= FUSE:
		if is_instance_valid(player) and player.position.distance_to(position) < RADIUS:
			player.take_damage(damage)
		Audio.play("break", -6.0)
		var ring := RingWave.new()
		ring.enemies = get_tree().get_first_node_in_group("enemy_manager")
		ring.position = position
		ring.max_radius = RADIUS
		ring.expand_time = 0.15
		ring.damage = 0.0
		ring.knockback = 0.0
		ring.color = Color("e04646")
		get_parent().add_child(ring)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / FUSE
	draw_circle(Vector2.ZERO, RADIUS, Color(0.9, 0.15, 0.1, 0.10 + 0.15 * k))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(1.0, 0.3, 0.2, 0.9), 1.5)
	draw_arc(Vector2.ZERO, RADIUS * (1.0 - k), 0.0, TAU, 24, Color(1.0, 0.8, 0.3, 0.9), 2.0)
