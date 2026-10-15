extends Weapon
## Rozliate mlieko: splashes a puddle under a random enemy on screen; the
## puddle hurts everything standing in it for `duration` seconds
## (like Santa Water).

const RANGE := 220.0
const BASE_RADIUS := 22.0
const TICK := 0.35


func shoot(_index: int) -> void:
	var pos := player.position + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 90.0)
	var targets := enemies.query_radius(player.position, RANGE)
	if not targets.is_empty():
		pos = targets.pick_random().position
	var puddle := MilkPuddle.new()
	puddle.enemies = enemies
	puddle.position = pos
	puddle.radius = BASE_RADIUS * area()
	puddle.damage = damage()
	puddle.tick = TICK
	puddle.lifetime = duration()
	world.add_child(puddle)
