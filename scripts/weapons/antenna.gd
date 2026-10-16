extends Weapon
## Anténa: a spark hits the nearest enemy and jumps on to the next closest
## ones (`pierce` jumps). Storm Antenna forks: every hit throws a second
## spark and leaves a small shock around it.

const RANGE := 210.0
const JUMP := 90.0


func shoot(_index: int) -> void:
	var first := enemies.nearest(player.position, RANGE)
	if first == null:
		return
	Audio.play("laser", -16.0 - (6.0 if player.is_companion() else 0.0))
	var storm: bool = data.get("storm", false)
	var hit: Dictionary = {}
	var points := PackedVector2Array([player.position + Vector2(0, -6)])
	var current := first
	var jumps := int(stat("pierce", 2.0))
	while current != null and jumps >= 0:
		hit[current.get_instance_id()] = true
		points.append(current.position)
		var from := current.position
		strike(current, damage(), current.position - points[points.size() - 2], stat("knockback", 0.2))
		if storm:
			for e in enemies.query_radius(from, 22.0 * area()):
				if not hit.has(e.get_instance_id()):
					strike(e, damage() * 0.4, e.position - from, 0.3)
		current = _next(from, hit)
		jumps -= 1
	_bolt(points)
	if storm and points.size() > 2:
		# The fork: a second chain from the first enemy hit.
		var fork := PackedVector2Array([points[1]])
		var next := _next(points[1], hit)
		var n := int(stat("pierce", 2.0)) / 2
		while next != null and n >= 0:
			hit[next.get_instance_id()] = true
			fork.append(next.position)
			strike(next, damage() * 0.7, next.position - fork[fork.size() - 2], 0.2)
			next = _next(next.position, hit)
			n -= 1
		_bolt(fork)


## The closest enemy within JUMP (scaled by area) that wasn't hit yet.
func _next(from: Vector2, hit: Dictionary) -> Enemy:
	var best: Enemy = null
	var best_d2 := INF
	for e in enemies.query_radius(from, JUMP * area()):
		if hit.has(e.get_instance_id()) or e.dead:
			continue
		var d2 := e.position.distance_squared_to(from)
		if d2 < best_d2:
			best_d2 = d2
			best = e
	return best


func _bolt(points: PackedVector2Array) -> void:
	if points.size() < 2:
		return
	var bolt := ChainBolt.new()
	bolt.points = points
	bolt.color = Color("ffe066") if data.get("storm", false) else Color("9ae0ff")
	world.add_child(bolt)
