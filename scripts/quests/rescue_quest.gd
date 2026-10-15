class_name RescueQuest
extends Quest
## A cat is trapped and guarded (one guard is an elite). Beat the guards,
## stay close to free it, then walk it to the safe cat bed further away.
## Enemies go after the rescued cat; if it gets knocked down, stand next to
## it to help it up. Once home it joins as a companion and is unlocked.

const FREE_RADIUS := 40.0
const HOME_RADIUS := 40.0
const REVIVE_RADIUS := 30.0
const REVIVE_TIME := 3.0
const ELITE_HP := 5.0

var cat_id := ""

var _stage := "find"
var _guards: Array[Enemy] = []
var _free_progress := 0.0
var _revive := 0.0
var _home := Vector2.ZERO
var _escort: Player
var _t := 0.0


func title() -> String:
	return tr("QUEST_RESCUE_TITLE") % _cat_name()


func objective() -> String:
	match _stage:
		"guards":
			return tr("QUEST_RESCUE_GUARDS") % alive_count(_guards)
		"free":
			return tr("QUEST_RESCUE_FREE") % _cat_name()
		"escort":
			if is_instance_valid(_escort) and _escort.is_dead:
				return tr("QUEST_RESCUE_REVIVE") % _cat_name()
			return tr("QUEST_RESCUE_ESCORT") % _cat_name()
	return tr("QUEST_RESCUE_FIND") % _cat_name()


func target_position() -> Vector2:
	if _stage == "escort":
		return _home
	return position


func _cat_name() -> String:
	return tr("CAT_%s_NAME" % cat_id)


func _on_start() -> void:
	_stage = "guards"
	_guards = spawn_wave_enemies(int(data.get("guard_count", 8)), position, 50.0, 110.0, data.get("guards", ""))
	var elite := spawn_wave_enemies(1, position, 20.0, 30.0)
	for e in elite:
		e.make_elite(ELITE_HP)
	_guards.append_array(elite)


func _tick(delta: float) -> void:
	_t += delta
	match _stage:
		"guards":
			if alive_count(_guards) == 0:
				_stage = "free"
		"free":
			if player_dist() < FREE_RADIUS:
				_free_progress += delta / float(data.get("free_time", 4.0))
			else:
				_free_progress = maxf(_free_progress - delta * 0.1, 0.0)
			if _free_progress >= 1.0:
				_begin_escort()
		"escort":
			if not is_instance_valid(_escort):
				fail()
				return
			if _escort.is_dead:
				if _escort.position.distance_to(player().position) < REVIVE_RADIUS:
					_revive += delta / REVIVE_TIME
				if _revive >= 1.0:
					_revive = 0.0
					_escort.revive(0.5)
			elif _escort.position.distance_to(_home) < HOME_RADIUS:
				var pos := _escort.position
				main.enemies.escorts.erase(_escort)
				_escort.queue_free()
				main.cat_joined(cat_id, pos)
				complete()


func _begin_escort() -> void:
	_stage = "escort"
	var dist: Array = data.get("escort_distance", [480.0, 620.0])
	_home = position + Vector2.from_angle(randf() * TAU) * randf_range(dist[0], dist[1])
	_escort = main.spawn_escort(cat_id, position, float(data.get("escort_hp", 60.0)))
	# A welcoming party: a few enemies wait along the way home.
	spawn_wave_enemies(10, position.lerp(_home, 0.5), 40.0, 120.0)


func _draw() -> void:
	if _stage == "escort":
		_draw_home(_home - position)
		if is_instance_valid(_escort) and _escort.is_dead:
			draw_set_transform(_escort.position - position)
			draw_arc(Vector2.ZERO, REVIVE_RADIUS, 0.0, TAU, 32, Color(0.4, 0.8, 0.4, 0.25), 2.0)
			draw_arc(Vector2.ZERO, REVIVE_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * _revive, 32, Color("6cc46c"), 3.0)
			draw_set_transform(Vector2.ZERO)
	var poi: String = data.get("poi", "box_fort")
	var trapped := _stage != "escort"
	var look := CatArt.look(cat_id)
	match poi:
		"laundry_basket":
			draw_colored_polygon(Shapes.ellipse(Vector2(0, 6), 28, 18), OUTLINE)
			draw_colored_polygon(Shapes.ellipse(Vector2(0, 6), 27, 17), Color("c9a26a"))
			draw_colored_polygon(Shapes.ellipse(Vector2(0, 4), 22, 13), Color("8fb4d9"))
			draw_colored_polygon(Shapes.ellipse(Vector2(-8, 8), 9, 5), Color("e07a7a"))
			if trapped:
				CatArt.draw(self, look, 1, 0.0, false, false, "sad", Vector2(2, -2))
		"bed_cave":
			draw_rect(Rect2(-40, -30, 80, 46), OUTLINE)
			draw_rect(Rect2(-38, -28, 76, 30), Color("5b4a8a"))
			draw_rect(Rect2(-38, 2, 76, 12), Color("15121c"))
			if trapped:
				CatArt.draw(self, look, -1, 0.0, false, false, "sad", Vector2(0, 8))
		"rat_nest":
			for i in 9:
				var a := TAU * i / 9.0
				draw_line(Vector2.from_angle(a) * 14.0, Vector2.from_angle(a + 0.6) * 30.0, Color("8a7a5a"), 3.0)
			draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 26, 16), Color("6a5a3a"))
			if trapped:
				CatArt.draw(self, look, 1, 0.0, false, false, "sad", Vector2(0, -2))
		_:
			for b: Vector2 in [Vector2(-26, -14), Vector2(-26, 2), Vector2(-10, -22), Vector2(6, -22), Vector2(22, -14), Vector2(22, 2)]:
				draw_rect(Rect2(b, Vector2(16, 15)), Color("c8955a"))
				draw_rect(Rect2(b + Vector2(6.5, 0), Vector2(3, 15)), Color("e6d3a8"))
				draw_rect(Rect2(b, Vector2(16, 15)), OUTLINE, false, 1.0)
			if trapped:
				CatArt.draw(self, look, 1, 0.0, false, false, "sad", Vector2(0, 2))
	if _stage == "free":
		draw_progress_ring(FREE_RADIUS, _free_progress, Color("f2c14e"))
	elif _stage == "find":
		_draw_bang()


func _draw_home(at: Vector2) -> void:
	# The safe cat bed with a soft glow.
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	draw_circle(at, HOME_RADIUS + 6.0, Color(0.95, 0.85, 0.4, 0.12 + 0.08 * pulse))
	draw_circle(at, 20.0, OUTLINE)
	draw_circle(at, 19.0, Color("c96a8a"))
	draw_circle(at, 12.0, Color("f1c6d4"))
	draw_arc(at, HOME_RADIUS, 0.0, TAU, 40, Color(0.95, 0.85, 0.4, 0.6), 2.0)


func _draw_bang() -> void:
	var y := -40.0 - absf(sin(_age * 3.0)) * 5.0
	draw_circle(Vector2(0, y), 7.0, OUTLINE)
	draw_circle(Vector2(0, y), 6.0, Color("f2c14e"))
	draw_rect(Rect2(-1, y - 4, 2, 5), OUTLINE)
	draw_rect(Rect2(-1, y + 2, 2, 2), OUTLINE)
