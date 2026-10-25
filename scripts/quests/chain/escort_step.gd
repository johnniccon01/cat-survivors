extends ChainStep
## Walk one or more cats somewhere: each one waits at its spot and follows
## you once you reach it. A cat that goes down gets back up if you stay
## close. data: cat (id in cats.json), count, spread [min, max] (where the
## cats wait; one cat waits at the spot), deliver_to "start" (bring them to
## the spot, e.g. their mother) or a distance [min, max] (a new place),
## hp, slow (speed factor of the cats), look_to.

const REACH := 28.0
const HOME_RADIUS := 50.0
const REVIVE_RADIUS := 40.0
const REVIVE_TIME := 3.0

var _waiting: Array[Vector2] = []
var _cats: Array[Player] = []
var _home := Vector2.ZERO
var _revive := 0.0
var _home_set := false


func _ready() -> void:
	var n := int(data.get("count", 1))
	if n == 1 or data.get("deliver_to", "start") is Array:
		_waiting.append(position)
	var spread: Array = data.get("spread", [200.0, 380.0])
	for i in n - _waiting.size():
		var a := TAU * i / float(n) + randf_range(-0.4, 0.4)
		_waiting.append(Terrain.fix(position + Vector2.from_angle(a) * randf_range(float(spread[0]), float(spread[1])), 24.0))


func objective() -> String:
	var n := int(data.get("count", 1))
	if n > 1:
		return "%s %d/%d" % [step_text(), _cats.size(), n]
	return step_text()


func target_position() -> Vector2:
	if not _waiting.is_empty():
		var best := _waiting[0]
		for p in _waiting:
			if p.distance_to(player().position) < best.distance_to(player().position):
				best = p
		return best
	for cat in _cats:
		if is_instance_valid(cat) and cat.is_dead:
			return cat.position
	return _home


func _tick(delta: float) -> void:
	var me := player().position
	for i in range(_waiting.size() - 1, -1, -1):
		if me.distance_to(_waiting[i]) < REACH:
			var cat := main.spawn_escort(data["cat"], _waiting[i], float(data.get("hp", 60.0))) as Player
			cat.speed_factor = float(data.get("slow", 1.0))
			_cats.append(cat)
			_waiting.remove_at(i)
			Audio.play("meow", -4.0, 0.2)
	if not _home_set and _waiting.is_empty():
		_home_set = true
		var to: Variant = data.get("deliver_to", "start")
		_home = random_point(position, to) if to is Array else position
	if not _home_set:
		_revive_tick(delta)
		return
	_revive_tick(delta)
	for cat in _cats:
		if not is_instance_valid(cat) or cat.is_dead or cat.position.distance_to(_home) > HOME_RADIUS:
			return
	complete()


func _revive_tick(delta: float) -> void:
	for cat in _cats:
		if is_instance_valid(cat) and cat.is_dead:
			if cat.position.distance_to(player().position) < REVIVE_RADIUS:
				_revive += delta / REVIVE_TIME
				if _revive >= 1.0:
					_revive = 0.0
					cat.revive(0.5)
			return


func _exit_tree() -> void:
	for cat in _cats:
		if is_instance_valid(cat):
			main.enemies.escorts.erase(cat)
			cat.queue_free()


func _draw() -> void:
	var look := CatArt.look(data["cat"])
	for p in _waiting:
		CatArt.draw(self, look, 1, 0.0, false, false, "sad", p - position)
		draw_beacon(p - position, 20.0, Color("f2c14e"))
	if _home_set:
		draw_look(_home - position, data.get("look_to", "x"))
		draw_beacon(_home - position, HOME_RADIUS, Color("6cc46c"))
	for cat in _cats:
		if is_instance_valid(cat) and cat.is_dead:
			draw_arc(cat.position - position, REVIVE_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * _revive, 32, Color("6cc46c"), 3.0)
