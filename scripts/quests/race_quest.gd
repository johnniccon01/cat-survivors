class_name RaceQuest
extends Quest
## The cat race: run through the flags one after another, each before its
## clock runs out.

var _flag := 0
var _left := 0.0
var _target := Vector2.ZERO


func title() -> String:
	return tr("QUEST_RACE_TITLE")


func objective() -> String:
	if not started:
		return tr("QUEST_RACE_FIND")
	return tr("QUEST_RACE_RUN") % [mini(_flag + 1, int(data["flags"])), int(data["flags"]), ceili(_left)]


func target_position() -> Vector2:
	return _target if started else position


func start_radius() -> float:
	return float(data["radius"])


func _on_start() -> void:
	_next_flag(position)


func _next_flag(from: Vector2) -> void:
	var dist: Array = data["next"]
	_target = Terrain.fix(from + Vector2.from_angle(randf() * TAU) * randf_range(float(dist[0]), float(dist[1])), 24.0)
	_left = float(data["time_per_flag"])


func _tick(delta: float) -> void:
	if not started:
		return
	_left -= delta
	if main.player.position.distance_to(_target) < float(data["radius"]):
		_flag += 1
		Audio.play("pop", -4.0, 0.1)
		if _flag >= int(data["flags"]):
			main.pickups.spawn_named("chest", _target, 0.0)
			player().heal(player().max_hp * 0.5)
			complete()
			return
		_next_flag(_target)
	elif _left <= 0.0:
		fail()


func _draw() -> void:
	var at := _target - position if started else Vector2.ZERO
	draw_line(at + Vector2(0, 10), at + Vector2(0, -22), OUTLINE, 3.0)
	var cloth := Color("e04646") if _flag % 2 == 0 else Color("f2f2f2")
	draw_colored_polygon(PackedVector2Array([at + Vector2(1, -22), at + Vector2(18, -16), at + Vector2(1, -10)]), cloth)
	var r := float(data["radius"])
	if started:
		draw_set_transform(at)
		draw_progress_ring(r, _left / float(data["time_per_flag"]), Color("f2c14e"))
		draw_set_transform(Vector2.ZERO)
	else:
		draw_arc(at, r, 0.0, TAU, 32, Color(0.95, 0.75, 0.3, 0.45), 1.5)
