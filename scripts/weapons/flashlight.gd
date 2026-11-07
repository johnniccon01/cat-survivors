extends Weapon
## Baterka: a cone of light ahead of the cat that keeps burning whoever stands
## in it. Evolved (Lighthouse) the beam goes round and round.

const REACH := 130.0


func shoot(_index: int) -> void:
	var g := Gizmo.new()
	g.kind = "beam"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.reach = REACH * area()
	g.half_angle = 0.42
	g.lifetime = duration()
	g.knockback = 0.0
	g.dir = player.velocity.normalized() if player.velocity.length() > 5.0 else Vector2(player.facing, 0)
	if data.get("lighthouse", false):
		g.spin = 2.6
		g.half_angle = 0.3
	g.position = player.position
	world.add_child(g)
