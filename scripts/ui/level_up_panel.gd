class_name LevelUpPanel
extends ColorRect
## Level-up screen in the shoe-box look: the title on cardboard with tape and
## a paw stamp, the offers as LevelCard notes, under them the reroll button
## and a row of what the cat already has. Pick with mouse, arrows +
## Enter/Space, or number keys 1-4. Shift + number (or the small x in a
## card's corner) banishes that card for the rest of the run.

signal chosen(offer: Dictionary)
signal reroll_requested
signal banish_requested(index: int)

## Ignore input for a moment so a held key doesn't pick a card by accident.
const INPUT_DELAY := 0.35

var _header: Control
var _title_text := ""
var _reroll: BoxButton
var _reroll_row: HBoxContainer
var _cards: HBoxContainer
var _inventory: PanelContainer
var _owned: HBoxContainer
var _player: Player
var _offers: Array[Dictionary] = []
var _ready_for_input := false
var _banish_left := 0


func _ready() -> void:
	color = Color(0.06, 0.04, 0.03, 0.76)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	_header = Control.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_header)

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 16)
	box.add_child(_cards)

	# A new offer: a cardboard button with its key and how many are left.
	_reroll_row = HBoxContainer.new()
	_reroll_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_reroll_row)
	_reroll = BoxButton.make("", 22, 23, 1.0, false)
	_reroll.pressed.connect(func() -> void:
		if _ready_for_input:
			_ready_for_input = false
			reroll_requested.emit())
	_reroll_row.add_child(_reroll)

	# What the cat already has, as a row of icons; what the cards touch is ringed.
	_inventory = PanelContainer.new()
	var sb := StyleBoxEmpty.new()
	sb.set_content_margin_all(12)
	sb.content_margin_left = 20
	_inventory.add_theme_stylebox_override("panel", sb)
	_inventory.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_inventory.custom_minimum_size.x = 760
	box.add_child(_inventory)
	_inventory.add_child(BoxBoard.make("dark", Vector2.ZERO, Vector2(10, 10), 14, -0.6))
	_owned = HBoxContainer.new()
	_owned.add_theme_constant_override("separation", 8)
	_inventory.add_child(_owned)

	var hint := BoxStyle.hud_label(16, HORIZONTAL_ALIGNMENT_CENTER, BoxStyle.CREAM)
	hint.text = "CHOICE_HINT"
	box.add_child(hint)


## The title on a piece of cardboard, taped at the corners, a paw stamped on it.
func _build_header(text: String) -> void:
	for c in _header.get_children():
		c.queue_free()
	var font := BoxStyle.head_font()
	var fs := BoxStyle.fit_size(text, font, 54, 700.0, 28)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var s := Vector2(maxf(tw + 120.0, 300.0), fs * 1.45)
	_header.custom_minimum_size = s + Vector2(40, 8)
	var off := Vector2(20, 4)
	var board := BoxBoard.make("board", off, s, 2, -1.0)
	_header.add_child(board)
	var label := BoxStyle.label(text, fs, BoxStyle.INK, true)
	label.size = s
	label.position = Vector2.ZERO
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	board.add_child(label)
	_header.add_child(BoxBoard.make("tape", off + Vector2(-14, -6), Vector2(72, 24), 3, -35.0))
	_header.add_child(BoxBoard.make("tape", off + Vector2(s.x - 58.0, -6), Vector2(72, 24), 4, 36.0))
	_header.add_child(BoxBoard.make("stamp", off + Vector2(-8, -8), Vector2(46, 46), 5, -18.0))


## `title` replaces the "Level N!" heading (e.g. a boss chest's pick).
func open(level: int, offers: Array[Dictionary], rerolls: int = 0, title: String = "", banishes: int = 0) -> void:
	_offers = offers
	_banish_left = banishes
	_reroll_row.visible = rerolls > 0
	_reroll.relabel(tr("LEVELUP_REROLL") % rerolls)
	_title_text = title if title != "" else tr("LEVEL_UP_TITLE") % level
	_build_header(_title_text)
	for child in _cards.get_children():
		child.queue_free()
	var hud := get_parent() as Hud
	_player = hud.get_parent().get("player") if hud != null else null
	for i in offers.size():
		_cards.add_child(_make_card(i, offers[i]))
	_fill_owned(Upgrades.related_ids(offers))
	visible = true
	_ready_for_input = false
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_ready_for_input = true
	if visible and _cards.get_child_count() > 0:
		(_cards.get_child(0).get_child(0) as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _ready_for_input:
		return
	if event.is_action_pressed("reroll") and _reroll_row.visible:
		get_viewport().set_input_as_handled()
		_ready_for_input = false
		reroll_requested.emit()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < _offers.size():
			if event.shift_pressed:
				_banish(index)
			else:
				_pick(index)
			get_viewport().set_input_as_handled()


func _pick(index: int) -> void:
	if not _ready_for_input:
		return
	_ready_for_input = false
	visible = false
	chosen.emit(_offers[index])


func _banish(index: int) -> void:
	if not _ready_for_input or _banish_left <= 0 or Upgrades.banish_key(_offers[index]) == "":
		return
	_ready_for_input = false
	banish_requested.emit(index)


func _make_card(index: int, offer: Dictionary) -> VBoxContainer:
	var column := VBoxContainer.new()
	var card := LevelCard.new()
	column.add_child(card)
	card.setup(index, offer, _player, _new_combo(offer), _banish_left, _banish.bind(index))
	card.pressed.connect(_pick.bind(index))
	return column


## The row under the cards: every weapon and skill the cat has, with its
## level; the ones the offered cards touch are ringed, and the first of them is
## named with what evolves it.
func _fill_owned(related: Array) -> void:
	for child in _owned.get_children():
		child.queue_free()
	_inventory.visible = _player != null
	if _player == null:
		return
	var head := BoxStyle.hud_label(26, HORIZONTAL_ALIGNMENT_LEFT, BoxStyle.CREAM, true)
	head.text = tr("LEVELUP_HAVE")
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_owned.add_child(head)
	var note := ""
	for w: Weapon in _player.weapons.get_children():
		var hot := w.id in related
		_owned.add_child(_owned_slot("weapon", w.id, w.level, w.max_level(), hot, 44.0, tr("WEAPON_%s_DESC" % w.id)))
		if hot and note == "":
			note = "%s %d/%d" % [Upgrades.item_name("weapon", w.id), w.level, w.max_level()]
			var evolve: Dictionary = w.data.get("evolve", {})
			if not evolve.is_empty():
				note += "\n" + tr("PAUSE_EVOLVE_WITH") % Upgrades.item_name("passive", evolve["with"])
	for i in maxi(_player.max_weapons() - _player.weapon_count(), 0):
		_owned.add_child(_owned_slot("", "", 0, 0, false, 44.0, ""))
	if not _player.passives.is_empty():
		var gap := Control.new()
		gap.custom_minimum_size.x = 6
		_owned.add_child(gap)
	for id: String in _player.passives:
		var hot := id in related
		_owned.add_child(_owned_slot("passive", id, int(_player.passives[id]), (GameData.passives[id]["levels"] as Array).size(), hot, 36.0, tr("PASSIVE_%s_DESC" % id)))
		if hot and note == "":
			note = "%s %d/%d" % [Upgrades.item_name("passive", id), int(_player.passives[id]), (GameData.passives[id]["levels"] as Array).size()]
	var text := BoxStyle.label(note, 14, BoxStyle.CREAM)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_owned.add_child(text)


## One slot of the "you have" row: icon in a crooked frame, level on a red
## badge, a blue marker ring if the offered cards touch it.
func _owned_slot(kind: String, id: String, level: int, max_level: int, hot: bool, side: float, tip: String) -> Control:
	var slot := _OwnedSlot.new()
	slot.kind = kind
	slot.id = id
	slot.level = level
	slot.max_level = max_level
	slot.hot = hot
	slot.custom_minimum_size = Vector2(side, side)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.tooltip_text = tip
	return slot


class _OwnedSlot:
	extends Control
	var kind := ""
	var id := ""
	var level := 0
	var max_level := 0
	var hot := false

	func _draw() -> void:
		var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
		if kind == "":
			var poly := BoxStyle.blob(r, 9)
			poly.append(poly[0])
			draw_polyline(poly, Color(BoxStyle.CREAM, 0.35), 2.0, true)
			return
		var maxed := level >= max_level
		BoxStyle.draw_blob(self, r, 9 + level, Color("ffe7a0") if maxed else Color("f4e8cb"), BoxStyle.INK, 2.4, Vector2(1.5, 2))
		Icons.draw(self, kind, id, r.grow(-4.0))
		if hot:
			BoxStyle.draw_ring(self, Rect2(Vector2.ZERO, size), 5 + level, Color("5aaeff"), 3.0, 4.0)
		var t := "★" if maxed else str(level)
		var font := BoxStyle.bold_font()
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var b := Rect2(size - Vector2(maxf(w + 8.0, 16.0) - 3.0, 15.0), Vector2(maxf(w + 8.0, 16.0), 16.0))
		BoxStyle.draw_blob(self, b, 4 + level, BoxStyle.RED, BoxStyle.DARK, 2.0, Vector2(1, 1.5))
		draw_string(font, Vector2(b.position.x + (b.size.x - w) * 0.5, b.position.y + 12.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff7e2"))


## The weapon combo taking this new weapon would start, or "".
func _new_combo(offer: Dictionary) -> String:
	if offer["kind"] != "weapon" or offer["level"] != 1:
		return ""
	var cat: Variant = get_tree().current_scene.get("player") if get_tree().current_scene != null else null
	if not (cat is Player):
		return ""
	var owned: Array = []
	for w: Weapon in (cat as Player).weapons.get_children():
		owned.append(w.base_id())
	var now := Combos.active(owned)
	owned.append(Icons.base_weapon(offer["id"]))
	for c in Combos.active(owned):
		if c not in now:
			return c
	return ""


