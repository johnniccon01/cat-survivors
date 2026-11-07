extends Weapon
## Pradenie: the cat purrs – a soft wave that hurts the enemies around it and
## heals the cat a little. Evolved (Lion's Purr) a bigger roar that heals more.

const BASE_RADIUS := 90.0


func shoot(_index: int) -> void:
	var wave := RingWave.new()
	wave.source = self
	wave.enemies = enemies
	wave.position = player.position
	wave.max_radius = BASE_RADIUS * area()
	wave.expand_time = 0.6
	wave.damage = damage()
	wave.knockback = stat("knockback", 0.4)
	wave.color = Color("f0a0c8") if not data.get("lion", false) else Color("f2c14e")
	world.add_child(wave)
	player.heal(stat("heal", 1.0) * player.stat("heal_power"))
