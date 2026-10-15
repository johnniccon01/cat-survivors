class_name LevelUpPanel
extends ColorRect
## Level-up screen: shows the offers as cards. Pick with mouse, arrows +
## Enter/Space, or number keys 1-4.

signal chosen(offer: Dictionary)

## Ignore input for a moment so a held key doesn't pick a card by accident.
const INPUT_DELAY := 0.35

const CARD_BG := Color("3b2a4a")
const CARD_BORDER := Color("6b5480")
const CARD_FOCUS := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _title: Label
var _cards: HBoxContainer
var _offers: Array[Dictionary] = []
var _ready_for_input := false


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.7)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 24)
	add_child(box)

	_title = _label(44, CARD_FOCUS)
	box.add_child(_title)

	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 20)
	box.add_child(_cards)


func open(level: int, offers: Array[Dictionary]) -> void:
	_offers = offers
	_title.text = tr("LEVEL_UP_TITLE") % level
	for child in _cards.get_children():
		child.queue_free()
	for i in offers.size():
		_cards.add_child(_make_card(i, offers[i]))
	visible = true
	_ready_for_input = false
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_ready_for_input = true
	if visible and _cards.get_child_count() > 0:
		(_cards.get_child(0) as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _ready_for_input:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < _offers.size():
			_pick(index)
			get_viewport().set_input_as_handled()


func _pick(index: int) -> void:
	if not _ready_for_input:
		return
	_ready_for_input = false
	visible = false
	chosen.emit(_offers[index])


func _make_card(index: int, offer: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(250, 170)
	card.focus_mode = Control.FOCUS_ALL
	card.add_theme_stylebox_override("normal", _style(CARD_BORDER))
	card.add_theme_stylebox_override("hover", _style(CARD_FOCUS))
	card.add_theme_stylebox_override("focus", _style(CARD_FOCUS))
	card.add_theme_stylebox_override("pressed", _style(CARD_FOCUS))
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

	var tag := _label(16, CARD_FOCUS if offer["level"] == 1 else Color("b9a8c9"))
	tag.text = "%d · %s" % [index + 1, Upgrades.tag(offer)] if Upgrades.tag(offer) != "" else str(index + 1)
	content.add_child(tag)

	var name_label := _label(24, Color.WHITE)
	name_label.text = Upgrades.title(offer)
	content.add_child(name_label)

	var kind := _label(14, Color("b9a8c9"))
	kind.text = "KIND_" + String(offer["kind"]).to_upper()
	content.add_child(kind)

	var desc := _label(16, Color("eee6f3"))
	desc.text = Upgrades.description(offer)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 222
	content.add_child(desc)
	return card


func _style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG
	sb.border_color = border
	sb.set_border_width_all(3)
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
