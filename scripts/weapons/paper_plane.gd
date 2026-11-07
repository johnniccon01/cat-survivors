extends Weapon
## Papierové lietadielko: a paper plane that steers towards the nearest enemy.
## Evolved (Origami Squadron) the planes turn and strike again.


func shoot(index: int) -> void:
	var g := Gizmo.new()
	g.kind = "plane"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.radius = 6.0 * area()
	g.velocity = Vector2(player.facing, 0).rotated(-0.8 + index * 0.5) * 230.0 * proj_speed()
	g.lifetime = duration()
	g.bounces = 2
	g.knockback = stat("knockback", 0.5)
	g.evolved = data.get("evolved", false)
	g.position = player.position + Vector2(0, -6)
	world.add_child(g)
