extends Weapon
## Dronček: little drones circle the cat and zap the nearest enemy with a
## laser. Drone Swarm: every beam jumps on to a second enemy.

const ORBIT := 34.0
const RANGE := 260.0

var _drones: Array[DroneFx] = []
var _t := 0.0


func shots() -> int:
	return 1


func _process(delta: float) -> void:
	_t += delta
	var n := maxi(amount(), 1)
	while _drones.size() < n:
		var d := DroneFx.new()
		d.position = player.position
		world.add_child(d)
		_drones.append(d)
	while _drones.size() > n:
		_drones.pop_back().queue_free()
	for i in _drones.size():
		_drones[i].position = player.position + Vector2(0, -10) + Vector2.from_angle(_t * 2.0 + TAU * i / n) * ORBIT * area()


func shoot(_index: int) -> void:
	var fired := false
	for d in _drones:
		var target := enemies.nearest(d.position, RANGE)
		if target == null:
			continue
		fired = true
		_beam(d.position, target.position)
		var at := target.position
		strike(target, damage(), at - d.position, 0.2)
		if data.get("swarm", false):
			var second := _nearest_other(target, 90.0)
			if second != null:
				_beam(at, second.position)
				strike(second, damage() * 0.7, second.position - at, 0.2)
	if fired:
		Audio.play("laser", -18.0 - (6.0 if player.is_companion() else 0.0), 0.2)


func _beam(from: Vector2, to: Vector2) -> void:
	var beam := BeamEffect.new()
	beam.from = from
	beam.to = to
	beam.width = 2.0
	beam.color = Color("ffe066") if data.get("swarm", false) else Color("5ad1e6")
	world.add_child(beam)


func _exit_tree() -> void:
	for d in _drones:
		if is_instance_valid(d):
			d.queue_free()
