class_name RedDotQuest
extends Quest
## The red dot: a laser dot zips around; touch it a few times before time
## runs out. It is faster than the cat, so you have to cut it off.

const CATCH_DIST := 13.0
const ROAM_RADIUS := 160.0

var _dot := Vector2.ZERO
var _goal := Vector2.ZERO
var _pause := 0.0
var _catches := 0
var _time_left := 0.0


func title() -> String:
	return tr("QUEST_DOT_TITLE")


func objective() -> String:
	if not started:
		return tr("QUEST_DOT_FIND")
	return tr("QUEST_DOT_CATCH") % [_catches, int(data["catches"]), ceili(_time_left)]


func _on_start() -> void:
	_time_left = float(data["time_limit"])
	_dot = Vector2(40, 0)
	_goal = _random_point()


func _tick(delta: float) -> void:
	if not started:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		fail()
		return
	if _pause > 0.0:
		_pause -= delta
	else:
		_dot = _dot.move_toward(_goal, float(data["dot_speed"]) * delta)
		if _dot.distance_to(_goal) < 2.0:
			_goal = _random_point()
			# Tease: sometimes stop for a moment.
			if randf() < 0.5:
				_pause = randf_range(0.3, 0.8)
	if (position + _dot).distance_to(player().position) < CATCH_DIST:
		_catches += 1
		if _catches >= int(data["catches"]):
			main.pickups.spawn_named("chest", position + _dot, 0.0)
			complete()
			return
		_dot = _random_point()
		_goal = _random_point()


func _random_point() -> Vector2:
	return Vector2.from_angle(randf() * TAU) * randf_range(30.0, ROAM_RADIUS)


func _draw() -> void:
	# The laser pointer lying on the floor.
	draw_rect(Rect2(-8, -2, 16, 4), OUTLINE)
	draw_rect(Rect2(-7, -1, 14, 2), Color("c9ced2"))
	draw_rect(Rect2(6, -1, 2, 2), Color("ff3b3b"))
	if not started:
		return
	draw_line(Vector2(8, 0), _dot, Color(1, 0.2, 0.2, 0.15), 1.0)
	var pulse := 1.0 + sin(_age * 25.0) * 0.25
	draw_circle(_dot, 7.0 * pulse, Color(1, 0.1, 0.1, 0.25))
	draw_circle(_dot, 3.0, Color("ff3b3b"))
	draw_circle(_dot, 1.2, Color.WHITE)
