extends ChainStep
## Stand in each zone until it fills up. data: count, hold (seconds),
## radius, spread [min, max], ordered (one after another, numbered),
## wrong_hurts (an ordered zone out of turn shocks the cat), time_limit
## (0 = none), during "converge" (enemies gather while you stand) |
## "lightning" (bolts strike around you), decay, look.

const SHOCK := 8.0

var _zones: Array[Vector2] = []
var _fill: Array[float] = []
var _current := 0
var _left := 0.0
var _pulse := 0.0
var _shock_t := 0.0


func _ready() -> void:
	var spread: Array = data.get("spread", [160.0, 320.0])
	var n := int(data.get("count", 3))
	_zones.append(position)
	for i in n - 1:
		var a := TAU * i / maxf(n - 1, 1) + randf_range(-0.5, 0.5)
		_zones.append(position + Vector2.from_angle(a) * randf_range(float(spread[0]), float(spread[1])))
	for i in n:
		_fill.append(0.0)
	_left = float(data.get("time_limit", 0.0))


func _radius() -> float:
	return float(data.get("radius", 40.0))


func _done_count() -> int:
	return _fill.filter(func(f: float) -> bool: return f >= 1.0).size()


func objective() -> String:
	var text := "%s %d/%d" % [step_text(), _done_count(), _zones.size()]
	if float(data.get("time_limit", 0.0)) > 0.0 and started:
		text += " · " + timer_text(_left)
	return text


func target_position() -> Vector2:
	if data.get("ordered", false):
		return _zones[_current]
	var best := position
	var best_d := INF
	for i in _zones.size():
		if _fill[i] < 1.0 and _zones[i].distance_to(player().position) < best_d:
			best_d = _zones[i].distance_to(player().position)
			best = _zones[i]
	return best


func _tick(delta: float) -> void:
	if started and float(data.get("time_limit", 0.0)) > 0.0:
		_left -= delta
		if _left <= 0.0:
			fail()
			return
	_shock_t -= delta
	var cat := player().position
	var ordered: bool = data.get("ordered", false)
	var standing := false
	for i in _zones.size():
		if _fill[i] >= 1.0:
			continue
		var inside := cat.distance_to(_zones[i]) < _radius()
		if inside and ordered and i != _current:
			if data.get("wrong_hurts", false) and _shock_t <= 0.0:
				_shock_t = 1.0
				player().take_damage(SHOCK)
				for k in _fill.size():
					if _fill[k] < 1.0:
						_fill[k] = 0.0
			continue
		if inside:
			standing = true
			_fill[i] += delta / float(data.get("hold", 10.0))
			if _fill[i] >= 1.0:
				_fill[i] = 1.0
				Audio.play("sparkle", -4.0, 0.0)
				while _current < _fill.size() - 1 and _fill[_current] >= 1.0:
					_current += 1
		else:
			_fill[i] = maxf(_fill[i] - delta * float(data.get("decay", 0.1)), 0.0)
	if _done_count() >= _zones.size():
		complete()
		return
	if standing:
		_pulse -= delta
		if _pulse <= 0.0:
			_during(cat)


func _during(cat: Vector2) -> void:
	match data.get("during", ""):
		"converge":
			_pulse = 3.0
			spawn_wave_enemies(4, cat, 150.0, 210.0)
		"lightning":
			_pulse = 1.1
			var at := cat + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 70.0)
			main.enemies.spawn_hazard(at, "strike", 26.0, 1.0, 14.0 * main.enemies.damage_mult, "lightning")
		_:
			_pulse = 999.0


func _draw() -> void:
	var look: String = data.get("look", "")
	var font := ThemeDB.fallback_font
	for i in _zones.size():
		var at := _zones[i] - position
		var done := _fill[i] >= 1.0
		draw_look(at, look, 0.5 if done else 1.0)
		var color := Color("6cc46c") if done else Color("f2c14e")
		if data.get("ordered", false) and not done and i != _current:
			color = Color("8f7ea3")
		draw_arc(at, _radius(), 0.0, TAU, 40, Color(color, 0.3), 2.0)
		if _fill[i] > 0.0:
			draw_arc(at, _radius(), -PI * 0.5, -PI * 0.5 + TAU * _fill[i], 40, color, 3.0)
		if data.get("ordered", false):
			draw_string(font, at + Vector2(-4, -_radius() - 6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
