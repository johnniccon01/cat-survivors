class_name Memorials
extends Node2D
## The memorial stones of retired cats (Profile.retired) on the Cemetery map:
## a quiet little lawn a bit north of where the night starts, a stone per cat
## with its name, generation and a paw in its fur colour, candles that
## flicker. Sit by a stone for a moment and, once a night, it heals you.

const SPACING := 40.0
const PER_ROW := 6
const SIT_RADIUS := 26.0
const SIT_TIME := 1.2
const HEAL := 0.3
const OUTLINE := Color("2b1d14")
const STONE := Color("8a8a94")

var main: Node
var player: Player
var _stones: Array = []
var _sit := 0.0
var _used := false
var _t := 0.0
var _font: Font


func _ready() -> void:
	z_index = 1
	_font = ThemeDB.fallback_font
	var list: Array = Profile.retired
	var rows := ceili(list.size() / float(PER_ROW))
	for i in list.size():
		var row := i / PER_ROW
		var in_row := mini(PER_ROW, list.size() - row * PER_ROW)
		var x := (i % PER_ROW - (in_row - 1) * 0.5) * SPACING
		_stones.append({"pos": Vector2(x, row * 46.0 - (rows - 1) * 23.0), "data": list[i]})


## Stones in world positions (tests, the sitting check).
func stone_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for s: Dictionary in _stones:
		out.append(position + (s["pos"] as Vector2))
	return out


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _used or player == null or player.is_dead:
		return
	# Tests: hold the cat by the first stone until it has sat there.
	if "--memorial-walk" in GameData.args() and not _stones.is_empty():
		player.position = position + (_stones[0]["pos"] as Vector2) + Vector2(0, 14)
	var near := ""
	for s: Dictionary in _stones:
		if player.position.distance_to(position + (s["pos"] as Vector2)) < SIT_RADIUS:
			near = String(s["data"]["cat"])
			break
	_sit = _sit + delta if near != "" else 0.0
	if _sit >= SIT_TIME:
		_used = true
		player.heal(player.max_hp * HEAL)
		Audio.play("angel", -6.0, 0.0)
		var ring := RingWave.new()
		ring.enemies = get_tree().get_first_node_in_group("enemy_manager")
		ring.position = player.position
		ring.max_radius = 60.0
		ring.damage = 0.0
		ring.knockback = 0.0
		ring.color = Color("fff3c0")
		get_parent().add_child(ring)
		BotLog.event("memorial_heal")
		if main != null and main.get("hud") != null:
			main.hud.show_banner(tr("MEMORIAL_BLESS") % tr("CAT_%s_NAME" % near), 3.5)


func _draw() -> void:
	if _stones.is_empty():
		return
	# A darker patch of lawn with a low hedge round the stones.
	var w := minf(_stones.size(), PER_ROW) * SPACING + 30.0
	var h := ceili(_stones.size() / float(PER_ROW)) * 46.0 + 40.0
	var area := Rect2(-w * 0.5, -h * 0.5 - 6.0, w, h)
	draw_rect(area, Color(0.12, 0.2, 0.1, 0.55))
	draw_rect(area, Color(0.2, 0.32, 0.16, 0.9), false, 3.0)
	for s: Dictionary in _stones:
		_draw_stone(s["pos"], s["data"])
	if not _used and _sit > 0.0:
		var k := _sit / SIT_TIME
		draw_arc(player.position - position, 16.0, -PI * 0.5, -PI * 0.5 + TAU * k, 24, Color("fff3c0"), 2.0)


func _draw_stone(at: Vector2, data: Dictionary) -> void:
	var look := CatArt.look(String(data["cat"]))
	var fur: Color = look.get("fur", Color("d98c4a"))
	# Shadow, the stone with a rounded top, a lit left edge.
	var pts := PackedVector2Array()
	for i in 9:
		var a := PI + PI * i / 8.0
		pts.append(at + Vector2(cos(a) * 9.0, -12.0 + sin(a) * 7.0))
	pts.append(at + Vector2(9, 8))
	pts.append(at + Vector2(-9, 8))
	draw_colored_polygon(Shapes.ellipse(at + Vector2(2, 9), 12.0, 3.0, 12), Color(0, 0, 0, 0.3))
	draw_colored_polygon(pts, STONE)
	draw_line(at + Vector2(-8, -12), at + Vector2(-8, 7), STONE.lightened(0.25), 1.0)
	draw_line(at + Vector2(8, -12), at + Vector2(8, 7), STONE.darkened(0.25), 1.0)
	draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
	# A paw in the cat's fur colour, and the generation under it.
	draw_circle(at + Vector2(0, -5), 3.0, fur)
	for toe: Vector2 in [Vector2(-3.5, -9.5), Vector2(-1.2, -11.5), Vector2(1.2, -11.5), Vector2(3.5, -9.5)]:
		draw_circle(at + toe, 1.2, fur)
	var gen := "%d." % int(data["gen"])
	draw_string(_font, at + Vector2(-8, 5), gen, HORIZONTAL_ALIGNMENT_CENTER, 16, 7, Color("3a3a44"))
	# Flowers on one side, a flickering candle on the other.
	draw_circle(at + Vector2(-11, 8), 1.6, Color("e0628f"))
	draw_circle(at + Vector2(-13, 6), 1.4, Color("f2d14e"))
	draw_rect(Rect2(at + Vector2(10, 3), Vector2(2, 5)), Color("f4f1ea"))
	var flick := 0.7 + 0.3 * sin(_t * 9.0 + at.x)
	draw_circle(at + Vector2(11, 2), 1.4, Color(1.0, 0.8, 0.35, flick))
	draw_circle(at + Vector2(11, 2), 4.0, Color(1.0, 0.75, 0.3, 0.12 * flick))
	# The name under the stone.
	var name := tr("CAT_%s_NAME" % String(data["cat"]))
	draw_string_outline(_font, at + Vector2(-30, 20), name, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, 3, OUTLINE)
	draw_string(_font, at + Vector2(-30, 20), name, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color("e8e4dc"))
