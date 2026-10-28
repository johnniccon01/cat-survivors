class_name DuelQuest
extends Quest
## A rival cat waits on its turf. Step in and a fence goes up: no other
## enemies get in, you can't get out, and regular spawning stops until one of
## you wins. Beat it and it respects you enough to join (and unlock).

const ARENA_RADIUS := 170.0

var cat_id := ""

var _rival: Enemy


func title() -> String:
	return tr("QUEST_DUEL_TITLE") % tr("CAT_%s_NAME" % cat_id)


func objective() -> String:
	if started:
		return tr("QUEST_DUEL_FIGHT") % tr("CAT_%s_NAME" % cat_id)
	return tr("QUEST_DUEL_FIND") % tr("CAT_%s_NAME" % cat_id)


## During the fight the arrow points at the rival.
func target_position() -> Vector2:
	return _rival.position if started and is_instance_valid(_rival) else position


func start_radius() -> float:
	return 150.0


func _on_start() -> void:
	var minute := floorf(main.spawner.elapsed / 60.0)
	# Rivals start beatable and grow with the night (+25 % health per minute).
	_rival = main.enemies.spawn(data["rival"], position, maxf(1.0 + minute * 0.25, main.spawner.hp_multiplier()))
	# ...and with the cat's level, so a duel at level 30 is still a duel.
	main.spawner.toughen(_rival)
	main.enemies.arena = {"center": position, "radius": ARENA_RADIUS, "rival": _rival}
	main.spawner.paused = true
	main.hud.show_banner(tr("QUEST_DUEL_CHALLENGE") % tr("CAT_%s_NAME" % cat_id), 3.0)


func _tick(_delta: float) -> void:
	if started and (not is_instance_valid(_rival) or _rival.dead):
		_open_arena()
		Profile.add_stat("duels_won")
		main.cat_joined(cat_id)
		complete()


func _open_arena() -> void:
	main.enemies.arena = {}
	main.spawner.paused = false


func _exit_tree() -> void:
	if started:
		_open_arena()


func _draw() -> void:
	# Turf: a round rug with paw prints.
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 60, 40, 32), Color("7a2f3a"))
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, 52, 34, 32), Color("9a4450"))
	draw_polyline(Shapes.closed(Shapes.ellipse(Vector2.ZERO, 60, 40, 32)), OUTLINE, 1.0)
	for p: Vector2 in [Vector2(-34, -8), Vector2(-22, 12), Vector2(26, -14), Vector2(36, 8)]:
		draw_circle(p, 3.0, Color("c2707b"))
		for t: Vector2 in [Vector2(-3, -4), Vector2(0, -5), Vector2(3, -4)]:
			draw_circle(p + t, 1.2, Color("c2707b"))
	if not started:
		CatArt.draw(self, CatArt.look(cat_id), -1, 0.0, false, false, "angry", Vector2(0, -4))
		draw_arc(Vector2.ZERO, ARENA_RADIUS, 0.0, TAU, 64, Color(0.9, 0.3, 0.3, 0.25), 1.0)
		return
	# Fence: posts with a rope between them.
	draw_arc(Vector2.ZERO, ARENA_RADIUS, 0.0, TAU, 64, Color("e8dcc0"), 2.0)
	for i in 24:
		var p := Vector2.from_angle(TAU * i / 24.0) * ARENA_RADIUS
		draw_rect(Rect2(p - Vector2(2.5, 6), Vector2(5, 8)), OUTLINE)
		draw_rect(Rect2(p - Vector2(1.5, 5), Vector2(3, 6)), Color("8a5a3b"))
