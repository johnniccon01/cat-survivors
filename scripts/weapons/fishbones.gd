extends Weapon
## Rybie kosti: fish bones circle the cat for `duration` seconds, then
## vanish until the next cast (like King Bible).

const BASE_ORBIT := 40.0
const BASE_ANGULAR := 3.0
const BASE_RADIUS := 6.0


func shots() -> int:
	return 1


func shoot(_index: int) -> void:
	var count := amount()
	for i in count:
		var bone := OrbitProjectile.new()
		bone.player = player
		bone.enemies = enemies
		bone.angle = TAU * i / count
		bone.orbit_radius = BASE_ORBIT * area()
		bone.angular_speed = BASE_ANGULAR * proj_speed()
		bone.radius = BASE_RADIUS * area()
		bone.damage = damage()
		bone.knockback = stat("knockback", 0.8)
		bone.lifetime = duration()
		world.add_child(bone)
