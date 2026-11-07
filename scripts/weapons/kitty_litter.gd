extends Weapon
## Stelivo: the cat kicks up a cloud of litter where it stands; enemies in it
## choke. Evolved (Sandstorm) the clouds are big and slow everyone in them.


func shoot(_index: int) -> void:
	var g := Gizmo.new()
	g.kind = "cloud"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.radius = 34.0 * area()
	g.lifetime = duration()
	g.evolved = data.get("evolved", false)
	g.position = player.position
	world.add_child(g)
