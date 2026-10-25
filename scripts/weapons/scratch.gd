extends Weapon
## Škrabanec: a horizontal swipe on the side the cat faces. Extra shots
## alternate to the other side, then stack above and below (like the Whip).

const BASE_SIZE := Vector2(56, 20)


func shoot(index: int) -> void:
	Audio.play("scratch", -10.0 - (6.0 if player.is_companion() else 0.0))
	var side := player.facing * (1 if index % 2 == 0 else -1)
	# Rows 0, 1, 2, 3... sit at the middle, above, below, two above...
	var row := floori(index / 2.0)
	var offset := ceili(row / 2.0) * (-1 if row % 2 == 1 else 1)
	var size := BASE_SIZE * area()
	var center := player.position + Vector2(side * (size.x * 0.5 + 4.0), -4.0 + offset * (size.y + 2.0))
	var rect := Rect2(center - size * 0.5, size)
	for enemy in enemies.query_rect(rect):
		strike(enemy, damage(), Vector2(side, 0), stat("knockback", 1.0))
	var fx := ScratchEffect.new()
	fx.position = center
	fx.size = size
	fx.side = side
	if id != "SCRATCH":
		fx.color = Color(1.0, 0.6, 0.25)
	world.add_child(fx)
