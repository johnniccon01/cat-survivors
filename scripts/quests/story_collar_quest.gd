class_name StoryCollarQuest
extends Quest
## Apartment story: rats were seen by the front door. Beat the ambush and
## find Luna's collar, which hints she was dragged down to the basement.
## Sets a story flag that the basement picks up.

const PICK_RADIUS := 18.0

var _stage := "find"
var _ambush: Array[Enemy] = []


func title() -> String:
	return tr("QUEST_COLLAR_TITLE")


func objective() -> String:
	match _stage:
		"ambush":
			return tr("QUEST_COLLAR_AMBUSH") % alive_count(_ambush)
		"pick":
			return tr("QUEST_COLLAR_PICK")
	return tr("QUEST_COLLAR_FIND")


func _on_start() -> void:
	_stage = "ambush"
	_ambush = spawn_wave_enemies(int(data.get("ambush_count", 14)), position, 40.0, 120.0, data.get("ambush", "RAT"))
	if not _ambush.is_empty():
		_ambush[0].make_elite(5.0)


func _tick(_delta: float) -> void:
	match _stage:
		"ambush":
			if alive_count(_ambush) == 0:
				_stage = "pick"
		"pick":
			if player_dist() < PICK_RADIUS:
				Profile.set_flag(data["flag"])
				main.hud.show_banner(tr("QUEST_COLLAR_FOUND"), 6.0)
				complete()


func _draw() -> void:
	# Front-door mat with shoes and the collar.
	draw_rect(Rect2(-36, -20, 72, 40), Color("6b4630"))
	draw_rect(Rect2(-32, -16, 64, 32), Color("8a6a42"))
	for i in 6:
		draw_line(Vector2(-30 + i * 12, -14), Vector2(-30 + i * 12, 14), Color("7a5a3a"), 1.0)
	for shoe: Vector2 in [Vector2(-22, -6), Vector2(-14, 4)]:
		draw_colored_polygon(Shapes.ellipse(shoe, 7, 3.5, 10), Color("2a2a30"))
	# Little rat footprints leading away.
	for i in 5:
		var p := Vector2(30 + i * 9, -4 + (i % 2) * 6)
		draw_circle(p, 1.2, Color(0.2, 0.15, 0.1, 0.6))
	# Luna's purple collar with its bell.
	draw_arc(Vector2(10, 2), 6.0, 0.0, TAU, 16, OUTLINE, 3.0)
	draw_arc(Vector2(10, 2), 6.0, 0.0, TAU, 16, Color("7a5cc4"), 2.0)
	draw_circle(Vector2(10, 9), 2.0, Color("f2c14e"))
	if _stage == "find":
		var y := -34.0 - absf(sin(_age * 3.0)) * 5.0
		draw_circle(Vector2(0, y), 7.0, OUTLINE)
		draw_circle(Vector2(0, y), 6.0, Color("f2c14e"))
		draw_rect(Rect2(-1, y - 4, 2, 5), OUTLINE)
		draw_rect(Rect2(-1, y + 2, 2, 2), OUTLINE)
