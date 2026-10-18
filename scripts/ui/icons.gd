class_name Icons
## Small procedural icons for weapons and passives, drawn on a 16x16 grid and
## scaled to whatever size is asked for. Evolved weapons reuse their base
## weapon's symbol on a gold background.

const OUTLINE := Color("2b1d14")
const WEAPON_BG := Color("4a3460")
const PASSIVE_BG := Color("2f5a5e")
const EVOLVED_BG := Color("8a6a1e")

## Evolved weapon -> base weapon whose symbol it shares.
static var _base_of: Dictionary = {}


static func base_weapon(id: String) -> String:
	if _base_of.is_empty():
		for wid: String in GameData.weapons:
			var evo: Dictionary = GameData.weapons[wid].get("evolve", {})
			if not evo.is_empty():
				_base_of[evo["into"]] = wid
	return _base_of.get(id, id)


static func is_evolved(kind: String, id: String) -> bool:
	return kind == "weapon" and GameData.weapons.get(id, {}).get("evolved", false)


## Draws the icon for (kind, id) into `rect` on canvas item `ci`.
static func draw(ci: CanvasItem, kind: String, id: String, rect: Rect2) -> void:
	var evolved := is_evolved(kind, id)
	var bg := EVOLVED_BG if evolved else (WEAPON_BG if kind == "weapon" else PASSIVE_BG)
	ci.draw_rect(rect, OUTLINE)
	ci.draw_rect(rect.grow(-1.0), bg)
	ci.draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, rect.size.y * 0.35)), bg.lightened(0.12))
	var s := rect.size.x / 16.0
	ci.draw_set_transform(rect.position, 0.0, Vector2(s, s))
	if kind == "weapon":
		_weapon(ci, base_weapon(id))
	else:
		_passive(ci, id)
	ci.draw_set_transform(Vector2.ZERO)


static func _weapon(ci: CanvasItem, id: String) -> void:
	match id:
		"SCRATCH":
			for i in 3:
				ci.draw_line(Vector2(4 + i * 3, 3), Vector2(2 + i * 3, 13), Color.WHITE, 1.5)
		"YARN":
			ci.draw_circle(Vector2(8, 8), 5.0, OUTLINE)
			ci.draw_circle(Vector2(8, 8), 4.2, Color("e0628f"))
			ci.draw_line(Vector2(4, 7), Vector2(12, 9), Color("f7a8c4"), 1.0)
			ci.draw_line(Vector2(7, 4), Vector2(9, 12), Color("f7a8c4"), 1.0)
			ci.draw_line(Vector2(12, 11), Vector2(14, 14), Color("e0628f"), 1.0)
		"HAIRBALL":
			var pts := PackedVector2Array()
			for i in 10:
				pts.append(Vector2(8, 8) + Vector2.from_angle(TAU * i / 10.0) * (5.0 if i % 2 == 0 else 3.8))
			ci.draw_colored_polygon(pts, Color("7a5235"))
			ci.draw_polyline(Shapes.closed(pts), OUTLINE, 1.0)
		"CATNIP":
			var leaf := PackedVector2Array([Vector2(3, 13), Vector2(5, 5), Vector2(12, 3), Vector2(11, 10)])
			ci.draw_colored_polygon(leaf, Color("6cc46c"))
			ci.draw_polyline(Shapes.closed(leaf), OUTLINE, 1.0)
			ci.draw_line(Vector2(3, 13), Vector2(11, 5), Color("3f7a3a"), 1.0)
		"FISHBONES":
			ci.draw_line(Vector2(3, 8), Vector2(12, 8), Color("eae4d3"), 1.5)
			for x: float in [5.0, 7.5, 10.0]:
				ci.draw_line(Vector2(x, 5), Vector2(x, 11), Color("eae4d3"), 1.0)
			ci.draw_circle(Vector2(13, 8), 1.8, Color("eae4d3"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(3, 8), Vector2(1, 5), Vector2(1, 11)]), Color("eae4d3"))
		"LASER":
			ci.draw_line(Vector2(2, 13), Vector2(12, 4), Color(1, 0.3, 0.3, 0.6), 2.0)
			ci.draw_circle(Vector2(12, 4), 2.5, Color("ff3b3b"))
			ci.draw_circle(Vector2(12, 4), 1.0, Color.WHITE)
			ci.draw_rect(Rect2(1, 12, 4, 2), Color("c9ced2"))
		"MILK":
			ci.draw_colored_polygon(Shapes.ellipse(Vector2(8, 11), 6, 2.5, 12), Color("f4f1ea"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 2), Vector2(11, 8), Vector2(8, 10), Vector2(5, 8)]), Color("f4f1ea"))
			ci.draw_polyline(PackedVector2Array([Vector2(8, 2), Vector2(11, 8), Vector2(8, 10), Vector2(5, 8), Vector2(8, 2)]), OUTLINE, 1.0)
		"BELL":
			var bell := PackedVector2Array([Vector2(3, 12), Vector2(4, 6), Vector2(8, 3), Vector2(12, 6), Vector2(13, 12)])
			ci.draw_colored_polygon(bell, Color("f2c14e"))
			ci.draw_polyline(Shapes.closed(bell), OUTLINE, 1.0)
			ci.draw_circle(Vector2(8, 13), 1.5, OUTLINE)
		"FEATHER":
			ci.draw_line(Vector2(3, 13), Vector2(13, 3), Color("e8e0d0"), 1.0)
			var vane := PackedVector2Array([Vector2(4, 12), Vector2(6, 6), Vector2(13, 3), Vector2(10, 10)])
			ci.draw_colored_polygon(vane, Color("6fc2ff"))
			ci.draw_polyline(Shapes.closed(vane), OUTLINE, 1.0)
		"MOUSE_TOY":
			ci.draw_line(Vector2(3, 11), Vector2(1, 9), Color("d9a0a8"), 1.0)
			ci.draw_colored_polygon(Shapes.ellipse(Vector2(8, 10), 5.5, 3.5, 12), OUTLINE)
			ci.draw_colored_polygon(Shapes.ellipse(Vector2(8, 10), 4.5, 2.6, 12), Color("9a9aa2"))
			ci.draw_circle(Vector2(11, 7), 1.6, Color("d9a0a8"))
			ci.draw_line(Vector2(7, 7), Vector2(7, 4), Color("c9a24a"), 1.0)
			ci.draw_line(Vector2(5, 4), Vector2(9, 4), Color("f2c14e"), 1.5)
		"COBWEB":
			for i in 6:
				ci.draw_line(Vector2(8, 8), Vector2(8, 8) + Vector2.from_angle(TAU * i / 6.0) * 6.5, Color("eef0f4"), 1.0)
			for r: float in [2.5, 4.5, 6.5]:
				ci.draw_arc(Vector2(8, 8), r, 0.0, TAU, 6, Color("eef0f4"), 1.0)
		"SPRINKLER":
			ci.draw_circle(Vector2(8, 9), 2.5, OUTLINE)
			ci.draw_circle(Vector2(8, 9), 1.8, Color("4a8a4a"))
			for i in 3:
				var d := Vector2.from_angle(-PI * 0.5 + (i - 1) * 0.7)
				for k in 3:
					ci.draw_circle(Vector2(8, 9) + d * (3.5 + k * 1.8), 0.9, Color("8fd3ff"))
		"ANTENNA":
			ci.draw_line(Vector2(5, 14), Vector2(5, 3), Color("c9ced2"), 1.0)
			ci.draw_line(Vector2(2, 5), Vector2(8, 5), Color("c9ced2"), 1.0)
			ci.draw_line(Vector2(3, 8), Vector2(7, 8), Color("c9ced2"), 1.0)
			ci.draw_polyline(PackedVector2Array([Vector2(9, 3), Vector2(12, 7), Vector2(10, 8), Vector2(14, 13)]), Color("ffe066"), 1.5)
		"TIN_CAN_TOSS":
			ci.draw_rect(Rect2(5, 5, 7, 9), OUTLINE)
			ci.draw_rect(Rect2(6, 6, 5, 7), Color("c9ced2"))
			ci.draw_rect(Rect2(6, 8, 5, 3), Color("d9534f"))
			ci.draw_arc(Vector2(10, 4), 3.0, PI, TAU, 6, Color("ffe066"), 1.0)
		"WAVE":
			ci.draw_polyline(PackedVector2Array([Vector2(2, 11), Vector2(5, 7), Vector2(8, 6), Vector2(11, 8), Vector2(9, 10)]), Color("e8f4ff"), 1.5)
			ci.draw_line(Vector2(2, 13), Vector2(14, 13), Color("5a9ae6"), 2.0)
			ci.draw_circle(Vector2(12, 6), 1.0, Color.WHITE)
		"DRONE_BUDDY":
			ci.draw_circle(Vector2(8, 9), 2.5, Color("3a3e44"))
			ci.draw_circle(Vector2(8, 9), 1.0, Color("5ad1e6"))
			for d: Vector2 in [Vector2(4, 5), Vector2(12, 5), Vector2(4, 13), Vector2(12, 13)]:
				ci.draw_line(Vector2(8, 9), d, Color("9aa0a6"), 1.0)
				ci.draw_line(d + Vector2(-2, 0), d + Vector2(2, 0), Color("e8f4ff"), 1.0)
		_:
			ci.draw_circle(Vector2(8, 8), 4.0, Color.WHITE)


static func _passive(ci: CanvasItem, id: String) -> void:
	match id:
		"MIGHT":
			for i in 3:
				var x := 4.0 + i * 3.5
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.2, 13), Vector2(x + 1.2, 13), Vector2(x + 1.5, 4)]), Color("f3e7d0"))
		"SPEED":
			ci.draw_circle(Vector2(10, 10), 3.0, Color("f3a9b8"))
			for p: Vector2 in [Vector2(7, 6), Vector2(10, 5), Vector2(13, 6)]:
				ci.draw_circle(p, 1.3, Color("f3a9b8"))
			for y: float in [8.0, 10.0, 12.0]:
				ci.draw_line(Vector2(1, y), Vector2(5, y), Color(1, 1, 1, 0.7), 1.0)
		"MAXHP":
			ci.draw_colored_polygon(Shapes.ellipse(Vector2(8, 10), 6, 3, 12), Color("d9d9e0"))
			ci.draw_colored_polygon(Shapes.ellipse(Vector2(8, 9), 4.5, 1.8, 12), Color("ffffff"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 6), Vector2(5, 3), Vector2(6.5, 2), Vector2(8, 3.5), Vector2(9.5, 2), Vector2(11, 3)]), Color("e04646"))
		"COOLDOWN":
			for z: Array in [[Vector2(3, 10), 4.0], [Vector2(8, 6), 3.0], [Vector2(12, 3), 2.0]]:
				var p: Vector2 = z[0]
				var w: float = z[1]
				ci.draw_polyline(PackedVector2Array([p, p + Vector2(w, 0), p + Vector2(0, w), p + Vector2(w, w)]), Color("8fd3ff"), 1.0)
		"AREA":
			ci.draw_arc(Vector2(8, 8), 5.5, 0.0, TAU * 0.8, 16, Color("d98c4a"), 2.5)
			ci.draw_arc(Vector2(8, 8), 2.5, 0.0, TAU * 0.8, 10, Color("d98c4a"), 1.5)
		"MAGNET":
			ci.draw_arc(Vector2(8, 7), 4.5, PI, TAU, 10, Color("d94848"), 3.0)
			ci.draw_rect(Rect2(2.2, 7, 3, 5), Color("d94848"))
			ci.draw_rect(Rect2(10.8, 7, 3, 5), Color("d94848"))
			ci.draw_rect(Rect2(2.2, 11, 3, 2), Color("e8ecef"))
			ci.draw_rect(Rect2(10.8, 11, 3, 2), Color("e8ecef"))
		"AMOUNT":
			for c: Vector2 in [Vector2(5, 9), Vector2(11, 9)]:
				ci.draw_circle(c, 3.0, Color("d98c4a"))
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -1), c + Vector2(-2, -4), c + Vector2(0, -2)]), Color("d98c4a"))
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(3, -1), c + Vector2(2, -4), c + Vector2(0, -2)]), Color("d98c4a"))
		"REGEN":
			ci.draw_rect(Rect2(3, 6, 10, 7), Color("9aa0a6"))
			ci.draw_rect(Rect2(3, 6, 10, 2), Color("c9ced2"))
			ci.draw_rect(Rect2(4, 9, 8, 3), Color("5aa9e6"))
		"ARMOR":
			ci.draw_arc(Vector2(8, 8), 5.0, 0.0, TAU, 16, Color("c94f4f"), 2.0)
			ci.draw_circle(Vector2(8, 13), 2.0, Color("f2c14e"))
		"DURATION":
			var glass := PackedVector2Array([Vector2(4, 2), Vector2(12, 2), Vector2(8, 8), Vector2(12, 14), Vector2(4, 14), Vector2(8, 8)])
			ci.draw_colored_polygon(glass, Color("e8dcc0"))
			ci.draw_polyline(Shapes.closed(glass), OUTLINE, 1.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(6, 13), Vector2(10, 13), Vector2(8, 10)]), Color("c9a24a"))
		"PROJ_SPEED":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 5), Vector2(14, 8), Vector2(8, 11)]), Color("f3e7d0"))
			for y: float in [5.5, 8.0, 10.5]:
				ci.draw_line(Vector2(2, y), Vector2(7, y), Color("8fd3ff"), 1.0)
		"LUCK":
			# Beckoning lucky cat paw with a coin.
			ci.draw_circle(Vector2(8, 10), 4.5, Color("f4f1ea"))
			ci.draw_rect(Rect2(10, 3, 3, 6), Color("f4f1ea"))
			ci.draw_circle(Vector2(11.5, 3), 1.8, Color("f4f1ea"))
			ci.draw_circle(Vector2(8, 11), 2.5, Color("f2c14e"))
			ci.draw_arc(Vector2(8, 10), 4.5, 0.0, TAU, 12, Color("e04646"), 1.0)
		"HEAL":
			ci.draw_colored_polygon(Shapes.ellipse(Vector2(9, 8), 5, 2.5, 12), Color("b8cfdc"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(4, 8), Vector2(1, 5), Vector2(1, 11)]), Color("8fa9b8"))
			ci.draw_rect(Rect2(11, 7, 1, 1), OUTLINE)
		_:
			ci.draw_circle(Vector2(8, 8), 4.0, Color.WHITE)
