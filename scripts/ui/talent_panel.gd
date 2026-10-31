class_name TalentPanel
extends ColorRect
## The chosen cat's career: its nine lives as paws, rank and generation,
## the talents it picked (charms and artifacts you own), the pick waiting
## after a new rank, and the legacy of retired cats. C / Esc closes, arrows
## and Enter pick a talent (or click one).

signal closed

const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _header: Label
var _lives: Control
var _list: Label
var _pick_title: Label
var _pick_box: VBoxContainer
var _legacy: Label
var _offers: Array = []
var _buttons: Array[Button] = []
var _index := 0


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	UiStyle.board(self, box)
	var title := _label(36, GOLD)
	title.text = "TALENTS_TITLE"
	box.add_child(title)
	_header = _label(19, Color("f4ecd4"))
	box.add_child(_header)
	_lives = Control.new()
	_lives.custom_minimum_size = Vector2(9 * 34, 34)
	_lives.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lives.draw.connect(_draw_lives)
	box.add_child(_lives)
	_list = _label(16, Color("d9cce6"))
	_list.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_list.custom_minimum_size = Vector2(760, 0)
	_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_list)
	_pick_title = _label(20, GOLD)
	box.add_child(_pick_title)
	_pick_box = VBoxContainer.new()
	_pick_box.add_theme_constant_override("separation", 6)
	box.add_child(_pick_box)
	for i in Profile.TALENT_OFFERS:
		var b := UiStyle.click_button("", 760, 16)
		b.pressed.connect(_pick.bind(i))
		b.mouse_entered.connect(func() -> void:
			_index = i
			_style_buttons())
		_pick_box.add_child(b)
		_buttons.append(b)
	_legacy = _label(15, Color("b8b0c8"))
	_legacy.custom_minimum_size = Vector2(760, 0)
	_legacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_legacy)
	var hint := _label(14, Color("8f7ea3"))
	hint.text = "TALENTS_HINT"
	hint.custom_minimum_size = Vector2(760, 0)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var back := UiStyle.click_button("SET_BACK", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	box.add_child(back)


func open() -> void:
	visible = true
	_index = 0
	_refresh()


func _refresh() -> void:
	var cat := Profile.selected_cat
	var c := Profile.career(cat)
	_header.text = tr("TALENTS_HEADER") % [tr("CAT_%s_NAME" % cat), int(c["gen"]), int(c["rank"]), Profile.MAX_RANK, int(c["xp"]), Profile.RANK_XP]
	var lines: Array[String] = []
	var talents: Array = c["talents"]
	for i in Profile.MAX_RANK:
		if i < talents.size():
			var t: String = talents[i]
			lines.append("%d. %s – %s" % [i + 1, Profile.talent_name(t), Profile.talent_desc(t)])
		elif i < int(c["rank"]):
			lines.append("%d. %s" % [i + 1, tr("TALENTS_EMPTY")])
		else:
			lines.append("%d. %s" % [i + 1, tr("TALENTS_LOCKED") % (i + 1)])
	_list.text = "\n".join(lines)
	_offers = Profile.talent_offers(cat)
	_pick_title.visible = not _offers.is_empty()
	_pick_title.text = tr("TALENTS_PICK") % int(c["picks"])
	for i in _buttons.size():
		var b := _buttons[i]
		b.visible = i < _offers.size()
		if b.visible:
			var t: String = _offers[i]
			b.text = "%s – %s" % [Profile.talent_name(t), Profile.talent_desc(t)]
	if int(c["picks"]) > 0 and _offers.is_empty():
		_pick_title.visible = true
		_pick_title.text = tr("TALENTS_NONE_LEFT")
	_legacy.text = tr("TALENTS_LEGACY") % Profile.retired.size() if not Profile.retired.is_empty() else tr("TALENTS_NO_LEGACY")
	_style_buttons()
	_lives.queue_redraw()


func _style_buttons() -> void:
	for i in _buttons.size():
		_buttons[i].modulate = Color(1.15, 1.1, 0.9) if i == _index else Color.WHITE


func _pick(i: int) -> void:
	if i >= _offers.size():
		return
	if Profile.pick_talent(Profile.selected_cat, _offers[i]):
		Audio.play("levelup", -6.0, 0.0)
	_index = 0
	_refresh()


## Nine paws: filled for lives left, faint for lives lost.
func _draw_lives() -> void:
	var lives := int(Profile.career(Profile.selected_cat)["lives"])
	for i in Profile.LIVES:
		var c := Vector2(17 + i * 34, 18)
		var on := i < lives
		var fill := Color("ff8fa8") if on else Color(0.35, 0.3, 0.4, 0.6)
		_lives.draw_circle(c + Vector2(0, 3), 7.5, OUTLINE)
		_lives.draw_circle(c + Vector2(0, 3), 6.0, fill)
		for toe: Vector2 in [Vector2(-7, -5), Vector2(-2.5, -9), Vector2(2.5, -9), Vector2(7, -5)]:
			_lives.draw_circle(c + toe, 3.2, OUTLINE)
			_lives.draw_circle(c + toe, 2.2, fill)


## _input, not _unhandled_input: the panel must see keys before the GUI
## focus of the screen behind it does.
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	var n := maxi(_offers.size(), 1)
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_index = (_index - 1 + n) % n
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_index = (_index + 1) % n
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		_pick(_index)
		return
	elif event.is_action_pressed("charms") or event.is_action_pressed("artifacts") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_close()
		return
	else:
		return
	Audio.play("click", -10.0, 0.0)
	_style_buttons()


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
