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
		"bin":
			_draw_bin()
		"bottle":
			_draw_bottle()
		"blueprint":
			_draw_blueprint()
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


## Supermarket: a bin by the checkout with a ticket sticking out.
func _draw_bin() -> void:
	draw_rect(Rect2(-14, -16, 28, 30), OUTLINE)
	draw_rect(Rect2(-13, -15, 26, 28), Color("4a8a5a"))
	draw_rect(Rect2(-15, -18, 30, 5), Color("3a6a46"))
	for x: float in [-7.0, 0.0, 7.0]:
		draw_line(Vector2(x, -10), Vector2(x, 10), Color("3a6a46"), 1.0)
	draw_set_transform(Vector2(6, -22), 0.3)
	draw_rect(Rect2(-6, -4, 12, 7), Color("f2d14e"))
	draw_rect(Rect2(-6, -4, 12, 7), OUTLINE, false, 1.0)
	draw_line(Vector2(-3, -1), Vector2(3, -1), Color("d9534f"), 1.0)
	draw_set_transform(Vector2.ZERO)


## Harbor: a bottle washed up on the sand, a rolled note inside.
func _draw_bottle() -> void:
	draw_colored_polygon(Shapes.ellipse(Vector2(0, 8), 26, 8, 16), Color(0.3, 0.55, 0.75, 0.35))
	draw_set_transform(Vector2.ZERO, -0.4)
	draw_rect(Rect2(-12, -5, 20, 10), OUTLINE)
	draw_rect(Rect2(-11, -4, 18, 8), Color(0.45, 0.75, 0.55, 0.85))
	draw_rect(Rect2(7, -2.5, 6, 5), Color(0.45, 0.75, 0.55, 0.85))
	draw_rect(Rect2(13, -2, 3, 4), Color("a07a4a"))
	draw_rect(Rect2(-8, -2, 12, 4), Color("efe2c0"))
	draw_set_transform(Vector2.ZERO)


## Factory: the Robo-Vacuum's blueprint on a workbench.
func _draw_blueprint() -> void:
	draw_rect(Rect2(-30, -18, 60, 36), OUTLINE)
	draw_rect(Rect2(-29, -17, 58, 34), Color("6b4630"))
	draw_rect(Rect2(-22, -13, 44, 26), Color("2a5a9a"))
	draw_arc(Vector2(0, 0), 9.0, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 1.0)
	draw_line(Vector2(-18, 8), Vector2(18, 8), Color(1, 1, 1, 0.8), 1.0)
	draw_line(Vector2(-18, -9), Vector2(-6, -9), Color(1, 1, 1, 0.8), 1.0)


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
