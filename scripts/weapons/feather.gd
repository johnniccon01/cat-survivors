extends Weapon
## Pierková hračka: a feather toy thrown towards the nearest enemy that
## flies back to the cat like a boomerang, hitting enemies on both passes.

const RANGE := 300.0
const LAUNCH_SPEED := 230.0
const RETURN_ACCEL := 330.0
const BASE_RADIUS := 6.0


func shoot(index: int) -> void:
	var target := enemies.nearest(player.position, RANGE)
	var dir := Vector2(player.facing, 0)
	if target != null:
		dir = (target.position - player.position).normalized()
	# Extra feathers fan out around the main direction.
	dir = dir.rotated((index - (amount() - 1) * 0.5) * 0.35)
	var p := Projectile.new()
	p.enemies = enemies
	p.style = "phoenix" if data.get("fire", false) else "feather"
	p.position = player.position + Vector2(0, -4)
	p.velocity = dir * LAUNCH_SPEED * proj_speed()
	p.return_to = player
	p.return_accel = RETURN_ACCEL * proj_speed()
	p.spin = 12.0
	p.damage = damage()
	p.knockback = stat("knockback", 0.6)
	p.pierce = -1
	p.radius = BASE_RADIUS * area()
	p.lifetime = duration()
	world.add_child(p)
