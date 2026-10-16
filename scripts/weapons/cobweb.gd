extends Weapon
## Pavučina: throws a sticky web onto a random nearby enemy. Enemies in the
## web are slowed down and take a little damage over time. The Silk Trap
## evolution holds them in place (bosses only slowed).

const RANGE := 220.0
const BASE_RADIUS := 26.0
const TICK := 0.5


func shoot(_index: int) -> void:
	Audio.play("whoosh", -12.0 - (6.0 if player.is_companion() else 0.0))
	var pos := player.position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 100.0)
	var targets := enemies.query_radius(player.position, RANGE)
	if not targets.is_empty():
		pos = targets.pick_random().position
	var web := WebPatch.new()
	web.source = self
	web.enemies = enemies
	web.position = pos
	web.radius = BASE_RADIUS * area()
	web.damage = damage()
	web.tick = TICK
	web.lifetime = duration()
	web.slow = stat("slow", 0.45)
	web.silk = data.get("silk", false)
	world.add_child(web)
