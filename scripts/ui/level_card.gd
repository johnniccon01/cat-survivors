class_name LevelCard
extends Button
## One offer on the level-up screen: a light cardboard note with a marker
## frame in the colour of its rarity and paws for the rarity at the top, the
## kind on a strip of tape, the icon in a crooked round frame, the name, the
## level tag, what the cat has of it and what it does. The chosen card is
## lifted, circled in red marker and has a paw under it. The note is drawn
## from `_draw` (so only when the focus changes); the texts are Labels.

const W := 270.0
const H := 358.0
const LIFT := 12.0
const BELOW := 30.0

var offer: Dictionary
var grade := 0
var rim := Color("7a5a3a")
var index := 0
var banish_button: BoxButton

var _lift := Control.new()
var _up := false


static func kind_tape(kind: String) -> Color:
	match kind:
		"weapon":
			return Color("f0a487")
		"passive":
			return Color("e8c27a")
		"heal":
			return Color("a6dc98")
		"branch":
			return Color("e6a3b8")
	return BoxStyle.TAPE


func setup(index_: int, offer_: Dictionary, player: Player, combo: String, banish_left: int, banish_cb: Callable) -> void:
	index = index_
	offer = offer_
	grade = int(offer.get("grade", 0))
	rim = Upgrades.GRADE_COLORS[grade] if grade > 0 else Color("7a5a3a")
	custom_minimum_size = Vector2(W, H + LIFT + BELOW)
	focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, empty)
	_lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lift.position = Vector2(0, LIFT)
	_lift.size = Vector2(W, H)
	add_child(_lift)
	focus_entered.connect(_set_up.bind(true))
	focus_exited.connect(_set_up.bind(false))
	mouse_entered.connect(grab_focus)
	_build(player, combo, banish_left, banish_cb)


func _set_up(on: bool) -> void:
	_up = on
	_lift.position.y = 2.0 if on else LIFT
	queue_redraw()


func _build(player: Player, combo: String, banish_left: int, banish_cb: Callable) -> void:
	var body := BoxStyle.body_font()
	var head := BoxStyle.head_font()
	var inner_w := W - 40.0
	# Top row: the paws of the rarity (left) and the kind on tape (right).
	var paws := PawRating.new()
	paws.set_rating(grade + 1, grade + 1, 17.0)
	paws.empty_color = BoxStyle.RED
	paws.position = Vector2(18, 16)
	paws.size = paws.custom_minimum_size
	_lift.add_child(paws)
	var kind: String = offer["kind"]
	var kind_tag := TapeTag.new()
	kind_tag.look_seed = 5 + index
	kind_tag.tilt = 2.0 if index % 2 == 0 else -2.0
	kind_tag.set_tag(tr("KIND_" + kind.to_upper()), kind_tape(kind), W - 44.0 - paws.size.x - 36.0, 17)
	kind_tag.position = Vector2(W - 16.0 - kind_tag.size.x, 11)
	_lift.add_child(kind_tag)
	# The icon in a crooked frame.
	var frame := _IconFrame.new()
	frame.size = Vector2(78, 78)
	frame.position = Vector2((W - 78.0) * 0.5, 46)
	frame.look_seed = 17 + index * 5
	frame.icon_kind = {"heal": "passive", "branch": "weapon"}.get(kind, kind)
	frame.icon_id = offer["id"]
	_lift.add_child(frame)
	# Name.
	var title := Upgrades.title(offer)
	var name_size := BoxStyle.fit_size(title, head, 31, inner_w, 20)
	var name_label := BoxStyle.label(title, name_size, BoxStyle.INK, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(inner_w, 0)
	name_label.position = Vector2(20, 132)
	_lift.add_child(name_label)
	var y := 132.0 + float(name_size) * 1.3
	if name_size == 20 and head.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x > inner_w:
		y += 22.0
	# Level tag ("Lv 2/5", "New!"), then what the cat already has of it.
	var tag_text := Upgrades.tag(offer)
	if tag_text != "":
		var tag := TapeTag.new()
		tag.look_seed = 9 + index
		tag.tilt = -1.5
		var is_new: bool = offer["level"] == 1 and grade == 0
		tag.set_tag(tag_text, Color("f6d870") if is_new else (rim.lightened(0.55) if grade > 0 else Color("e6d9b8")), inner_w, 16)
		tag.position = Vector2((W - tag.size.x) * 0.5, y)
		_lift.add_child(tag)
		y += tag.size.y + 4.0
	if player != null:
		for note: Array in Upgrades.owned_notes(player, offer):
			var chip := BoxStyle.label(note[0], 13, Color("2c5a26") if note[1] else Color("8a3f0c"))
			chip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			chip.size = Vector2(inner_w, 0)
			chip.position = Vector2(20, y)
			_lift.add_child(chip)
			var lines := body.get_multiline_string_size(note[0], HORIZONTAL_ALIGNMENT_CENTER, inner_w, 13).y
			y += lines + 2.0
	# What it does: shrinks a little if a long text would run out of the card.
	var text := Upgrades.description(offer, false)
	if combo != "":
		text += "\n" + tr("COMBO_NEW") % [tr("COMBO_%s_NAME" % combo), tr("COMBO_%s_DESC" % combo)]
	var room := H - 14.0 - y - (26.0 if banish_left > 0 and Upgrades.banish_key(offer) != "" else 0.0)
	var fs := 16
	while fs > 10 and body.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, fs).y > room:
		fs -= 1
	var desc := BoxStyle.label(text, fs, Color("3a2713"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size = Vector2(inner_w, room)
	desc.position = Vector2(20, y + 2.0)
	desc.clip_contents = true
	_lift.add_child(desc)
	# The number key that picks the card, on a small ink blob in the corner.
	var key := _KeyBlob.new()
	key.text = str(index + 1)
	key.size = Vector2(30, 30)
	key.position = Vector2(-6, -6)
	_lift.add_child(key)
	# Banish: a small marker x in the bottom corner (Shift + number does the same).
	if banish_left > 0 and Upgrades.banish_key(offer) != "":
		banish_button = BoxButton.make("×", 20, 41 + index, 2.0, false, true)
		banish_button.tooltip_text = tr("BANISH_BUTTON") % [index + 1, banish_left]
		banish_button.size = banish_button.custom_minimum_size
		banish_button.position = Vector2(W - banish_button.size.x - 12.0, H - banish_button.size.y - 10.0)
		banish_button.pressed.connect(banish_cb)
		_lift.add_child(banish_button)


func _draw() -> void:
	var base := Transform2D(0.0, Vector2(0, _lift.position.y))
	var sz := Vector2(W, H)
	# The note: light cardboard, a rarity-coloured marker frame inside.
	BoxStyle.draw_board(self, sz, 31 + index * 7, Color("fbf1d6"), Color("ecdcb2"), base, Vector2(6, 7), Color(0.31, 0.19, 0.08, 0.08))
	var inner := PackedVector2Array()
	for p in BoxStyle.torn(sz - Vector2(16, 16), 71 + index * 3, 1.6):
		inner.append(p + Vector2(8, 8))
	inner.append(inner[0])
	draw_set_transform_matrix(base)
	draw_polyline(inner, Color(rim, 0.95), 4.0 + grade, true)
	if _up:
		BoxStyle.draw_ring(self, Rect2(Vector2.ZERO, sz), 4 + index, BoxStyle.RED, 5.0, 6.0, base)
		BoxStyle.draw_paw(self, Vector2(W * 0.5, H + 10.0), 28.0, Color(0, 0, 0, 0.55), -8.0, base * Transform2D(0.0, Vector2(1.5, 2.0)))
		BoxStyle.draw_paw(self, Vector2(W * 0.5, H + 10.0), 28.0, Color("ff6a5c"), -8.0, base)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## The offered item's icon in a crooked round frame.
class _IconFrame:
	extends Control
	var look_seed := 1
	var icon_kind := "weapon"
	var icon_id := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		BoxStyle.draw_blob(self, Rect2(Vector2(2, 2), size - Vector2(4, 4)), look_seed, Color("fdf6e0"), BoxStyle.INK, 3.0, Vector2(2, 3))
		Icons.draw(self, icon_kind, icon_id, Rect2(Vector2(11, 11), size - Vector2(22, 22)))


## The card's number on a little ink blob.
class _KeyBlob:
	extends Control
	var text := ""

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		BoxStyle.draw_blob(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), 8, BoxStyle.INK, BoxStyle.DARK, 1.5, Vector2(1, 1.5))
		var font := BoxStyle.bold_font()
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(font, Vector2((size.x - w) * 0.5, size.y * 0.5 + 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, BoxStyle.CREAM)
