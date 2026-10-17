extends ChainStep
## A runaway: it shows up when the cat comes close and flees. Defeat it
## before it gets away (its "flee_time" in enemies.json). data: enemy,
## hp_mult.

var _runner: Enemy
var _left := 0.0


func objective() -> String:
	if not started:
		return step_text()
	return "%s · %s" % [step_text(), timer_text(_left)]


func target_position() -> Vector2:
	return _runner.position if is_instance_valid(_runner) else position


func _on_start() -> void:
	var id: String = data["enemy"]
	_runner = main.enemies.spawn(id, position, main.spawner.hp_multiplier() * float(data.get("hp_mult", 1.0)))
	_left = float(GameData.enemies[id].get("flee_time", 30.0))
	main.enemies.enemy_killed.connect(_on_killed)
	main.enemies.escaped.connect(_on_escaped)


func _tick(delta: float) -> void:
	if started:
		_left -= delta


func _on_killed(enemy_id: String, _pos: Vector2, _xp: float) -> void:
	if enemy_id == data["enemy"]:
		complete()


func _on_escaped(enemy_id: String, _pos: Vector2) -> void:
	if enemy_id == data["enemy"]:
		fail()


func _draw() -> void:
	if not started:
		draw_look(Vector2.ZERO, "hint")
		draw_beacon(Vector2.ZERO, 20.0, Color("f2c14e"))
