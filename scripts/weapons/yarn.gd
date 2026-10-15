extends Weapon
## Klbko vlny: thrown at the nearest enemy (like the Magic Wand).

const RANGE := 320.0
const BASE_RADIUS := 4.0


func shoot(_index: int) -> void:
	var target := enemies.nearest(player.position, RANGE)
	var dir := Vector2.from_angle(randf() * TAU)
	if target != null:
		dir = (target.position - player.position).normalized()
	var p := Projectile.new()
	p.enemies = enemies
	p.style = "yarn"
	p.position = player.position + Vector2(0, -4)
	p.velocity = dir * proj_speed()
	p.damage = damage()
	p.knockback = stat("knockback", 0.5)
	p.pierce = int(stat("pierce", 1.0))
	p.radius = BASE_RADIUS * area()
	p.lifetime = duration()
	world.add_child(p)
