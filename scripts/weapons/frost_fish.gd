extends Weapon
## Mrazená rybka: an icy beam at the toughest enemy nearby (bosses first)
## that freezes everything it hits in place for a moment. Bosses thaw twice
## as fast, and Death shrugs the ice off: it only slows down a little.
## Eternal Winter beams at several foes and freezes a ring around each.

const RANGE := 320.0
const BASE_LENGTH := 240.0
const BASE_WIDTH := 3.5
const ICE := Color("8fe3ff")
## Bosses stay frozen this much of the time.
const BOSS_FREEZE := 0.5
## Death resists the ice: never stopped, only slowed to this much of its
## speed, and for a short part of the freeze.
const DEATH_SLOW := 0.6
const DEATH_FREEZE := 0.3


func shoot(index: int) -> void:
	Audio.play("laser", -16.0 - (6.0 if player.is_companion() else 0.0), 0.0)
	var target := _toughest(index)
	var dir := Vector2.from_angle(randf() * TAU) if target == null else (target.position - player.position).normalized()
	var from := player.position + Vector2(0, -5)
	var to := from + dir * BASE_LENGTH * area()
	var width := BASE_WIDTH * area()
	var seconds := stat("freeze", 1.0) * player.stat("duration")
	var hit := enemies.query_segment(from, to, width)
	if target != null and not target in hit:
		hit.append(target)
	for enemy in hit:
		strike(enemy, damage(), dir, 0.0)
		freeze(enemy, seconds)
		if data.get("nova", false):
			for other in enemies.query_radius(enemy.position, 40.0 * area()):
				freeze(other, seconds * 0.6)
	var beam := BeamEffect.new()
	beam.from = from
	beam.to = to if target == null else from + dir * maxf(from.distance_to(target.position), BASE_LENGTH * area())
	beam.width = width
	beam.color = ICE
	world.add_child(beam)


## Stops `enemy` where it stands (bosses for half as long, Death only slows).
static func freeze(enemy: Enemy, seconds: float) -> void:
	if enemy == null or enemy.dead or enemy.is_prop:
		return
	if enemy.fatal:
		enemy.slow_down(DEATH_SLOW, seconds * DEATH_FREEZE)
		enemy.chill(seconds * DEATH_FREEZE)
		return
	var t := seconds * (BOSS_FREEZE if enemy.is_boss else 1.0)
	enemy.slow_down(0.0, t)
	enemy.chill(t)


## Bosses first, then the enemy with the most health in range; later shots
## of a burst pick the next one down, so Eternal Winter spreads its beams.
func _toughest(index: int) -> Enemy:
	var near: Array = enemies.query_radius(player.position, RANGE).filter(func(e: Enemy) -> bool: return not e.dead and not e.is_prop)
	if near.is_empty():
		return null
	near.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		if a.is_boss != b.is_boss:
			return a.is_boss
		return a.hp > b.hp)
	return near[index % near.size()]
