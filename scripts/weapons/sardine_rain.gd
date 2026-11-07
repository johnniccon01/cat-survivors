extends Weapon
## Sardinkový dážď: sardines fall from the sky onto enemies around the cat;
## their shadows show where. Evolved (Fish Storm) many more, bigger.

const RANGE := 300.0


func shoot(_index: int) -> void:
	var target := enemies.nearest(player.position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 220.0), RANGE)
	var at := target.position if target != null else player.position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 200.0)
	var g := Gizmo.new()
	g.kind = "drop"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.radius = 26.0 * area()
	g.lifetime = 0.6
	g.knockback = stat("knockback", 0.8)
	g.position = at
	world.add_child(g)
