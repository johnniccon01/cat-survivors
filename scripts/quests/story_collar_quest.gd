class_name StoryCollarQuest
extends Quest
## A map's story quest: go to the spot, beat the ambush, pick up the clue.
## Sets a story flag. data: flag, ambush, ambush_count, text (string key
## prefix, e.g. "COLLAR" -> QUEST_COLLAR_TITLE...) and poi (the look).

const PICK_RADIUS := 18.0

var _stage := "find"
var _ambush: Array[Enemy] = []


func _key(part: String) -> String:
	return "QUEST_%s_%s" % [data.get("text", "COLLAR"), part]


func title() -> String:
	return tr(_key("TITLE"))


func objective() -> String:
	match _stage:
		"ambush":
			return tr(_key("AMBUSH")) % alive_count(_ambush)
		"pick":
			return tr(_key("PICK"))
	return tr(_key("FIND"))


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
				main.hud.show_banner(tr(_key("FOUND")), 6.0)
				complete()


func _draw() -> void:
	match data.get("poi", "door"):
		"trunk":
			_draw_trunk()
		"tree":
			_draw_tree()
		"antenna":
			_draw_antenna()
		_:
			_draw_door()
	if _stage == "find":
		var y := -34.0 - absf(sin(_age * 3.0)) * 5.0
		draw_circle(Vector2(0, y), 7.0, OUTLINE)
		draw_circle(Vector2(0, y), 6.0, Color("f2c14e"))
		draw_rect(Rect2(-1, y - 4, 2, 5), OUTLINE)
		draw_rect(Rect2(-1, y + 2, 2, 2), OUTLINE)


## Basement: an old trunk with a rolled-up map.
func _draw_trunk() -> void:
	draw_rect(Rect2(-24, -12, 48, 26), OUTLINE)
	draw_rect(Rect2(-23, -11, 46, 24), Color("6b4630"))
	draw_rect(Rect2(-23, -11, 46, 7), Color("8a5a3b"))
	draw_rect(Rect2(-3, -5, 6, 5), Color("c9a24a"))
	if _stage != "find":
		draw_rect(Rect2(8, -18, 16, 6), Color("efe2c0"))
		draw_rect(Rect2(8, -18, 16, 6), OUTLINE, false, 1.0)


## Garden: a dug-up patch under a tree, a key glinting in it.
func _draw_tree() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2(0, 6), 20, 9, 16), Color("5a3e28"))
	for i in 7:
		var a := TAU * i / 7.0
		draw_circle(Vector2.from_angle(a) * Vector2(22, 10) + Vector2(0, 6), 3.0, Color("6b4a32"))
	draw_line(Vector2(-4, 6), Vector2(6, 2), Color("b0784a"), 2.0)
	draw_circle(Vector2(-5, 6), 2.5, Color("b0784a"))


## Rooftop: an antenna with a note pinned to it.
func _draw_antenna() -> void:
	draw_line(Vector2(0, 14), Vector2(0, -24), OUTLINE, 3.0)
	draw_line(Vector2(0, 14), Vector2(0, -24), Color("9aa0a6"), 1.0)
	for k in 3:
		draw_line(Vector2(-12 + k * 2, -18 + k * 8), Vector2(12 - k * 2, -18 + k * 8), Color("9aa0a6"), 1.0)
	draw_rect(Rect2(3, -6, 9, 11), Color("efe2c0"))
	draw_rect(Rect2(3, -6, 9, 11), OUTLINE, false, 1.0)


func _draw_door() -> void:
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
