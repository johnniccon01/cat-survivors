extends Weapon
## Chlpáč: a hairball lobbed upwards that falls in an arc (like the Axe).

const LAUNCH_SPEED := 230.0
const GRAVITY := 420.0
const BASE_RADIUS := 6.0


func shoot(index: int) -> void:
	Audio.play("hairball", -10.0 - (6.0 if player.is_companion() else 0.0))
	# Spread consecutive shots to alternating sides, leaning towards the facing.
	var spread := (index + 1) * 25.0 * (1 if index % 2 == 0 else -1)
	var p := Projectile.new()
	p.enemies = enemies
	p.style = "hairball"
	p.position = player.position + Vector2(0, -6)
	p.velocity = Vector2(player.facing * 30.0 + spread + randf_range(-15, 15), -LAUNCH_SPEED) * proj_speed()
	p.gravity = GRAVITY * proj_speed()
	p.spin = 10.0 * player.facing
	p.damage = damage()
	p.knockback = stat("knockback", 1.0)
	p.pierce = int(stat("pierce", 3.0))
	p.radius = BASE_RADIUS * area()
	p.lifetime = duration()
	world.add_child(p)
