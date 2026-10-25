class_name LevelUpPanel
extends ColorRect
## Level-up screen: shows the offers as cards. Pick with mouse, arrows +
## Enter/Space, or number keys 1-4. Shift + number (or the small button
## under a card) banishes that card for the rest of the run.

signal chosen(offer: Dictionary)
signal reroll_requested
signal banish_requested(index: int)

## Ignore input for a moment so a held key doesn't pick a card by accident.
const INPUT_DELAY := 0.35

const CARD_BG := Color("3b2a4a")
const CARD_BORDER := Color("6b5480")
const CARD_FOCUS := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _title: Label
var _reroll: Label
var _cards: HBoxContainer
var _inventory: PanelContainer
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

	_reroll = _label(18, Color("b9a8c9"))
	box.add_child(_reroll)

	# What the cat already has, so the pick is easier (like the pause screen).
	_inventory = UiStyle.inventory_panel(1040, 150)
	box.add_child(_inventory)


## `title` replaces the "Level N!" heading (e.g. a boss chest's pick).
func open(level: int, offers: Array[Dictionary], rerolls: int = 0, title: String = "", banishes: int = 0) -> void:
	_offers = offers
	_banish_left = banishes
	_reroll.text = tr("LEVELUP_REROLL") % rerolls if rerolls > 0 else ""
	_title.text = title if title != "" else tr("LEVEL_UP_TITLE") % level
	for child in _cards.get_children():
		child.queue_free()
	var hud := get_parent() as Hud
	_player = hud.get_parent().get("player") if hud != null else null
	for i in offers.size():
		_cards.add_child(_make_card(i, offers[i]))
	var owned := hud.weapons_text(3, Upgrades.related_ids(offers)) if hud != null else ""
	(_inventory.get_meta("text") as RichTextLabel).text = owned
	_inventory.visible = owned != ""
	visible = true
	_ready_for_input = false
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_ready_for_input = true
	if visible and _cards.get_child_count() > 0:
		(_cards.get_child(0).get_child(0) as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _ready_for_input:
		return
	if event.is_action_pressed("reroll") and _reroll.text != "":
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
	card.custom_minimum_size = Vector2(260, 300)
	card.focus_mode = Control.FOCUS_ALL
	var grade := int(offer.get("grade", 0))
	var border: Color = Upgrades.GRADE_COLORS[grade] if grade > 0 else CARD_BORDER
	card.add_theme_stylebox_override("normal", _style(border, grade))
	card.add_theme_stylebox_override("hover", _style(CARD_FOCUS, grade))
	card.add_theme_stylebox_override("focus", _style(CARD_FOCUS, grade))
	card.add_theme_stylebox_override("pressed", _style(CARD_FOCUS, grade))
	card.pressed.connect(_pick.bind(index))
	card.mouse_entered.connect(card.grab_focus)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_right = -14
	content.offset_top = 12
	content.offset_bottom = -12
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)

	var tag := _label(16, Upgrades.GRADE_COLORS[grade].lightened(0.25) if grade > 0 else (CARD_FOCUS if offer["level"] == 1 else Color("b9a8c9")))
	tag.text = "%d · %s" % [index + 1, Upgrades.tag(offer)] if Upgrades.tag(offer) != "" else str(index + 1)
	content.add_child(tag)

	var icon_kind: String = {"heal": "passive", "branch": "weapon"}.get(offer["kind"], offer["kind"])
	var icon := IconView.new(icon_kind, offer["id"], 44.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(icon)

	var name_label := _label(24, Color.WHITE)
	name_label.text = Upgrades.title(offer)
	content.add_child(name_label)

	var kind := _label(14, Color("b9a8c9"))
	kind.text = "KIND_" + String(offer["kind"]).to_upper()
	content.add_child(kind)

	# What the cat already has of it: "You have it: Lv 3/8", "Evolves Scratch – you have it".
	if _player != null:
		for note: Array in Upgrades.owned_notes(_player, offer):
			var owned := _label(14, Color("8fdc8f") if note[1] else Color("e8a07a"))
			owned.text = note[0]
			owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			owned.custom_minimum_size.x = 232
			content.add_child(owned)

	var desc := _label(16, Color("eee6f3"))
	desc.text = Upgrades.description(offer, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 232
	content.add_child(desc)
	if _banish_left > 0 and Upgrades.banish_key(offer) != "":
		var banish := Button.new()
		banish.text = tr("BANISH_BUTTON") % [index + 1, _banish_left]
		banish.focus_mode = Control.FOCUS_NONE
		banish.add_theme_font_size_override("font_size", 14)
		banish.add_theme_color_override("font_color", Color("b9a8c9"))
		banish.add_theme_color_override("font_hover_color", Color("ff8a8a"))
		banish.add_theme_stylebox_override("normal", _flat(Color(0, 0, 0, 0.35)))
		banish.add_theme_stylebox_override("hover", _flat(Color(0.5, 0.1, 0.1, 0.5)))
		banish.add_theme_stylebox_override("pressed", _flat(Color(0.5, 0.1, 0.1, 0.7)))
		banish.pressed.connect(_banish.bind(index))
		column.add_child(banish)
	return column


func _flat(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb


func _style(border: Color, grade: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG.lerp(border, 0.05 * grade)
	sb.border_color = border
	sb.set_border_width_all(3 + grade)
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
