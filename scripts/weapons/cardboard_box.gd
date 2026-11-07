extends Weapon
## Krabica: drops a cardboard box. Enemies bump into it and get scratched,
## and after a while it bursts. Evolved (Fortress Box) the boxes are big.

func shoot(_index: int) -> void:
	var g := Gizmo.new()
	g.kind = "box"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.radius = 14.0 * area()
	g.lifetime = duration()
	g.knockback = stat("knockback", 1.5)
	g.position = Terrain.fix(player.position + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 70.0), 12.0)
	world.add_child(g)
