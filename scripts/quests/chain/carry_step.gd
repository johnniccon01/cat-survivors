extends ChainStep
## Pick something up and bring it somewhere before time runs out.
## data: item (look), to_distance [min, max], time, max_hits (-1 = any),
## slow (speed factor while carrying), look_to, guards {enemy, count}.

const PICK_RADIUS := 20.0
const DROP_RADIUS := 32.0

var _stage := "pick"
var _to := Vector2.ZERO
var _left := 0.0
var _hits := 0
var _guards: Array[Enemy] = []


func objective() -> String:
	if _stage == "pick":
		return step_text()
	var text := "%s · %s" % [step_text(), timer_text(_left)]
	var max_hits := int(data.get("max_hits", -1))
	if max_hits >= 0:
		text += " · " + tr("CHAIN_HITS") % [_hits, max_hits]
	return text


func target_position() -> Vector2:
	return _to if _stage == "carry" else position


func _on_start() -> void:
	var guards: Dictionary = data.get("guards", {})
	if not guards.is_empty():
		_guards = spawn_wave_enemies(int(guards.get("count", 8)), position, 40.0, 110.0, guards.get("enemy", ""))


func _tick(delta: float) -> void:
	match _stage:
		"pick":
			if started and alive_count(_guards) == 0 and player_dist() < PICK_RADIUS:
				_stage = "carry"
				_to = random_point(position, data.get("to_distance", [450.0, 600.0]))
				_left = float(data.get("time", 60.0))
				player().speed_factor = float(data.get("slow", 1.0))
				player().hurt.connect(_on_hurt)
				Audio.play("pop", -4.0, 0.0)
		"carry":
			_left -= delta
			if player().position.distance_to(_to) < DROP_RADIUS:
				_drop()
				complete()
			elif _left <= 0.0:
				_drop()
				fail()


func _on_hurt() -> void:
	_hits += 1
	var max_hits := int(data.get("max_hits", -1))
	if max_hits >= 0 and _hits > max_hits:
		_drop()
		fail()


func _drop() -> void:
	if is_instance_valid(main.player):
		main.player.speed_factor = 1.0


func _exit_tree() -> void:
	_drop()


func _draw() -> void:
	var item: String = data.get("item", "key")
	if _stage == "pick":
		draw_look(Vector2.ZERO, item)
		draw_beacon(Vector2.ZERO, 16.0, Color("f2c14e"))
		return
	draw_look(_to - position, data.get("look_to", "x"))
	draw_beacon(_to - position, DROP_RADIUS, Color("6cc46c"))
	draw_look(player().position - position + Vector2(0, -24), item)
