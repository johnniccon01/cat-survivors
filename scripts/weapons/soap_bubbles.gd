extends Weapon
## Mydlové bubliny: slow soap bubbles drift away from the cat; the first enemy
## they touch pops them, hurting and slowing everyone close. Evolved (Bubble
## Bath) bigger bubbles, longer slow.


func shoot(_index: int) -> void:
	var g := Gizmo.new()
	g.kind = "bubble"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.radius = 9.0 * area()
	g.velocity = Vector2.from_angle(randf() * TAU) * 60.0 * proj_speed()
	g.lifetime = duration()
	g.knockback = stat("knockback", 0.3)
	g.evolved = data.get("evolved", false)
	g.position = player.position + Vector2(0, -6)
	world.add_child(g)
