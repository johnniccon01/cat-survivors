extends Weapon
## Ihla s niťou: a needle shoots at the nearest enemy and goes through every
## enemy on its way. Evolved (Embroidery) it shoots in four directions.

const BASE_RADIUS := 3.0


func shoot(index: int) -> void:
	Audio.play("throw", -14.0 - (6.0 if player.is_companion() else 0.0))
	# At the nearest enemy; with none around, the way the cat runs.
	var target := enemies.nearest(player.position, 360.0)
	var dir := player.velocity.normalized() if player.velocity.length() > 5.0 else Vector2(player.facing, 0)
	if target != null:
		dir = (target.position - player.position).normalized()
	if data.get("embroidery", false):
		dir = dir.rotated(index % 4 * PI * 0.5)
	else:
		dir = dir.rotated((index - (amount() - 1) * 0.5) * 0.12)
	var p := Projectile.new()
	p.source = self
	p.enemies = enemies
	p.style = "needle"
	p.position = player.position + Vector2(0, -4)
	p.velocity = dir * 520.0 * proj_speed()
	p.rotation = dir.angle()
	p.damage = damage()
	p.knockback = stat("knockback", 0.2)
	p.pierce = -1
	p.radius = BASE_RADIUS * area()
	p.lifetime = duration()
	world.add_child(p)


func shots() -> int:
	return amount() * (4 if data.get("embroidery", false) else 1)
