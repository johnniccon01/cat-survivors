extends Weapon
## Udica: casts a hook at an enemy and reels it in – it lands at the cat's
## feet, ready for the claws. Evolved (Golden Rod) the hooks go through.

const RANGE := 280.0
const BASE_RADIUS := 5.0


func shoot(index: int) -> void:
	Audio.play("throw", -12.0 - (6.0 if player.is_companion() else 0.0))
	var target := enemies.nearest(player.position, RANGE)
	var dir := Vector2(player.facing, 0)
	if target != null:
		dir = (target.position - player.position).normalized()
	dir = dir.rotated((index - (amount() - 1) * 0.5) * 0.4)
	var p := Projectile.new()
	p.source = self
	p.enemies = enemies
	p.style = "hook" if not data.get("golden", false) else "golden_hook"
	p.position = player.position + Vector2(0, -4)
	p.velocity = dir * 320.0 * proj_speed()
	p.damage = damage()
	# Negative knockback: the hook pulls the enemy towards the cat.
	p.knockback = -stat("knockback", 1.6)
	p.pierce = int(stat("pierce", 1.0))
	p.radius = BASE_RADIUS * area()
	p.lifetime = duration()
	world.add_child(p)
