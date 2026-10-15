extends Weapon
## Zvonček: rings a bell that sends a shockwave outwards from the cat,
## hitting every enemy once and knocking it back hard.

const BASE_RADIUS := 90.0
const EXPAND_TIME := 0.45


func shoot(_index: int) -> void:
	Audio.play("bell", -8.0 - (6.0 if player.is_companion() else 0.0))
	var wave := RingWave.new()
	wave.enemies = enemies
	wave.position = player.position
	wave.max_radius = BASE_RADIUS * area()
	wave.expand_time = EXPAND_TIME
	wave.damage = damage()
	wave.knockback = stat("knockback", 2.0)
	if data.get("thunder", false):
		wave.color = Color("8fd3ff")
	world.add_child(wave)
