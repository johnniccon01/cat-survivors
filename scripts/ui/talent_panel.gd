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
## The cat shown; ← → (or the arrows by its name) go through the unlocked cats.
var cat := ""
var _cats: Array = []
var _others: Label
var _lives: Control
var _list: Label
var _pick_title: Label
var _pick_box: VBoxContainer
var _legacy: Label
var _offers: Array = []
var _buttons: Array[Button] = []
var _index := 0


func _ready() -> void:
	color = Color(0.09, 0.055, 0.03, 1.0)
	theme = UiStyle.panel_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 4)
	UiStyle.board(self, box)
	var title := UiStyle.paper_title(_label(32, GOLD))
	title.text = "TALENTS_TITLE"
	box.add_child(title)
	var head_row := HBoxContainer.new()
	head_row.alignment = BoxContainer.ALIGNMENT_CENTER
	head_row.add_theme_constant_override("separation", 12)
	box.add_child(head_row)
	var prev := UiStyle.click_button("‹", 44, 22)
	prev.pressed.connect(_switch.bind(-1))
	head_row.add_child(prev)
	_header = _label(19, Color("f4ecd4"))
	_header.custom_minimum_size.x = 640
	_header.clip_text = true
	_header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head_row.add_child(_header)
	var next := UiStyle.click_button("›", 44, 22)
	next.pressed.connect(_switch.bind(1))
	head_row.add_child(next)
	_others = _label(15, GOLD)
	_others.custom_minimum_size = Vector2(760, 22)
	_others.clip_text = true
	_others.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_others)
	_lives = Control.new()
	_lives.custom_minimum_size = Vector2(9 * 34, 34)
	_lives.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lives.draw.connect(_draw_lives)
	box.add_child(_lives)
	_list = _label(14, Color("e6d3ab"))
	_list.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Everything below keeps its size whatever the cat has, so the panel
	# never moves: one line per rank ("…" if too long), the pick lines are
	# always there and only fade out when there is nothing to pick.
	_list.custom_minimum_size = Vector2(760, Profile.MAX_RANK * 22)
	_list.clip_text = true
	_list.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_list.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	box.add_child(_list)
	_pick_title = _label(20, GOLD)
	_pick_title.custom_minimum_size.y = 30
	box.add_child(_pick_title)
	_pick_box = VBoxContainer.new()
	_pick_box.add_theme_constant_override("separation", 6)
	box.add_child(_pick_box)
	for i in Profile.TALENT_OFFERS:
		var b := UiStyle.click_button("", 760, 16)
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size.x = 760
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(_pick.bind(i))
		b.mouse_entered.connect(func() -> void:
			_index = i
			_style_buttons())
		_pick_box.add_child(b)
		_buttons.append(b)
	_legacy = _label(15, Color("c4a27a"))
	_legacy.custom_minimum_size = Vector2(760, 44)
	_legacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_legacy)
	var hint := _label(14, Color("c4a27a"))
	hint.text = "TALENTS_HINT"
	hint.custom_minimum_size = Vector2(760, 0)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var back := UiStyle.click_button("SET_BACK", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_close)
	box.add_child(back)


## Opens on cat_id; cats are the ones ← → may go through.
func open(cat_id: String = Profile.selected_cat, cats: Array = []) -> void:
	cat = cat_id
	_cats = cats if not cats.is_empty() else [cat_id]
	visible = true
	_index = 0
	_refresh()


func _refresh() -> void:
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
	_pick_title.text = tr("TALENTS_PICK") % int(c["picks"]) if not _offers.is_empty() else ""
	for i in _buttons.size():
		var b := _buttons[i]
		var on := i < _offers.size()
		b.modulate.a = 1.0 if on else 0.0
		b.disabled = not on
		b.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
		b.text = "%s – %s" % [Profile.talent_name(_offers[i]), Profile.talent_desc(_offers[i])] if on else ""
		b.tooltip_text = b.text
	if int(c["picks"]) > 0 and _offers.is_empty():
		_pick_title.text = tr("TALENTS_NONE_LEFT")
	var waiting: Array = _cats.filter(func(id: String) -> bool: return id != cat and int(Profile.career(id)["picks"]) > 0)
	var names: Array = waiting.map(func(id: String) -> String: return tr("CAT_%s_NAME" % id))
	_others.text = (tr("TALENTS_SWITCH") if _cats.size() > 1 else "") + ("   " + tr("TALENTS_OTHERS") % ", ".join(names) if not names.is_empty() else "")
	_legacy.text = tr("TALENTS_LEGACY") % Profile.retired.size() if not Profile.retired.is_empty() else tr("TALENTS_NO_LEGACY")
	_style_buttons()
	_lives.queue_redraw()


func _style_buttons() -> void:
	for i in _buttons.size():
		_buttons[i].modulate = Color(1.15, 1.1, 0.9) if i == _index else Color.WHITE


func _pick(i: int) -> void:
	if i >= _offers.size():
		return
	if Profile.pick_talent(cat, _offers[i]):
		Audio.play("levelup", -6.0, 0.0)
	_index = 0
	_refresh()


## Nine paws: filled for lives left, faint for lives lost.
func _draw_lives() -> void:
	var lives := int(Profile.career(cat)["lives"])
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
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_switch(-1)
		return
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_switch(1)
		return
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


## The next or previous cat in the list.
func _switch(step: int) -> void:
	if _cats.size() < 2:
		return
	cat = _cats[(_cats.find(cat) + step + _cats.size()) % _cats.size()]
	_index = 0
	Audio.play("click", -10.0, 0.0)
	_refresh()


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
