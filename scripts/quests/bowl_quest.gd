class_name BowlQuest
extends Quest
## Guard the food bowl: stay next to it while enemies pour in.

var _held := 0.0
var _spawn_t := 0.0


func title() -> String:
	return tr("QUEST_BOWL_TITLE")


func objective() -> String:
	if not started:
		return tr("QUEST_BOWL_FIND")
	return tr("QUEST_BOWL_HOLD") % ceili(float(data["hold_time"]) - _held)


func start_radius() -> float:
	return float(data["radius"])


func _tick(delta: float) -> void:
	if not started:
		return
	if player_dist() < float(data["radius"]) * 1.4:
		_held += delta
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = float(data["spawn_interval"])
		spawn_wave_enemies(int(data["spawn_count"]), position, 150.0, 200.0)
	if _held >= float(data["hold_time"]):
		main.pickups.spawn_named("chest", position + Vector2(0, 20), 0.0)
		player().heal(player().max_hp)
		complete()


func _draw() -> void:
	draw_rect(Rect2(-22, -10, 44, 20), Color("e07a7a"))
	draw_rect(Rect2(-22, -10, 44, 20), OUTLINE, false, 1.0)
	draw_circle(Vector2.ZERO, 10.0, OUTLINE)
	draw_circle(Vector2.ZERO, 9.0, Color("d9d9e0"))
	draw_circle(Vector2.ZERO, 6.0, Color("9a6a3a"))
	for k: Vector2 in [Vector2(-2, -1), Vector2(2, 1), Vector2(1, -3), Vector2(-3, 2)]:
		draw_rect(Rect2(k, Vector2(2, 2)), Color("6d4a28"))
	var r := float(data["radius"]) * 1.4
	if started:
		draw_progress_ring(r, _held / float(data["hold_time"]), Color("6cc46c"))
	else:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(0.4, 0.8, 0.4, 0.35), 1.0)
