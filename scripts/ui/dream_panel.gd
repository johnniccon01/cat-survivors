class_name DreamPanel
extends ColorRect
## Cat Dreams (the endgame, after the director): three dreams to pick from,
## each a night on any map of any district one depth deeper than the last
## dream won; some come with dream shards (challenges) already in. Your own
## shards can be added to the chosen dream: harder, richer. Dream points
## (one per dream won) buy small bonuses that never run out.
## Click a dream to start it; Esc / the back button closes.

signal closed
signal dream_chosen(offer: Dictionary, shards: Array)

const GOLD := Color("f2c14e")
const DREAM := Color("ffc27a")
const OUTLINE := Color("2b1d14")

var _box: VBoxContainer
var _header: Label
var _offers: VBoxContainer
var _shards: HFlowContainer
var _growth: HFlowContainer
var _points: Label
var _picked: Array[String] = []


func _ready() -> void:
	color = Color(0.09, 0.055, 0.03, 0.98)
	theme = UiStyle.panel_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_box.add_theme_constant_override("separation", 8)
	UiStyle.board(self, _box)
	var title := _label(36, DREAM)
	title.text = "DREAMS_TITLE"
	_box.add_child(title)
	_header = _label(18, GOLD)
	_box.add_child(_header)
	_offers = VBoxContainer.new()
	_offers.add_theme_constant_override("separation", 6)
	_box.add_child(_offers)
	var shard_title := _label(16, Color("e6d3ab"))
	shard_title.text = "DREAMS_SHARDS"
	_box.add_child(shard_title)
	_shards = HFlowContainer.new()
	_shards.custom_minimum_size = Vector2(760, 0)
	_shards.alignment = FlowContainer.ALIGNMENT_CENTER
	_box.add_child(_shards)
	_points = _label(16, GOLD)
	_box.add_child(_points)
	_growth = HFlowContainer.new()
	_growth.custom_minimum_size = Vector2(760, 0)
	_growth.alignment = FlowContainer.ALIGNMENT_CENTER
	_box.add_child(_growth)
	var back := UiStyle.click_button("SET_BACK", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	_box.add_child(back)


func open() -> void:
	visible = true
	_picked.clear()
	_refresh()


func _refresh() -> void:
	_header.text = tr("DREAMS_DEPTH") % [Profile.dream_depth, Profile.dream_depth + 1]
	for c in _offers.get_children():
		c.queue_free()
	for offer: Dictionary in Profile.dream_offers():
		var b := UiStyle.click_button(_offer_text(offer), 760, 16)
		b.custom_minimum_size.y = 46
		b.add_theme_color_override("font_color", Color("a01c15") if offer.get("nightmare", false) else UiStyle.INK)
		b.pressed.connect(func() -> void:
			Audio.play("select", -4.0, 0.0)
			dream_chosen.emit(offer, _picked.duplicate()))
		_offers.add_child(b)
	for c in _shards.get_children():
		c.queue_free()
	if Profile.dream_shards.is_empty():
		var none := _label(14, Color("c4a27a"))
		none.text = "DREAMS_NO_SHARDS"
		_shards.add_child(none)
	var counted := {}
	for s: String in Profile.dream_shards:
		counted[s] = int(counted.get(s, 0)) + 1
	for s: String in counted:
		var on := s in _picked
		var b := UiStyle.click_button("%s %s ×%d" % ["■" if on else "□", tr("CHALLENGE_%s_NAME" % s), counted[s]], 0, 14)
		b.add_theme_color_override("font_color", Color("a01c15") if on else UiStyle.INK)
		b.tooltip_text = tr("CHALLENGE_%s_DESC" % s)
		b.pressed.connect(func() -> void:
			if s in _picked:
				_picked.erase(s)
			else:
				_picked.append(s)
			Audio.play("click", -8.0, 0.0)
			_refresh())
		_shards.add_child(b)
	_points.text = tr("DREAMS_POINTS") % Profile.dream_points
	for c in _growth.get_children():
		c.queue_free()
	for stat: String in Profile.DREAM_GROWTH:
		var b := UiStyle.click_button(tr("DREAMS_GROW") % [tr("DREAM_STAT_" + stat.to_upper()), int(Profile.dream_growth.get(stat, 0))], 0, 14)
		b.disabled = Profile.dream_points <= 0
		b.pressed.connect(func() -> void:
			if Profile.spend_dream_point(stat):
				Audio.play("select", -6.0, 0.0)
				_refresh())
		_growth.add_child(b)


## "Depth 4 – The Junkyard (Dog District) · Glass Cat, No Magnet".
func _offer_text(offer: Dictionary) -> String:
	var stage: String = offer["stage"]
	var text := tr("DREAMS_OFFER") % [int(offer["depth"]), tr("STAGE_%s_NAME" % stage), tr("DISTRICT_NAME_" + DistrictMap.stage_district(stage).to_upper())]
	if offer.get("nightmare", false):
		text = tr("DREAMS_NIGHTMARE") % tr("ENEMY_%s_NAME" % offer["boss"]) + "\n" + text
	var shards: Array = offer.get("shards", [])
	if not shards.is_empty():
		text += " · " + ", ".join(shards.map(func(s: String) -> String: return tr("CHALLENGE_%s_NAME" % s)))
	return text


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	if event.is_pressed() and not event.is_echo() and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	visible = false
	closed.emit()


func _label(size: int, font_color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 4
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
