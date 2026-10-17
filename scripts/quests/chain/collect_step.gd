extends ChainStep
## Gather things scattered over the map and (if "deliver") bring them to the
## spot. data: item (look), count, capacity (0 = no limit), spread [min, max],
## source "ground" | "guards" (an elite stands on each) | "kills" (drops
## from `enemy` with `chance`), enemy, guard_hp, deliver, look_to,
## slow_each (speed lost per thing carried), items (a look per thing, in
## turn, instead of one item), max_hits (-1 = any), spawn {enemy, every,
## count} (keeps sending the enemies the things drop from), time_limit
## (0 = none).

const PICK_RADIUS := 20.0
const DROP_RADIUS := 36.0
## A guard steps out when the cat comes this close to its thing.
const GUARD_WAKE := 320.0

var _items: Array[Vector2] = []
var _guards: Array = []
## Whether each thing's guard has stepped out yet (a freed guard compares
## equal to null, so _guards alone can't tell).
var _woke: Array[bool] = []
var _carried := 0
var _delivered := 0
var _dropped := 0
var _looks: Array[String] = []
var _hits := 0
var _spawn_t := 0.0
var _left := 0.0


func _ready() -> void:
	var source: String = data.get("source", "ground")
	if source == "kills":
		return
	var spread: Array = data.get("spread", [160.0, 420.0])
	for i in int(data.get("count", 5)):
		var a := TAU * i / float(data.get("count", 5)) + randf_range(-0.4, 0.4)
		_items.append(position + Vector2.from_angle(a) * randf_range(float(spread[0]), float(spread[1])))
		_guards.append(null)
		_woke.append(false)
		_looks.append(_look(i))


func _look(n: int) -> String:
	var looks: Array = data.get("items", [])
	return looks[n % looks.size()] if not looks.is_empty() else data.get("item", "sock")


func _on_start() -> void:
	_left = float(data.get("time_limit", 0.0))
	if data.get("source", "ground") == "kills":
		main.enemies.enemy_killed.connect(_on_killed)
	if int(data.get("max_hits", -1)) >= 0:
		player().hurt.connect(_on_hurt)


func _on_hurt() -> void:
	_hits += 1
	if _hits > int(data.get("max_hits", -1)):
		fail()


func objective() -> String:
	var n := int(data.get("count", 5))
	var text := "%s %d/%d" % [step_text(), _delivered if data.get("deliver", false) else _delivered + _carried, n]
	if int(data.get("max_hits", -1)) >= 0 and started:
		text += " · " + tr("CHAIN_HITS") % [_hits, int(data["max_hits"])]
	if float(data.get("time_limit", 0.0)) > 0.0 and started:
		text += " · " + timer_text(_left)
	if data.get("deliver", false) and _carried > 0:
		text += " · " + tr("CHAIN_CARRYING") % _carried
	return text


func _full() -> bool:
	var cap := int(data.get("capacity", 0))
	return cap > 0 and _carried >= cap


func target_position() -> Vector2:
	var deliver: bool = data.get("deliver", false)
	if deliver and _carried > 0 and (_full() or _items.is_empty()):
		return position
	var best := position
	var best_d := INF
	for i in _items.size():
		var p := _items[i]
		if is_instance_valid(_guards[i]) and not _guards[i].dead:
			p = _guards[i].position
		var d := p.distance_to(player().position)
		if d < best_d:
			best_d = d
			best = p
	return best


func _guarded(i: int) -> bool:
	return data.get("source", "ground") == "guards" and (not _woke[i] or (is_instance_valid(_guards[i]) and not _guards[i].dead))


func _tick(delta: float) -> void:
	var cat := player().position
	if started and float(data.get("time_limit", 0.0)) > 0.0:
		_left -= delta
		if _left <= 0.0:
			fail()
			return
	var spawn: Dictionary = data.get("spawn", {})
	if started and not spawn.is_empty():
		_spawn_t -= delta
		if _spawn_t <= 0.0:
			_spawn_t = float(spawn.get("every", 6.0))
			spawn_wave_enemies(int(spawn.get("count", 3)), cat, 220.0, 280.0, spawn["enemy"])
	for i in range(_items.size() - 1, -1, -1):
		if data.get("source", "ground") == "guards" and not _woke[i] and cat.distance_to(_items[i]) < GUARD_WAKE:
			_woke[i] = true
			var guard := spawn_wave_enemies(1, _items[i], 0.0, 4.0, data.get("enemy", ""))
			_guards[i] = guard[0] if not guard.is_empty() else false
			if not guard.is_empty():
				guard[0].make_elite(float(data.get("guard_hp", 6.0)))
		if _guarded(i) or _full() or cat.distance_to(_items[i]) > PICK_RADIUS:
			continue
		_items.remove_at(i)
		_guards.remove_at(i)
		_woke.remove_at(i)
		_looks.remove_at(i)
		_carried += 1
		Audio.play("pop", -4.0, 0.0)
	if not data.get("deliver", false):
		if _carried >= int(data.get("count", 5)):
			complete()
		return
	player().speed_factor = 1.0 - float(data.get("slow_each", 0.0)) * _carried
	if _carried > 0 and player_dist() < DROP_RADIUS:
		_delivered += _carried
		_carried = 0
		player().speed_factor = 1.0
		Audio.play("chest", -6.0, 0.0)
		if _delivered >= int(data.get("count", 5)):
			complete()


func _on_killed(enemy_id: String, pos: Vector2, _xp: float) -> void:
	if enemy_id != data.get("enemy", "") or _dropped >= int(data.get("count", 5)):
		return
	if randf() < float(data.get("chance", 0.2)):
		_dropped += 1
		_items.append(pos)
		_guards.append(null)
		_woke.append(true)
		_looks.append(_look(_dropped - 1))


func _exit_tree() -> void:
	if is_instance_valid(main) and is_instance_valid(main.player):
		main.player.speed_factor = 1.0


func _draw() -> void:
	for i in _items.size():
		if not _guarded(i):
			draw_look(_items[i] - position, _looks[i])
			draw_beacon(_items[i] - position, 12.0, Color("f2c14e"))
	if data.get("deliver", false):
		draw_look(Vector2.ZERO, data.get("look_to", "basket"))
		if _carried > 0:
			draw_beacon(Vector2.ZERO, DROP_RADIUS, Color("6cc46c"))
	for k in _carried:
		draw_look(player().position - position + Vector2(-6 + k * 12, -26), _look(_delivered + k))
