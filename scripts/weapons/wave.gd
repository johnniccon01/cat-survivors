extends Weapon
## Vlna: a wall of water rolls out the way the cat faces and shoves enemies
## back; extra waves go the other way. Tsunami sends them both ways at once,
## taller and further.


func shoot(index: int) -> void:
	var dir := Vector2(player.facing * (1 if index % 2 == 0 else -1), 0)
	_roll(dir)
	if data.get("tsunami", false):
		_roll(-dir)
	Audio.play("splash", -10.0 - (6.0 if player.is_companion() else 0.0), 0.15)


func _roll(dir: Vector2) -> void:
	var w := WaveFx.new()
	w.weapon = self
	w.position = player.position
	w.dir = dir
	w.height = 64.0 * area()
	w.distance = 240.0 * area()
	w.speed = 260.0 * proj_speed()
	w.damage = damage()
	w.knockback = stat("knockback", 2.0)
	world.add_child(w)
