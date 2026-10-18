extends Weapon
## Konzerva: lobs a tin can at an enemy; it bursts where it lands. Cluster
## Can: every burst throws four little cans that burst too.

const RANGE := 260.0
const BLAST := 42.0


func shoot(_index: int) -> void:
	var target := enemies.nearest(player.position, RANGE)
	var to := target.position if target != null else player.position + Vector2(player.facing * 120.0, randf_range(-40.0, 40.0))
	var can := CanLob.new()
	can.weapon = self
	can.from = player.position + Vector2(0, -8)
	can.to = to + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
	can.flight = 0.55 / proj_speed()
	can.radius = BLAST * area()
	can.damage = damage()
	can.cluster = data.get("cluster", false)
	world.add_child(can)
	Audio.play("pop", -12.0 - (6.0 if player.is_companion() else 0.0), 0.2)
