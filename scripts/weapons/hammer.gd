extends Weapon
## Pískacie kladivko: a squeaky toy hammer slams down on the nearest crowd,
## hitting everything under it and stunning it for a moment. Quake Hammer
## slams several spots and each slam sends a quake ring out.

const RANGE := 220.0
const BASE_RADIUS := 42.0
const STUN := 0.6


func shoot(index: int) -> void:
	var near := enemies.query_radius(player.position, RANGE)
	if near.is_empty():
		return
	var at: Vector2 = near[(index * 7) % near.size()].position
	Audio.play("squeak", -6.0 - (6.0 if player.is_companion() else 0.0))
	var slam := _Slam.new()
	slam.position = at
	slam.radius = BASE_RADIUS * area()
	slam.weapon = self
	slam.quake = data.get("quake", false)
	world.add_child(slam)


## Lands after a short drop: hits, stuns, and (Quake Hammer) rings out.
func land(at: Vector2, radius: float, quake: bool) -> void:
	var stun := stat("stun", STUN) * player.stat("duration")
	for enemy in enemies.query_radius(at, radius):
		strike(enemy, damage(), enemy.position - at, stat("knockback", 0.6))
		if not enemy.dead and not enemy.is_prop:
			enemy.slow_down(0.0, stun * (0.5 if enemy.is_boss else 1.0))
	player.shake(1.5, 0.12)
	if quake:
		var ring := RingWave.new()
		ring.source = self
		ring.enemies = enemies
		ring.position = at
		ring.max_radius = radius * 2.2
		ring.expand_time = 0.3
		ring.damage = damage() * 0.5
		ring.knockback = 1.2
		ring.color = Color("c9a26a")
		world.add_child(ring)


## The hammer dropping onto its spot, then the dust and cracks of the slam.
class _Slam extends Node2D:
	const DROP := 0.18
	const FADE := 0.4
	var radius := 40.0
	var weapon: Weapon
	var quake := false
	var _t := 0.0
	var _landed := false

	func _init() -> void:
		process_mode = Node.PROCESS_MODE_PAUSABLE
		z_index = 4

	func _process(delta: float) -> void:
		_t += delta
		if not _landed and _t >= DROP:
			_landed = true
			if is_instance_valid(weapon):
				weapon.land(position, radius, quake)
		if _t >= DROP + FADE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		if not _landed:
			var k := _t / DROP
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(1, 0.4, 0.3, 0.5 * k), 2.0)
			_hammer(Vector2(0, lerpf(-70.0, -8.0, k * k)), lerpf(-0.9, 0.0, k))
			return
		var f := (_t - DROP) / FADE
		draw_circle(Vector2.ZERO, radius * (0.6 + 0.4 * f), Color(1.0, 0.9, 0.6, 0.35 * (1.0 - f)))
		draw_arc(Vector2.ZERO, radius * (0.8 + 0.4 * f), 0.0, TAU, 28, Color(0.75, 0.55, 0.3, 1.0 - f), 3.0)
		for i in 6:
			var d := Vector2.from_angle(TAU * i / 6.0 + 0.4)
			draw_line(d * radius * 0.3, d * radius * (0.6 + 0.5 * f), Color(0.45, 0.3, 0.2, 1.0 - f), 1.5)
		if f < 0.5:
			_hammer(Vector2(0, -8), 0.0)

	func _hammer(at: Vector2, tilt: float) -> void:
		draw_set_transform(at, tilt)
		draw_rect(Rect2(-2, -26, 4, 22), Color("2b1d14"))
		draw_rect(Rect2(-1, -25, 2, 20), Color("e8c37a"))
		draw_rect(Rect2(-12, -6, 24, 12), Color("2b1d14"))
		draw_rect(Rect2(-11, -5, 22, 10), Color("e0628f"))
		draw_rect(Rect2(-11, -5, 22, 3), Color("f28ac0"))
		draw_rect(Rect2(-11, -5, 4, 10), Color("ffd84a"))
		draw_rect(Rect2(7, -5, 4, 10), Color("ffd84a"))
		draw_set_transform(Vector2.ZERO)
