class_name TreasurePanel
extends ColorRect
## Shows what a treasure chest gave. The chest shakes and bursts open first
## (a short pop for a plain chest, rays and a shower of coins for a good one,
## a flash and a rainbow for a legendary one), then the rewards come out as
## cards. A key during the show skips it; once everything is out any key,
## button or click closes it.

signal closed

const REVEAL_STEP := 0.3
const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")
const HEAL_COLOR := Color("5fd38a")
const PLAIN_COLOR := Color("a08ab8")
## How long the chest shakes before it opens, per tier (plain, super, legendary).
const SHAKE_TIME := [0.4, 0.9, 1.5]
## How long the light shows after the lid flies off, before the cards come.
const BURST_TIME := [0.25, 0.55, 0.9]
const CARD_WIDTH := 300.0

var _title: Label
var _show: ChestShow
var _cards: HBoxContainer
var _hint: Label
var _inventory: PanelContainer
var _flash: ColorRect
var _edges: EdgeGlow
var _ready_for_input := false
## A key pressed during the show: the rest comes out at once.
var _fast := false
## Bumped on every open, so a sequence still running from before stops.
var _run := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color(0.08, 0.05, 0.1, 0.8)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_edges = EdgeGlow.new()
	_edges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_edges)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	_title = _label(48, GOLD)
	_title.text = "TREASURE_TITLE"
	box.add_child(_title)
	_show = ChestShow.new()
	_show.custom_minimum_size = Vector2(1040, 190)
	box.add_child(_show)
	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 20)
	_cards.custom_minimum_size = Vector2(0, 230)
	box.add_child(_cards)
	_inventory = UiStyle.inventory_panel(1040, 140)
	box.add_child(_inventory)
	_hint = _label(20, Color("b9a8c9"))
	_hint.text = "TREASURE_HINT"
	box.add_child(_hint)
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 0.9, 0.0)
	add_child(_flash)


## `kind` is the chest ("chest", "boss_chest", "great_chest").
func open(results: Array[Dictionary], kind: String = "chest") -> void:
	_run += 1
	var run := _run
	for child in _cards.get_children():
		child.queue_free()
	_hint.modulate.a = 0.0
	_ready_for_input = false
	_fast = false
	var tier := TreasurePanel.tier_of(results, kind)
	var hud := get_parent() as Hud
	var owned := hud.weapons_text(3, Upgrades.related_ids(results)) if hud != null else ""
	(_inventory.get_meta("text") as RichTextLabel).text = owned
	_inventory.visible = owned != ""
	_inventory.modulate.a = 0.0
	_title.modulate.a = 0.0
	_title.label_settings.font_color = _tier_color(tier)
	_show.start(tier, kind)
	_edges.strength = 0.0
	_edges.queue_redraw()
	visible = true
	# The chest shakes harder and harder...
	await _wait(SHAKE_TIME[tier])
	if run != _run:
		return
	# ...and bursts open.
	_show.burst()
	Audio.play(["chest", "chest_boss", "legendary"][tier], -1.0, 0.0)
	if tier == 2:
		_flash_screen(0.85, 0.6)
	elif tier == 1:
		_flash_screen(0.35, 0.35)
	if tier >= 1:
		_edges.color = _tier_color(tier) if tier == 1 else GOLD
		_edges.create_tween().tween_property(_edges, "strength", 1.0 if tier == 2 else 0.5, 0.4)
	_pop(_title, 0.3)
	await _wait(BURST_TIME[tier])
	if run != _run:
		return
	for offer in results:
		_add_card(offer, tier)
		Audio.play("levelup" if _offer_grade(offer) >= 2 or offer.get("evolved", false) else "coin", -4.0, 0.0)
		await _wait(REVEAL_STEP)
		if run != _run:
			return
	_inventory.modulate.a = 1.0
	_hint.modulate.a = 1.0
	_ready_for_input = true


## 0 plain, 1 super (a boss chest, three rewards or a rare card), 2 legendary
## (an evolution, a great chest or a legendary card).
static func tier_of(results: Array[Dictionary], kind: String) -> int:
	var best := 0
	for offer in results:
		if offer.get("evolved", false) or int(offer.get("grade", 0)) >= 3:
			return 2
		best = maxi(best, int(offer.get("grade", 0)))
	if kind == "great_chest":
		return 2
	return 1 if best >= 1 or results.size() >= 3 or kind == "boss_chest" else 0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var pressed := (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) \
		and event.is_pressed() and not event.is_echo()
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if not _ready_for_input:
		_fast = true
		_show.skip()
		return
	visible = false
	_ready_for_input = false
	closed.emit()


## Waits `seconds` on real time (the game is paused), or not at all once skipped.
func _wait(seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not _fast:
		await get_tree().process_frame
		left -= get_process_delta_time()


## One reward: a card framed in its rarity colour that pops out of the chest.
func _add_card(offer: Dictionary, tier: int) -> void:
	var evolved: bool = offer.get("evolved", false)
	var grade := _offer_grade(offer)
	var frame: Color
	if evolved:
		frame = Upgrades.GRADE_COLORS[3]
	elif offer["kind"] == "heal":
		frame = HEAL_COLOR
	elif grade > 0:
		frame = Upgrades.GRADE_COLORS[grade]
	else:
		frame = PLAIN_COLOR if tier == 0 else GOLD
	var card := PanelContainer.new()
	var sb := UiStyle.box(Color(0.12, 0.08, 0.16, 0.96), frame)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(12)
	sb.shadow_color = Color(frame, 0.45)
	sb.shadow_size = 14 if evolved or grade >= 2 else 6
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	card.add_child(content)
	# A tag on top: evolved, or the card's rarity.
	var tag := _label(18, frame)
	tag.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if evolved:
		tag.text = tr("TREASURE_EVOLVED")
	elif grade > 0:
		tag.text = tr("GRADE_%d" % grade) % (int(offer["level"]) + grade)
	content.add_child(tag)
	var icon_kind: String = {"heal": "passive", "branch": "weapon"}.get(offer["kind"], offer["kind"])
	var icon := IconView.new(icon_kind, offer["id"], 56.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)
	var title := _label(24, GOLD if evolved else Color.WHITE)
	title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if evolved or offer["kind"] == "heal":
		title.text = Upgrades.title(offer)
	else:
		title.text = "%s → %d" % [Upgrades.title(offer), int(offer["level"]) + grade]
	content.add_child(title)
	if offer["kind"] != "heal":
		var desc := _label(16, Color("d8cbe6"))
		desc.text = Upgrades.description(offer)
		desc.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(desc)
	_cards.add_child(card)
	_pop(card, 0.35)
	_show.sparkle(frame)


func _offer_grade(offer: Dictionary) -> int:
	return int(offer.get("grade", 0))


## Fades a control in and lets it overshoot a little as it grows.
func _pop(control: Control, time: float) -> void:
	control.modulate.a = 0.0
	control.scale = Vector2(0.4, 0.4)
	await get_tree().process_frame
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween().set_parallel()
	tween.tween_property(control, "modulate:a", 1.0, time * 0.6)
	tween.tween_property(control, "scale", Vector2.ONE, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _flash_screen(alpha: float, time: float) -> void:
	_flash.color.a = alpha
	_flash.create_tween().tween_property(_flash, "color:a", 0.0, time)


func _tier_color(tier: int) -> Color:
	return [GOLD, Color("c77dff"), Upgrades.GRADE_COLORS[3]][tier]


func _label(size: int, font_color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 5
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## The chest itself, drawn big in pixel style: it shakes, the lid flies
## off, light and coins burst out. Draws round its centre and may spill out
## of its rect.
class ChestShow:
	extends Control

	const PIXEL := 6.0
	const GRAVITY := 900.0

	var _tier := 0
	var _great := false
	var _boss := false
	## Seconds since the show began, and since the lid flew off (-1: shut).
	var _t := 0.0
	var _open_t := -1.0
	## Flying coins and sparks: {pos, vel, color, r, life, age, coin}.
	var _bits: Array[Dictionary] = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS

	func start(tier: int, kind: String) -> void:
		_tier = tier
		_great = kind == "great_chest"
		_boss = kind != "chest"
		_t = 0.0
		_open_t = -1.0
		_bits.clear()
		queue_redraw()

	## Jumps straight to the open chest.
	func skip() -> void:
		if _open_t < 0.0:
			burst()
		_open_t = maxf(_open_t, 0.6)

	func burst() -> void:
		if _open_t >= 0.0:
			return
		_open_t = 0.0
		var coins: int = [10, 28, 60][_tier]
		for i in coins:
			var a := -PI * 0.5 + randf_range(-1.1, 1.1)
			var v := Vector2.from_angle(a) * randf_range(250.0, 520.0 + 120.0 * _tier)
			_bits.append({"pos": Vector2(0, -20), "vel": v, "color": GOLD if randf() < 0.75 else Color("fff4c2"),
				"r": randf_range(4.0, 7.0), "life": randf_range(0.9, 1.6), "age": 0.0, "coin": true})
		if _tier >= 1:
			sparkle(Color("c77dff") if _tier == 1 else Color.WHITE, 24 * _tier)

	## A puff of small sparks out of the chest (a card coming out).
	func sparkle(color: Color, count: int = 10) -> void:
		for i in count:
			var v := Vector2.from_angle(randf() * TAU) * randf_range(80.0, 260.0)
			_bits.append({"pos": Vector2(0, -24), "vel": v, "color": color, "r": randf_range(2.0, 4.0),
				"life": randf_range(0.4, 0.9), "age": 0.0, "coin": false})

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		if _open_t >= 0.0:
			_open_t += delta
		for bit in _bits:
			bit["age"] += delta
			bit["vel"] += Vector2(0, GRAVITY * (1.0 if bit["coin"] else 0.25)) * delta
			bit["pos"] += bit["vel"] * delta
		_bits = _bits.filter(func(b: Dictionary) -> bool: return b["age"] < b["life"])
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5 + Vector2(0, 30)
		if _open_t >= 0.0:
			_draw_light(c)
		# The chest: it shakes harder as the opening comes, hops when it bursts.
		var shake_for: float = TreasurePanel.SHAKE_TIME[_tier]
		var off := Vector2.ZERO
		var tilt := 0.0
		if _open_t < 0.0:
			var k := clampf(_t / shake_for, 0.0, 1.0)
			off.x = sin(_t * (40.0 + 30.0 * k)) * (2.0 + 7.0 * k * k)
			tilt = sin(_t * 33.0) * 0.08 * k
		elif _open_t < 0.25:
			off.y = -sin(_open_t / 0.25 * PI) * 22.0
		Blit.ellipse(self, c + Vector2(0, 8 * PIXEL), 10 * PIXEL, 2 * PIXEL, Color(0, 0, 0, 0.35))
		if _open_t < 0.0:
			_draw_swirl(c, clampf(_t / shake_for, 0.0, 1.0))
		draw_set_transform(c + off, tilt, Vector2.ONE * PIXEL)
		var body := Color("5b3a8a") if _great else Color("8a5a2b")
		var lid := Color("7d52b8") if _great else Color("a8703a")
		var band := Color("ffd27a") if _tier == 2 else GOLD
		draw_rect(Rect2(-8, -4, 16, 10), body)
		draw_rect(Rect2(-8, -4, 16, 10), OUTLINE, false, 0.4)
		draw_rect(Rect2(-8, -4, 2, 10), band)
		draw_rect(Rect2(6, -4, 2, 10), band)
		if _open_t >= 0.0:
			# Light pours out of the open chest.
			var glow := _glow_color()
			draw_rect(Rect2(-7, -5, 14, 2), Color(glow, 0.95))
			draw_rect(Rect2(-6, -6, 12, 1), Color(1, 1, 0.9, 0.8))
		# The lid: shut, or flipped back and away.
		var lid_off := Vector2.ZERO
		var lid_rot := 0.0
		if _open_t >= 0.0:
			var f := clampf(_open_t / 0.3, 0.0, 1.0)
			lid_off = Vector2(-4.0 * f, -9.0 * f + 4.0 * f * f)
			lid_rot = -1.2 * f
		draw_set_transform(c + off + (Vector2(-8, -3) + lid_off) * PIXEL, tilt + lid_rot, Vector2.ONE * PIXEL)
		draw_rect(Rect2(0, -5, 16, 5), lid)
		draw_rect(Rect2(0, -5, 16, 5), OUTLINE, false, 0.4)
		draw_rect(Rect2(0, -5, 2, 5), band)
		draw_rect(Rect2(14, -5, 2, 5), band)
		draw_rect(Rect2(6.5, -2, 3, 3), band)
		draw_set_transform(Vector2.ZERO)
		for bit in _bits:
			var fade := 1.0 - float(bit["age"]) / float(bit["life"])
			var p: Vector2 = c + bit["pos"]
			if bit["coin"]:
				# A coin spinning: it gets thin and wide again.
				var w := absf(cos(float(bit["age"]) * 12.0)) * float(bit["r"]) + 1.0
				draw_rect(Rect2(p - Vector2(w, bit["r"]), Vector2(w * 2.0, bit["r"] * 2.0)), Color(bit["color"], fade))
				draw_rect(Rect2(p - Vector2(w, bit["r"]), Vector2(w * 2.0, bit["r"] * 2.0)), Color(OUTLINE, fade), false, 1.0)
			else:
				Blit.disc(self, p, bit["r"], Color(bit["color"], fade))

	## Behind the open chest: a glow, and for a good chest turning rays
	## (a rainbow for a legendary one).
	func _draw_light(c: Vector2) -> void:
		var grow := clampf(_open_t / 0.4, 0.0, 1.0)
		var glow := _glow_color()
		var pulse := 0.85 + 0.15 * sin(_t * 4.0)
		if _open_t < 0.5:
			var f := _open_t / 0.5
			Blit.ring(self, c, 30.0 + 260.0 * f, 6.0, Color(1, 1, 0.9, 0.8 * (1.0 - f)))
		Blit.disc(self, c + Vector2(0, -20), (60.0 + 40.0 * _tier) * grow, Color(glow, 0.3 * pulse))
		if _tier == 0:
			return
		var rays := 12 if _tier == 1 else 20
		var length := (220.0 if _tier == 1 else 340.0) * grow
		for layer in (1 if _tier == 1 else 2):
			var dir := 1.0 if layer == 0 else -0.6
			for i in rays:
				var a := _t * 0.5 * dir + TAU * i / rays
				var color := glow
				if _tier == 2:
					color = Color.from_hsv(fmod(float(i) / rays + _t * 0.15, 1.0), 0.55, 1.0)
				var tip := Vector2.from_angle(a) * length * (1.0 if i % 2 == 0 else 0.75)
				var o := c + Vector2(0, -20)
				draw_colored_polygon(PackedVector2Array([o, o + tip.rotated(0.07), o + tip.rotated(-0.07)]),
					Color(color, (0.22 if layer == 0 else 0.12) * pulse))
		if _tier == 2:
			# Stars twinkling round the chest.
			for i in 8:
				var a := TAU * i / 8.0 + _t * 0.3
				var p := c + Vector2(0, -20) + Vector2.from_angle(a) * (150.0 + 20.0 * sin(_t * 3.0 + i))
				var s := 6.0 + 4.0 * sin(_t * 6.0 + i * 1.7)
				draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(1, 1, 0.9, 0.9), 2.0)
				draw_line(p - Vector2(0, s), p + Vector2(0, s), Color(1, 1, 0.9, 0.9), 2.0)

	## Before it opens: sparks circle the chest, closing in and speeding up.
	func _draw_swirl(c: Vector2, k: float) -> void:
		var count: int = [6, 12, 20][_tier]
		var glow := _glow_color()
		for i in count:
			var a := TAU * i / count + _t * (3.0 + 6.0 * k)
			var r := (120.0 - 60.0 * k) * (0.8 + 0.2 * sin(i * 1.7))
			var p := c + Vector2(0, -20) + Vector2(cos(a) * r, sin(a) * r * 0.55)
			Blit.disc(self, p, 3.0 + 2.0 * k, Color(glow, 0.5 + 0.5 * k))
			Blit.disc(self, p, 1.5, Color(1, 1, 0.95, 0.9))

	func _glow_color() -> Color:
		return [GOLD, Color("c77dff"), Color("ffd27a")][_tier]


## The screen edges glow (gold for a legendary chest) once a good chest opens.
class EdgeGlow:
	extends Control

	const BAND := 140.0
	const STEPS := 10

	var color := Color.TRANSPARENT
	var strength := 0.0
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(delta: float) -> void:
		_t += delta
		if strength > 0.0 and is_visible_in_tree():
			queue_redraw()

	func _draw() -> void:
		if strength <= 0.0:
			return
		var pulse := 0.8 + 0.2 * sin(_t * 5.0)
		for i in STEPS:
			var d := BAND * i / STEPS
			var w := BAND / STEPS
			var col := Color(color, strength * pulse * 0.12 * (1.0 - float(i) / STEPS))
			draw_rect(Rect2(0, d, size.x, w), col)
			draw_rect(Rect2(0, size.y - d - w, size.x, w), col)
			draw_rect(Rect2(d, 0, w, size.y), col)
			draw_rect(Rect2(size.x - d - w, 0, w, size.y), col)
