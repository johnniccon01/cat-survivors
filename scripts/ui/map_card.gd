class_name MapCard
extends Control
## A map on the selection screen: a little picture of its floor with the
## final boss, its name, and whether it is cleared, locked or how long the
## longest night lasted.

const GROUNDS := {
	"apartment": [Color("8a5a3b"), Color("6b4630")],
	"basement": [Color("6a6e72"), Color("4a4e52")],
	"garden": [Color("5e9e4a"), Color("4a8a3a")],
	"rooftop": [Color("a8503a"), Color("3e3e46")],
	"supermarket": [Color("dcd8cc"), Color("b8c4cc")],
	"harbor": [Color("e2cc94"), Color("1f4a6a")],
	"factory": [Color("5a5650"), Color("8a6a2a")],
}

var stage_id := ""
var selected := false
var _t := 0.0


## Difficulty 1-5 from the map's challenge factor (1.0 to 2.2).
static func difficulty(id: String) -> int:
	return clampi(roundi((float(GameData.stages[id].get("challenge", 1.0)) - 1.0) / 0.3) + 1, 1, 5)


func _init(p_stage: String = "") -> void:
	stage_id = p_stage
	custom_minimum_size = Vector2(196, 128)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var stage: Dictionary = GameData.stages[stage_id]
	var open := Profile.is_stage_unlocked(stage_id)
	var r := Rect2(Vector2.ZERO, size)
	var pic := Rect2(4, 4, size.x - 8, 74)
	var colors: Array = GROUNDS.get(stage.get("theme", "apartment"), GROUNDS["apartment"])
	draw_rect(r, UiStyle.PANEL_HOVER if selected else UiStyle.PANEL)
	# The floor: two-tone stripes, darker when locked.
	var dim := 0.0 if open else 0.7
	draw_rect(pic, (colors[0] as Color).darkened(dim))
	for i in 6:
		draw_rect(Rect2(pic.position + Vector2(i * pic.size.x / 6.0, 0), Vector2(pic.size.x / 12.0, pic.size.y)), (colors[1] as Color).darkened(dim))
	var boss: String = stage.get("final_boss", "")
	if boss != "":
		_draw_boss(boss, pic.get_center() + Vector2(0, 6 + sin(_t * 2.0) * 2.0), open)
	if not open:
		# A padlock.
		var c := pic.get_center()
		draw_arc(c + Vector2(0, -4), 7.0, PI, TAU, 12, Color("d9cce6"), 3.0)
		draw_rect(Rect2(c + Vector2(-10, -4), Vector2(20, 16)), Color("d9cce6"))
		draw_rect(Rect2(c + Vector2(-2, 1), Vector2(4, 6)), UiStyle.PANEL)
	elif stage_id in Profile.cleared_stages:
		draw_string(ThemeDB.fallback_font, pic.position + Vector2(pic.size.x - 26, 26), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("6cd48a"))
	if open:
		# Difficulty: stars filled up to the rating.
		var n := difficulty(stage_id)
		for i in 5:
			_draw_star(pic.position + Vector2(10 + i * 13, 10), 5.5, Color("ff9a2a") if i < n else Color(0.2, 0.15, 0.25, 0.8))
	var font := ThemeDB.fallback_font
	var title := tr("STAGE_%s_NAME" % stage_id) if open else "???"
	draw_string(font, Vector2(8, 100), title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 18, UiStyle.GOLD if selected else UiStyle.TEXT)
	var sub := tr("SELECT_MAP_BEST") % Profile.get_stat("best_minutes:" + stage_id) if open else tr("STAGE_%s_HINT" % stage_id)
	var best_dark := int(Profile.darkness_best.get(stage_id, 0))
	if open and best_dark > 0:
		sub = tr("SELECT_MAP_DARKNESS") % best_dark
	draw_string(font, Vector2(8, 120), sub, HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 13, UiStyle.MUTED)
	draw_rect(r, UiStyle.GOLD if selected else UiStyle.BORDER, false, 3.0 if selected else 2.0)


func _draw_star(c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		pts.append(c + Vector2.from_angle(-PI * 0.5 + i * PI / 5.0) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, UiStyle.OUTLINE)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.7)
	draw_colored_polygon(inner, color)


func _draw_boss(id: String, at: Vector2, known: bool) -> void:
	var data: Dictionary = GameData.enemies[id]
	var tint := Color.WHITE if known else Color(0.12, 0.09, 0.15)
	if data.get("shape", "") == "cat":
		var lk := CatArt.look(data.get("cat", "MICA")).duplicate()
		lk["silhouette"] = not known
		CatArt.draw(self, lk, 1, _t * 4.0, false, false, "angry", at + Vector2(0, 8), 1.6, false)
		return
	var sprite := Sprites.enemy(id)
	if sprite.is_empty():
		return
	draw_set_transform(at, 0.0, Vector2(2.0, 2.0))
	Sprites.draw_frame(self, sprite, int(_t * 3.0) % 2, 0, tint)
	draw_set_transform(Vector2.ZERO)
