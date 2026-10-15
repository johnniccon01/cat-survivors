class_name FridgeQuest
extends Quest
## Midnight snack: stay by the fridge until it opens, then beat everything
## that comes out of it.

const OPEN_RADIUS := 45.0

var _open := 0.0
var _opened := false
var _leftovers: Array[Enemy] = []


func title() -> String:
	return tr("QUEST_FRIDGE_TITLE")


func objective() -> String:
	if not started:
		return tr("QUEST_FRIDGE_FIND")
	if not _opened:
		return tr("QUEST_FRIDGE_OPEN")
	return tr("QUEST_FRIDGE_FIGHT") % alive_count(_leftovers)


func start_radius() -> float:
	return OPEN_RADIUS


func _tick(delta: float) -> void:
	if not started:
		return
	if not _opened:
		if player_dist() < OPEN_RADIUS * 1.3:
			_open += delta / float(data["open_time"])
		if _open >= 1.0:
			_opened = true
			_leftovers = spawn_wave_enemies(int(data["enemy_count"]), position, 30.0, 80.0)
		return
	if alive_count(_leftovers) == 0:
		main.pickups.spawn_named("chest", position + Vector2(0, 30), 0.0)
		main.pickups.spawn_named("heart", position + Vector2(-16, 30), 15.0)
		main.pickups.spawn_named("heart", position + Vector2(16, 30), 15.0)
		complete()


func _draw() -> void:
	draw_rect(Rect2(-24, -20, 48, 40), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(-26, -22, 48, 40), Color("f1f3f5"))
	draw_rect(Rect2(-26, -22, 48, 40), OUTLINE, false, 1.0)
	if _opened:
		# Door swung open, cold light spilling out.
		draw_colored_polygon(Shapes.ellipse(Vector2(0, 30), 40, 14), Color(0.75, 0.9, 1.0, 0.25))
		draw_rect(Rect2(-26, 18, 48, 6), Color("d8dde2"))
		draw_rect(Rect2(-26, 18, 48, 6), OUTLINE, false, 1.0)
	else:
		draw_line(Vector2(-26, -2), Vector2(22, -2), OUTLINE, 1.0)
		draw_rect(Rect2(14, -14, 3, 8), Color("9aa3aa"))
		draw_rect(Rect2(14, 4, 3, 8), Color("9aa3aa"))
		for m: Array in [[Vector2(-18, -16), Color("e04646")], [Vector2(-8, -12), Color("5aa9e6")], [Vector2(-14, 6), Color("f2c14e")]]:
			draw_rect(Rect2(m[0], Vector2(5, 4)), m[1])
	if started and not _opened:
		draw_progress_ring(OPEN_RADIUS, _open, Color("8fd3ff"))
