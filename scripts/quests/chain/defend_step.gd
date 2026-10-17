extends ChainStep
## Keep a spot (or several) safe until time runs out. data: time, spots,
## spread [min, max], mode "enemies" (enemies standing at a spot wear it
## down) | "absence" (a spot wears down while the cat is away from it),
## radius, spawn_every, spawn_count, enemy, look.

const SPOT_HP := 100.0
const DRAIN_PER_ENEMY := 6.0
const ABSENCE_DRAIN := 5.0
const REFILL := 12.0

var _spots: Array[Vector2] = []
var _hp: Array[float] = []
var _left := 0.0
var _spawn_t := 0.0


func _ready() -> void:
	_spots.append(position)
	var n := int(data.get("spots", 1))
	var spread: Array = data.get("spread", [220.0, 300.0])
	for i in n - 1:
		var a := TAU * i / maxf(n - 1, 1) + randf_range(-0.3, 0.3)
		_spots.append(position + Vector2.from_angle(a) * randf_range(float(spread[0]), float(spread[1])))
	for i in n:
		_hp.append(SPOT_HP)
	_left = float(data.get("time", 45.0))


func _radius() -> float:
	return float(data.get("radius", 60.0))


func objective() -> String:
	if not started:
		return step_text()
	return "%s · %s · %d %%" % [step_text(), timer_text(_left), roundi(_hp.min())]


func target_position() -> Vector2:
	if _spots.size() == 1:
		return position
	var worst := 0
	for i in _hp.size():
		if _hp[i] < _hp[worst]:
			worst = i
	return _spots[worst]


func _tick(delta: float) -> void:
	if not started:
		return
	_left -= delta
	_spawn_t -= delta
	var absence: bool = data.get("mode", "enemies") == "absence"
	for i in _spots.size():
		var near_cat := player().position.distance_to(_spots[i]) < _radius()
		if absence:
			_hp[i] += (REFILL if near_cat else -ABSENCE_DRAIN) * delta
		else:
			var biters: int = main.enemies.query_radius(_spots[i], _radius() * 0.6).size()
			_hp[i] -= biters * DRAIN_PER_ENEMY * delta
		_hp[i] = minf(_hp[i], SPOT_HP)
		if _hp[i] <= 0.0:
			fail()
			return
	if _spawn_t <= 0.0:
		_spawn_t = float(data.get("spawn_every", 3.0))
		for i in _spots.size():
			if absence and player().position.distance_to(_spots[i]) < _radius():
				continue
			spawn_wave_enemies(int(data.get("spawn_count", 4)), _spots[i], 140.0, 210.0, data.get("enemy", ""))
	if _left <= 0.0:
		complete()


func _draw() -> void:
	var look: String = data.get("look", "")
	for i in _spots.size():
		var at := _spots[i] - position
		draw_look(at, look)
		draw_arc(at, _radius(), 0.0, TAU, 40, Color(1, 1, 1, 0.2), 2.0)
		if started:
			var k := clampf(_hp[i] / SPOT_HP, 0.0, 1.0)
			draw_rect(Rect2(at + Vector2(-24, 26), Vector2(48, 5)), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(at + Vector2(-24, 26), Vector2(48 * k, 5)), Color("6cc46c").lerp(Color("e04646"), 1.0 - k))
		else:
			draw_beacon(at, 22.0, Color("f2c14e"))
