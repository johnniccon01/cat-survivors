class_name LevelUpPanel
extends ColorRect
## Level-up screen: shows the offers as cards. Pick with mouse, arrows +
## Enter/Space, or number keys 1-4. Shift + number (or the small x in a
## card's corner) banishes that card for the rest of the run. Under the
## cards: the reroll button and a row of what the cat already has.

signal chosen(offer: Dictionary)
signal reroll_requested
signal banish_requested(index: int)

## Ignore input for a moment so a held key doesn't pick a card by accident.
const INPUT_DELAY := 0.35

const CARD_BG := Color("2b2238")
const CARD_BORDER := Color("4b3d61")
const CARD_FOCUS := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _title: Label
var _reroll: Button
var _reroll_left: Label
var _reroll_row: HBoxContainer
var _cards: HBoxContainer
var _inventory: PanelContainer
var _owned: HBoxContainer
var _player: Player
var _offers: Array[Dictionary] = []
var _ready_for_input := false
var _banish_left := 0


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.7)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	_title = _label(44, CARD_FOCUS)
	box.add_child(_title)

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 20)
	box.add_child(_cards)

	# A new offer: a real button with its key, and how many are left.
	_reroll_row = HBoxContainer.new()
	_reroll_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_reroll_row.add_theme_constant_override("separation", 10)
	box.add_child(_reroll_row)
	_reroll = UiStyle.click_button("LEVELUP_REROLL_BUTTON", 0, 16)
	UiStyle.add_key(_reroll, "R")
	_reroll.pressed.connect(func() -> void:
		if _ready_for_input:
			_ready_for_input = false
			reroll_requested.emit())
	_reroll_row.add_child(_reroll)
	_reroll_left = UiStyle.plain("", 14, UiStyle.MUTED)
	_reroll_row.add_child(_reroll_left)

	# What the cat already has, as a row of icons; what the cards touch glows.
	_inventory = PanelContainer.new()
	var sb := UiStyle.frame(Color(0.13, 0.1, 0.17, 0.96), Color("4b3d61"), 2)
	sb.set_content_margin_all(12)
	_inventory.add_theme_stylebox_override("panel", sb)
	_inventory.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_inventory.custom_minimum_size.x = 700
	box.add_child(_inventory)
	_owned = HBoxContainer.new()
	_owned.add_theme_constant_override("separation", 8)
	_inventory.add_child(_owned)


## `title` replaces the "Level N!" heading (e.g. a boss chest's pick).
func open(level: int, offers: Array[Dictionary], rerolls: int = 0, title: String = "", banishes: int = 0) -> void:
	_offers = offers
	_banish_left = banishes
	_reroll_row.visible = rerolls > 0
	_reroll_left.text = tr("PAUSE_LEFT") % rerolls
	_title.text = title if title != "" else tr("LEVEL_UP_TITLE") % level
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
	column.add_theme_constant_override("separation", 6)
	var card := Button.new()
	column.add_child(card)
	card.custom_minimum_size = Vector2(260, 330)
	card.focus_mode = Control.FOCUS_ALL
	var grade := int(offer.get("grade", 0))
	var tint: Color = Upgrades.GRADE_COLORS[grade] if grade > 0 else Color("9c8bb8")
	var border: Color = Upgrades.GRADE_COLORS[grade] if grade > 0 else CARD_BORDER
	card.add_theme_stylebox_override("normal", _style(border, grade))
	card.add_theme_stylebox_override("hover", _style(CARD_FOCUS, grade))
	card.add_theme_stylebox_override("focus", _style(CARD_FOCUS, grade))
	card.add_theme_stylebox_override("pressed", _style(CARD_FOCUS, grade))
	card.pressed.connect(_pick.bind(index))
	card.mouse_entered.connect(card.grab_focus)

	# A thin strip of the card's rarity colour along the top.
	var strip := ColorRect.new()
	strip.color = tint
	strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	strip.offset_left = 10
	strip.offset_right = -10
	strip.offset_top = 3
	strip.offset_bottom = 7
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(strip)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_right = -14
	content.offset_top = 14
	content.offset_bottom = -12
	content.add_theme_constant_override("separation", 7)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)

	var tag := UiStyle.plain("%d · %s" % [index + 1, Upgrades.tag(offer).to_upper()] if Upgrades.tag(offer) != "" else str(index + 1), 13, tint.lightened(0.2) if grade > 0 else (CARD_FOCUS if offer["level"] == 1 else Color("b9a8c9")))
	content.add_child(tag)

	var icon_kind: String = {"heal": "passive", "branch": "weapon"}.get(offer["kind"], offer["kind"])
	var icon := IconView.new(icon_kind, offer["id"], 56.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)

	var name_label := _label(22, tint.lightened(0.45) if grade > 0 else Color.WHITE)
	name_label.text = Upgrades.title(offer)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 232
	content.add_child(name_label)

	var kind := UiStyle.plain("KIND_" + String(offer["kind"]).to_upper(), 13, Color("b9a8c9"))
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(kind)

	# What the cat already has of it ("You have it: Lv 3/8", "Evolves Scratch"),
	# as small chips.
	if _player != null:
		for note: Array in Upgrades.owned_notes(_player, offer):
			var chip := UiStyle.tag(note[0], Color("a6dc98") if note[1] else Color("e9c08a"), 12)
			chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			(chip.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			(chip.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(chip.get_child(0) as Label).custom_minimum_size.x = minf(ThemeDB.fallback_font.get_string_size(note[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 2.0, 214.0)
			content.add_child(chip)

	var desc := UiStyle.plain(Upgrades.description(offer, false), 15, Color("e7def2"), true)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var combo := _new_combo(offer)
	if combo != "":
		desc.text += "\n" + tr("COMBO_NEW") % [tr("COMBO_%s_NAME" % combo), tr("COMBO_%s_DESC" % combo)]
	desc.custom_minimum_size.x = 232
	content.add_child(desc)
	if _banish_left > 0 and Upgrades.banish_key(offer) != "":
		# Banish: a small x in the corner (Shift + number does the same).
		var banish := Button.new()
		banish.text = "×"
		banish.tooltip_text = tr("BANISH_BUTTON") % [index + 1, _banish_left]
		banish.focus_mode = Control.FOCUS_NONE
		banish.add_theme_font_size_override("font_size", 15)
		banish.add_theme_color_override("font_color", Color("8f80a3"))
		banish.add_theme_color_override("font_hover_color", Color("ff8a8a"))
		banish.add_theme_stylebox_override("normal", _flat(Color("1b1524"), Color("4b3d61")))
		banish.add_theme_stylebox_override("hover", _flat(Color(0.4, 0.1, 0.12, 0.9), Color("ff8a8a")))
		banish.add_theme_stylebox_override("pressed", _flat(Color(0.5, 0.1, 0.12, 0.9), Color("ff8a8a")))
		banish.pressed.connect(_banish.bind(index))
		banish.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		banish.offset_left = -34
		banish.offset_right = -8
		banish.offset_top = 10
		banish.offset_bottom = 34
		card.add_child(banish)
	return column


## The row under the cards: every weapon and skill the cat has, with its
## level; the ones the offered cards touch glow, and the first of them is
## named with what evolves it.
func _fill_owned(related: Array) -> void:
	for child in _owned.get_children():
		child.queue_free()
	_inventory.visible = _player != null
	if _player == null:
		return
	var head := UiStyle.plain(tr("LEVELUP_HAVE"), 15, UiStyle.GOLD)
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_owned.add_child(head)
	var note := ""
	for w: Weapon in _player.weapons.get_children():
		var hot := w.id in related
		_owned.add_child(_owned_slot("weapon", w.id, w.level, w.max_level(), hot, 42.0, tr("WEAPON_%s_DESC" % w.id)))
		if hot and note == "":
			note = "%s %d/%d" % [Upgrades.item_name("weapon", w.id), w.level, w.max_level()]
			var evolve: Dictionary = w.data.get("evolve", {})
			if not evolve.is_empty():
				note += "\n" + tr("PAUSE_EVOLVE_WITH") % Upgrades.item_name("passive", evolve["with"])
	for i in maxi(_player.max_weapons() - _player.weapon_count(), 0):
		_owned.add_child(_owned_slot("", "", 0, 0, false, 42.0, ""))
	if not _player.passives.is_empty():
		var gap := Control.new()
		gap.custom_minimum_size.x = 6
		_owned.add_child(gap)
	for id: String in _player.passives:
		var hot := id in related
		_owned.add_child(_owned_slot("passive", id, int(_player.passives[id]), (GameData.passives[id]["levels"] as Array).size(), hot, 32.0, tr("PASSIVE_%s_DESC" % id)))
		if hot and note == "":
			note = "%s %d/%d" % [Upgrades.item_name("passive", id), int(_player.passives[id]), (GameData.passives[id]["levels"] as Array).size()]
	var text := UiStyle.plain(note, 13, UiStyle.MUTED)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_owned.add_child(text)


## One slot of the "you have" row: icon, level in the corner, glow if hot.
func _owned_slot(kind: String, id: String, level: int, max_level: int, hot: bool, side: float, tip: String) -> PanelContainer:
	var slot := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.04, 0.08, 0.72 if kind != "" else 0.32)
	sb.border_color = Color("5aaeff") if hot else (Color("d8a93e") if level >= max_level and kind != "" else (Color("54466c") if kind != "" else Color(1, 1, 1, 0.13)))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(7)
	sb.set_content_margin_all(3)
	if hot:
		sb.shadow_color = Color(0.35, 0.68, 1.0, 0.45)
		sb.shadow_size = 6
	slot.add_theme_stylebox_override("panel", sb)
	slot.custom_minimum_size = Vector2(side, side)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.tooltip_text = tip
	if kind != "":
		slot.add_child(IconView.new(kind, id, side - 8.0))
		var lv := _label(11, UiStyle.GOLD if level >= max_level else Color.WHITE)
		lv.text = "★" if level >= max_level else str(level)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		slot.add_child(lv)
	return slot


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


func _flat(bg: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_top = 0
	sb.content_margin_bottom = 2
	return sb


func _style(border: Color, grade: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG.lerp(border, 0.05 * grade)
	sb.border_color = border
	sb.set_border_width_all(2 + grade)
	if grade > 0:
		sb.shadow_color = Color(border, 0.45)
		sb.shadow_size = 4 + grade * 3
	sb.set_corner_radius_all(10)
	return sb


func _label(size: int, font_color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 4
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
