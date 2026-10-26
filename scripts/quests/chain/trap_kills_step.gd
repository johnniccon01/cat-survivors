extends ChainStep
## Hold the trap ring: while the cat stands inside it, tougher "lured"
## enemies keep coming at it, and every enemy defeated anywhere counts (by
## traps or by weapons, even ones that never get near the ring). Outside the
## ring nothing comes and nothing counts.
## data: count, radius, spawn_every, spawn_count, hp_mult, enemy,
## traps {id, count}.

var _traps: Array[Trap] = []
var _kills := 0
var _spawn_t := 0.0


func objective() -> String:
	var text := "%s %d/%d" % [step_text(), _kills, _count()]
	if started and not _inside():
		text += " · " + tr("TRAP_RING_BACK")
	return text


func _count() -> int:
	return int(data.get("count", 60))


func _radius() -> float:
	return float(data.get("radius", 110.0))


func _inside() -> bool:
	return player_dist() < _radius()


func _on_start() -> void:
	main.enemies.enemy_killed.connect(_on_killed)
	var traps: Dictionary = data.get("traps", {})
	var n := int(traps.get("count", 6))
	for i in n:
		var trap := Trap.new()
		trap.position = position + Vector2.from_angle(TAU * i / n) * randf_range(_radius() * 0.55, _radius() * 1.3)
		trap.setup(traps.get("id", "MOUSETRAP"), main)
		main.add_child(trap)
		_traps.append(trap)


func _tick(delta: float) -> void:
	if not started:
		return
	if _kills >= _count():
		complete()
		return
	if not _inside():
		return
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = float(data.get("spawn_every", 2.5))
		_spawn_lured(int(data.get("spawn_count", 6)))


func _spawn_lured(count: int) -> void:
	var pool: Array = main.spawner.current_wave()["enemies"]
	var hp_mult: float = main.spawner.hp_multiplier() * float(data.get("hp_mult", 1.6))
	for i in count:
		var id: String = data.get("enemy", "") if data.get("enemy", "") != "" else pool.pick_random()
		var pos := position + Vector2.from_angle(TAU * i / count + randf() * 0.5) * randf_range(_radius() + 90.0, _radius() + 170.0)
		main.enemies.spawn(id, pos, hp_mult)


func _on_killed(_enemy_id: String, _pos: Vector2, _xp: float) -> void:
	if started and _inside():
		_kills += 1


func _exit_tree() -> void:
	for trap in _traps:
		if is_instance_valid(trap):
			trap.queue_free()


func _draw() -> void:
	if not started:
		draw_beacon(Vector2.ZERO, 24.0, Color("f2c14e"))
		return
	var on := _inside()
	draw_arc(Vector2.ZERO, _radius(), 0.0, TAU, 48, Color("f2c14e", 0.55 if on else 0.25), 3.0)
	var k := clampf(float(_kills) / _count(), 0.0, 1.0)
	draw_arc(Vector2.ZERO, _radius() + 6.0, -PI / 2, -PI / 2 + TAU * k, 48, Color("6cc46c", 0.8), 4.0)
