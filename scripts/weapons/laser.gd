extends Weapon
## Laserové ukazovátko: an instant beam towards a random nearby enemy that
## hits everything along its line. Disco Laser fires rainbow beams.

const RANGE := 260.0
const BASE_LENGTH := 180.0
const BASE_WIDTH := 3.0


func shoot(index: int) -> void:
	Audio.play("laser", -14.0 - (6.0 if player.is_companion() else 0.0))
	var dir := Vector2.from_angle(randf() * TAU)
	var targets := enemies.query_radius(player.position, RANGE)
	if not targets.is_empty():
		dir = (targets.pick_random().position - player.position).normalized()
	var from := player.position + Vector2(0, -5)
	var to := from + dir * BASE_LENGTH * area()
	var width := BASE_WIDTH * area()
	for enemy in enemies.query_segment(from, to, width):
		enemy.hit(damage(), dir, stat("knockback", 0.2))
	var beam := BeamEffect.new()
	beam.from = from
	beam.to = to
	beam.width = width
	if data.get("rainbow", false):
		beam.color = Color.from_hsv(fmod(index * 0.17 + randf() * 0.1, 1.0), 0.8, 1.0)
	world.add_child(beam)
