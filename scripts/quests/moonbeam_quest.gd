class_name MoonbeamQuest
extends Quest
## Stay in the moonbeam: a patch of moonlight drifts slowly across the map;
## standing in it fills the ring (and heals a little).

var _held := 0.0
var _dir := Vector2.RIGHT
var _turn_t := 0.0


func title() -> String:
	return tr("QUEST_MOONBEAM_TITLE")


func objective() -> String:
	if not started:
		return tr("QUEST_MOONBEAM_FIND")
	return tr("QUEST_MOONBEAM_HOLD") % ceili(float(data["hold_time"]) - _held)


func start_radius() -> float:
	return float(data["radius"])


func _on_start() -> void:
	_dir = Vector2.from_angle(randf() * TAU)


func _tick(delta: float) -> void:
	if not started:
		return
	_turn_t -= delta
	if _turn_t <= 0.0:
		_turn_t = randf_range(2.0, 4.0)
		_dir = _dir.rotated(randf_range(-1.5, 1.5))
	position = Terrain.fix(position + _dir * float(data["speed"]) * delta, float(data["radius"]) * 0.5)
	if player_dist() < float(data["radius"]):
		_held += delta
		player().heal(float(data["heal_per_second"]) * delta)
	if _held >= float(data["hold_time"]):
		main.pickups.spawn_named("chest", position, 0.0)
		complete()


func _draw() -> void:
	var r := float(data["radius"])
	var pulse := 0.06 * sin(_age * 3.0)
	draw_circle(Vector2.ZERO, r, Color(0.85, 0.9, 1.0, 0.18 + pulse))
	draw_circle(Vector2.ZERO, r * 0.6, Color(0.92, 0.95, 1.0, 0.16 + pulse))
	for i in 5:
		var a := _age * 0.6 + TAU * i / 5.0
		draw_circle(Vector2.from_angle(a) * r * 0.75, 2.0, Color(1, 1, 0.85, 0.7))
	if started:
		draw_progress_ring(r, _held / float(data["hold_time"]), Color("bcd7ff"))
	else:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(0.8, 0.88, 1.0, 0.5), 1.5)
