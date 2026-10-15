class_name RescueQuest
extends Quest
## A cat is trapped at a point of interest and guarded. Defeat the guards,
## then stay close for a few seconds to free it; it joins as a companion and
## is unlocked for good.

const FREE_RADIUS := 40.0

var cat_id := ""

var _stage := "find"
var _guards: Array[Enemy] = []
var _free_progress := 0.0
var _t := 0.0


func title() -> String:
	return tr("QUEST_RESCUE_TITLE") % tr("CAT_%s_NAME" % cat_id)


func objective() -> String:
	match _stage:
		"guards":
			return tr("QUEST_RESCUE_GUARDS") % alive_count(_guards)
		"free":
			return tr("QUEST_RESCUE_FREE") % tr("CAT_%s_NAME" % cat_id)
	return tr("QUEST_RESCUE_FIND") % tr("CAT_%s_NAME" % cat_id)


func _on_start() -> void:
	_stage = "guards"
	_guards = spawn_wave_enemies(int(data.get("guard_count", 8)), position, 50.0, 110.0, data.get("guards", ""))


func _tick(delta: float) -> void:
	_t += delta
	match _stage:
		"guards":
			if alive_count(_guards) == 0:
				_stage = "free"
		"free":
			if player_dist() < FREE_RADIUS:
				_free_progress += delta / float(data.get("free_time", 6.0))
			else:
				_free_progress = maxf(_free_progress - delta * 0.1, 0.0)
			if _free_progress >= 1.0:
				main.cat_joined(cat_id)
				complete()


func _draw() -> void:
	var poi: String = data.get("poi", "box_fort")
	var look := CatArt.look(cat_id)
	match poi:
		"laundry_basket":
			draw_colored_polygon(Shapes.ellipse(Vector2(0, 6), 28, 18), OUTLINE)
			draw_colored_polygon(Shapes.ellipse(Vector2(0, 6), 27, 17), Color("c9a26a"))
			draw_colored_polygon(Shapes.ellipse(Vector2(0, 4), 22, 13), Color("8fb4d9"))
			draw_colored_polygon(Shapes.ellipse(Vector2(-8, 8), 9, 5), Color("e07a7a"))
			CatArt.draw(self, look, 1, 0.0, false, false, "sad", Vector2(2, -2))
			for i in 3:
				var b := Vector2(-18 + i * 16, -14 - sin(_t * 2.0 + i) * 4.0)
				draw_arc(b, 3.0, 0.0, TAU, 10, Color(1, 1, 1, 0.8), 1.0)
		"bed_cave":
			draw_rect(Rect2(-40, -30, 80, 46), OUTLINE)
			draw_rect(Rect2(-38, -28, 76, 30), Color("5b4a8a"))
			draw_rect(Rect2(-38, 2, 76, 12), Color("15121c"))
			CatArt.draw(self, look, -1, 0.0, false, false, "sad", Vector2(0, 8))
		_:
			# Box fort: a U of cardboard boxes around the trapped cat.
			for b: Vector2 in [Vector2(-26, -14), Vector2(-26, 2), Vector2(-10, -22), Vector2(6, -22), Vector2(22, -14), Vector2(22, 2)]:
				draw_rect(Rect2(b, Vector2(16, 15)), Color("c8955a"))
				draw_rect(Rect2(b + Vector2(6.5, 0), Vector2(3, 15)), Color("e6d3a8"))
				draw_rect(Rect2(b, Vector2(16, 15)), OUTLINE, false, 1.0)
			CatArt.draw(self, look, 1, 0.0, false, false, "sad", Vector2(0, 2))
	if _stage == "free":
		draw_progress_ring(FREE_RADIUS, _free_progress, Color("f2c14e"))
	elif _stage == "find":
		_draw_bang()


func _draw_bang() -> void:
	var y := -40.0 - absf(sin(_age * 3.0)) * 5.0
	draw_circle(Vector2(0, y), 7.0, OUTLINE)
	draw_circle(Vector2(0, y), 6.0, Color("f2c14e"))
	draw_rect(Rect2(-1, y - 4, 2, 5), OUTLINE)
	draw_rect(Rect2(-1, y + 2, 2, 2), OUTLINE)
