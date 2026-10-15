class_name DuelQuest
extends Quest
## A rival cat waits on its turf. Step in and it attacks as a boss; beat it
## and it respects you enough to join (and unlock).

var cat_id := ""

var _rival: Enemy


func title() -> String:
	return tr("QUEST_DUEL_TITLE") % tr("CAT_%s_NAME" % cat_id)


func objective() -> String:
	if started:
		return tr("QUEST_DUEL_FIGHT") % tr("CAT_%s_NAME" % cat_id)
	return tr("QUEST_DUEL_FIND") % tr("CAT_%s_NAME" % cat_id)


func start_radius() -> float:
	return 150.0


func _on_start() -> void:
	var minute := floorf(main.spawner.elapsed / 60.0)
	_rival = main.enemies.spawn(data["rival"], position, 1.0 + minute * 0.08)
	main.hud.show_banner(tr("QUEST_DUEL_CHALLENGE") % tr("CAT_%s_NAME" % cat_id), 3.0)


func _tick(_delta: float) -> void:
	if started and (not is_instance_valid(_rival) or _rival.dead):
		main.cat_joined(cat_id)
		complete()


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
