class_name DigQuest
extends Quest
## Buried treasure: dig at a spot, the clue there points to the next one;
## the last spot holds a chest and a pile of coins.

var _spot := 0
var _dug := 0.0
var _target := Vector2.ZERO


func title() -> String:
	return tr("QUEST_DIG_TITLE")


func objective() -> String:
	if not started:
		return tr("QUEST_DIG_FIND")
	return tr("QUEST_DIG_DIG") % [mini(_spot + 1, int(data["spots"])), int(data["spots"])]


func target_position() -> Vector2:
	return _target if started else position


func start_radius() -> float:
	return float(data["radius"])


func _on_start() -> void:
	_target = position


func _tick(delta: float) -> void:
	if not started:
		return
	if main.player.position.distance_to(_target) > float(data["radius"]):
		_dug = maxf(_dug - delta * 0.5, 0.0)
		return
	_dug += delta
	if _dug < float(data["dig_time"]):
		return
	_dug = 0.0
	_spot += 1
	Audio.play("pop", -4.0, 0.0)
	if _spot >= int(data["spots"]):
		main.pickups.spawn_named("chest", _target, 0.0)
		for i in 10:
			main.pickups.spawn_named("coin", _target + Vector2.from_angle(TAU * i / 10.0) * 24.0, 5.0)
		complete()
		return
	# Diggers attract trouble; the next clue points further on.
	spawn_wave_enemies(int(data["guards"]), _target, 140.0, 200.0)
	var dist: Array = data["next"]
	_target = Terrain.fix(_target + Vector2.from_angle(randf() * TAU) * randf_range(float(dist[0]), float(dist[1])), 24.0)


func _draw() -> void:
	var at := _target - position if started else Vector2.ZERO
	var c := Color("c0392b")
	draw_line(at + Vector2(-9, -9), at + Vector2(9, 9), c, 4.0)
	draw_line(at + Vector2(9, -9), at + Vector2(-9, 9), c, 4.0)
	var r := float(data["radius"])
	if started:
		draw_set_transform(at)
		draw_progress_ring(r, _dug / float(data["dig_time"]), Color("e0b53a"))
		draw_set_transform(Vector2.ZERO)
	else:
		draw_arc(at, r, 0.0, TAU, 32, Color(0.9, 0.7, 0.3, 0.4), 1.5)
