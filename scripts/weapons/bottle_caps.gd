extends Weapon
## Vrchnáky: a bottle cap flicked at an enemy ricochets on to the next ones.
## Evolved (Cap Cannon) more caps and many more bounces.

const RANGE := 300.0


func shoot(_index: int) -> void:
	var target := enemies.nearest(player.position, RANGE)
	var dir := Vector2.from_angle(randf() * TAU) if target == null else (target.position - player.position).normalized()
	var g := Gizmo.new()
	g.kind = "cap"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.radius = 5.0 * area()
	g.velocity = dir * 360.0 * proj_speed()
	g.bounces = int(stat("bounces", 3.0))
	g.lifetime = duration()
	g.knockback = stat("knockback", 0.4)
	g.evolved = data.get("evolved", false)
	g.position = player.position + Vector2(0, -4)
	world.add_child(g)
