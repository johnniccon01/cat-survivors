extends Weapon
## Labka: the cat stamps its paw and a short, heavy shockwave knocks the
## crowd back. Evolved (Quake Paw) it stamps twice and stuns for a moment.

const BASE_RADIUS := 60.0


func shoot(index: int) -> void:
	Audio.play("hit", -8.0 - (6.0 if player.is_companion() else 0.0), 0.0)
	var wave := RingWave.new()
	wave.source = self
	wave.enemies = enemies
	wave.position = player.position
	wave.max_radius = BASE_RADIUS * area() * (1.0 + index * 0.4)
	wave.expand_time = 0.3
	wave.damage = damage()
	wave.knockback = stat("knockback", 2.5)
	wave.color = Color("c89a6a") if not data.get("quake", false) else Color("f2c14e")
	world.add_child(wave)
	if data.get("quake", false):
		for e in enemies.query_radius(player.position, wave.max_radius):
			e.slow_down(0.3, 0.8)
	player.shake(1.5, 0.12)
