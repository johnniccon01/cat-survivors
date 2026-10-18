class_name InventoryBar
extends Control
## Two rows of slots in the top-left corner: weapons and passives. Each icon
## shows its level; maxed items say MAX and evolved weapons get a star and
## a gold frame. Empty slots are dark, so the slot limit is visible.

const SLOT := 28.0
const GAP := 4.0
const OUTLINE := Color("2b1d14")
const GOLD := Color("f2c14e")

var player: Player

var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	position = Vector2(10, 22)
	size = Vector2((SLOT + GAP) * (Player.MAX_WEAPONS + 2), (SLOT + GAP) * 2)


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var weapons := player.weapons.get_children()
	for i in maxi(player.max_weapons(), weapons.size()):
		var rect := Rect2(Vector2(i * (SLOT + GAP), 0), Vector2(SLOT, SLOT))
		if i < weapons.size():
			var w: Weapon = weapons[i]
			Icons.draw(self, "weapon", w.id, rect)
			if w.branch != "":
				# One dot per branch rank, coloured by what the branch does.
				for k in w.branch_rank:
					var p := rect.position + Vector2(4 + k * 6, 4)
					draw_circle(p, 2.6, OUTLINE)
					draw_circle(p, 2.0, InventoryBar.branch_color(w.branch_effect()))
			if Icons.is_evolved("weapon", w.id):
				draw_rect(rect.grow(1.0), GOLD, false, 2.0)
				_badge(rect, "★", GOLD)
			else:
				_badge(rect, "MAX" if w.level >= w.max_level() else str(w.level), GOLD if w.level >= w.max_level() else Color.WHITE)
		else:
			_empty(rect)
	var ids := player.passives.keys()
	for i in Player.MAX_PASSIVES:
		var rect := Rect2(Vector2(i * (SLOT + GAP), SLOT + GAP), Vector2(SLOT, SLOT))
		if i < ids.size():
			var id: String = ids[i]
			var lvl: int = player.passives[id]
			var max_lvl: int = GameData.passives[id]["levels"].size()
			Icons.draw(self, "passive", id, rect)
			_badge(rect, "MAX" if lvl >= max_lvl else str(lvl), GOLD if lvl >= max_lvl else Color.WHITE)
		else:
			_empty(rect)


func _empty(rect: Rect2) -> void:
	draw_rect(rect, Color(0, 0, 0, 0.35))
	draw_rect(rect, Color(1, 1, 1, 0.12), false, 1.0)


## Colour that tells the kind of a weapon branch (fire, frost, spark...).
static func branch_color(fx: Dictionary) -> Color:
	if fx.has("burn"):
		return Color("ff8a3d")
	if fx.has("chill"):
		return Color("8fd3ff")
	if fx.has("shock"):
		return Color("ffe066")
	if fx.has("blast"):
		return Color("e04646")
	if fx.has("execute"):
		return Color("f4f1ea")
	if fx.has("vamp"):
		return Color("c94f8a")
	return Color("6cd48a")


## Small number (or MAX / star) in the bottom-right corner of a slot.
func _badge(rect: Rect2, text: String, color: Color) -> void:
	var size := 11 if text.length() > 1 else 13
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := rect.end + Vector2(-w - 1, -2)
	draw_string_outline(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, OUTLINE)
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
