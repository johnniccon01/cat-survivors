extends Weapon
## Chvost: a sweep of the tail behind the cat, where the claws don't reach.
## Evolved (Twin Tails) it whips both ways at once.

const REACH := 70.0


func shoot(index: int) -> void:
	Audio.play("scratch", -12.0 - (6.0 if player.is_companion() else 0.0), 0.1)
	var back := Vector2(-player.facing, 0)
	if data.get("twin", false) and index % 2 == 1:
		back = -back
	var g := Gizmo.new()
	g.kind = "arc"
	g.source = self
	g.enemies = enemies
	g.player = player
	g.damage = damage()
	g.dir = back
	g.half_angle = 1.1
	g.reach = REACH * area()
	g.knockback = stat("knockback", 1.2)
	g.position = player.position
	world.add_child(g)


func shots() -> int:
	return amount() * (2 if data.get("twin", false) else 1)
