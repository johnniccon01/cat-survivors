class_name InventoryBar
extends Control
## Two rows of slots in the top-left corner under the health bar: weapons
## (bigger) and passives. Each icon shows its level; maxed and evolved items
## get a gold frame and a star. Empty slots are a faint outline, so the slot
## limit is visible without covering the floor.

const SLOT := 40.0
const PASSIVE_SLOT := 28.0
const GAP := 5.0
const FRAME := Color("8c5f36")
const OUTLINE := Color("2b1d14")
const GOLD := Color("f2c14e")

var player: Player

var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = BoxStyle.bold_font()
	position = Vector2(14, 62)
	size = Vector2((SLOT + GAP) * (Player.MAX_WEAPONS + 2), SLOT + PASSIVE_SLOT + GAP * 2 + 20 * 4)


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
			var top := Icons.is_evolved("weapon", w.id) or w.level >= w.max_level()
			_slot(rect, top)
			Icons.draw(self, "weapon", w.id, rect.grow(-4.0))
			if w.branch != "":
				# One dot per branch rank, coloured by what the branch does.
				for k in w.branch_rank:
					var p := rect.position + Vector2(6 + k * 6, 6)
					draw_circle(p, 2.6, OUTLINE)
					draw_circle(p, 2.0, InventoryBar.branch_color(w.branch_effect()))
			if top:
				_star(rect)
			else:
				_badge(rect, str(w.level), Color.WHITE, 12)
		else:
			_empty(rect)
	var ids := player.passives.keys()
	var y0 := SLOT + GAP
	for i in Player.MAX_PASSIVES:
		var rect := Rect2(Vector2(i * (PASSIVE_SLOT + GAP), y0), Vector2(PASSIVE_SLOT, PASSIVE_SLOT))
		if i < ids.size():
			var id: String = ids[i]
			var lvl: int = player.passives[id]
			var max_lvl: int = GameData.passives[id]["levels"].size()
			_slot(rect, lvl >= max_lvl)
			Icons.draw(self, "passive", id, rect.grow(-3.0))
			if lvl >= max_lvl:
				_star(rect, 1)
			else:
				_badge(rect, str(lvl), Color.WHITE, 11)
		else:
			_empty(rect)
	# Active weapon combos under the slots: both icons and the name.
	var y := SLOT + PASSIVE_SLOT + GAP * 2 + 2
	for c: String in player.combos:
		var pair: Array = Combos.LIST[c]
		var x := 0.0
		for group: Array in pair:
			var shown: String = group[0]
			for w: Weapon in weapons:
				if w.base_id() in group:
					shown = w.id
					break
			Icons.draw(self, "weapon", shown, Rect2(Vector2(x, y), Vector2(16, 16)))
			x += 18.0
		draw_string_outline(_font, Vector2(x + 2, y + 13), tr("COMBO_%s_NAME" % c), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 6, OUTLINE)
		draw_string(_font, Vector2(x + 2, y + 13), tr("COMBO_%s_NAME" % c), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("bfe8ff"))
		y += 19.0
	# The soul bell's souls tonight.
	if Profile.soul_live >= 0.0:
		var b := Profile.soul_bonus(Profile.soul_live)
		var text := tr("HUD_SOUL") % [roundi(Profile.soul_live), roundi(float(b["might"]) * 100.0)]
		draw_circle(Vector2(8, y + 8), 6.0, OUTLINE)
		draw_circle(Vector2(8, y + 8), 4.5, Color("9a7aff"))
		draw_string_outline(_font, Vector2(20, y + 13), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 6, OUTLINE)
		draw_string(_font, Vector2(20, y + 13), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e6d3ab"))


func _empty(rect: Rect2) -> void:
	var poly := BoxStyle.blob(rect.grow(-1.0), 11 + int(rect.position.x) + int(rect.position.y) * 3)
	poly.append(poly[0])
	draw_polyline(poly, Color(BoxStyle.CREAM, 0.3), 2.0, true)


## A filled slot: a crooked piece of cream cardboard with a hard shadow, gold
## when the item is at its best.
func _slot(rect: Rect2, gold: bool) -> void:
	var s := 11 + int(rect.position.x) + int(rect.position.y) * 3
	BoxStyle.draw_blob(self, rect.grow(-1.0), s, Color("ffe7a0") if gold else Color("f4e8cb"), GOLD.darkened(0.45) if gold else BoxStyle.INK, 2.6)


## The gold star of a maxed or evolved item, in the bottom-right corner.
func _star(rect: Rect2, scale: int = 2) -> void:
	var size := Vector2(7, 7) * scale
	PixelGlyph.draw(self, "star", Rect2(rect.end - size + Vector2(2, 2), size))


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
func _badge(rect: Rect2, text: String, _color: Color, size: int = 13) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var r := Rect2(rect.end - Vector2(maxf(w + 8.0, 16.0) - 3.0, 15.0), Vector2(maxf(w + 8.0, 16.0), 16.0))
	BoxStyle.draw_blob(self, r, 5 + text.length(), BoxStyle.RED, BoxStyle.DARK, 2.0, Vector2(1, 1.5))
	draw_string(_font, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + 13.0 - (13 - size) * 0.3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("fff7e2"))
