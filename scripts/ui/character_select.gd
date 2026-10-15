extends Control
## Cat selection before a run. Locked cats show as silhouettes with a hint
## on how to get them. Any debug flag on the command line skips this screen.

const MAIN_SCENE := "res://scenes/main.tscn"
const BG := Color("1d1626")
const CARD := Color("3b2a4a")
const BORDER := Color("6b5480")
const GOLD := Color("f2c14e")
const OUTLINE := Color("2b1d14")

var _ids: Array[String] = []
var _index := 0
var _cards: Array[PanelContainer] = []
var _previews: Array[CatPreview] = []
var _name: Label
var _desc: Label
var _stage_label: Label
var _stage_ids: Array[String] = []
var _stage_index := 0
var _shop: ShopPanel
var _charms: CharmPanel
var _goals: GoalsPanel
var _worn: Label
var _gold: Label


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg not in ["--shop", "--charms", "--goals"]:
			get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
			return
	for id: String in GameData.cats:
		_ids.append(id)
	_index = maxi(_ids.find(Profile.selected_cat), 0)
	for id: String in GameData.stages:
		_stage_ids.append(id)
	_stage_index = maxi(_stage_ids.find(Profile.selected_stage), 0)
	_build()
	_refresh()
	Audio.play_music("music_apartment")
	if "--shop" in OS.get_cmdline_user_args():
		_shop.open()
	if "--charms" in OS.get_cmdline_user_args():
		_charms.open()
	if "--goals" in OS.get_cmdline_user_args():
		_goals.open()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 22)
	add_child(box)

	var title := _label(46, GOLD)
	title.text = "SELECT_TITLE"
	box.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	for i in _ids.size():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(160, 170)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(i))
		var preview := CatPreview.new()
		preview.cat_id = _ids[i]
		preview.locked = not Profile.is_unlocked(_ids[i])
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		row.add_child(card)
		_cards.append(card)
		_previews.append(preview)

	_name = _label(32, Color.WHITE)
	box.add_child(_name)
	_desc = _label(20, Color("d9cce6"))
	_desc.custom_minimum_size = Vector2(700, 60)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_desc)

	_stage_label = _label(24, GOLD)
	box.add_child(_stage_label)

	_gold = _label(20, GOLD)
	box.add_child(_gold)
	_worn = _label(18, Color("c77dff"))
	box.add_child(_worn)

	var hint := _label(18, Color("8f7ea3"))
	hint.text = "SELECT_HINT"
	box.add_child(hint)

	_shop = ShopPanel.new()
	add_child(_shop)
	_shop.closed.connect(_refresh)
	_charms = CharmPanel.new()
	add_child(_charms)
	_charms.closed.connect(_refresh)
	_goals = GoalsPanel.new()
	add_child(_goals)
	_goals.closed.connect(_refresh)


func _refresh() -> void:
	var id := _ids[_index]
	var unlocked := Profile.is_unlocked(id)
	for i in _cards.size():
		var sb := StyleBoxFlat.new()
		sb.bg_color = CARD
		sb.border_color = GOLD if i == _index else BORDER
		sb.set_border_width_all(4 if i == _index else 2)
		sb.set_corner_radius_all(10)
		_cards[i].add_theme_stylebox_override("panel", sb)
		_previews[i].walking = i == _index and unlocked
	if unlocked:
		_name.text = tr("CAT_%s_NAME" % id)
		_desc.text = tr("CAT_%s_DESC" % id)
	else:
		_name.text = tr("SELECT_LOCKED")
		_desc.text = tr("CAT_%s_HINT" % id)
	var worn: Array = Profile.equipped_charms.map(func(c: String) -> String: return tr("CHARM_%s_NAME" % c))
	_worn.text = tr("SELECT_CHARMS") % ("—" if worn.is_empty() else ", ".join(worn))
	_gold.text = tr("SELECT_GOLD") % Profile.gold
	if Profile.streak > 0 or Profile.best_streak > 0:
		_gold.text += "   ·   " + tr("SELECT_STREAK") % [Profile.streak, Profile.best_streak, roundi((Profile.streak_multiplier() - 1.0) * 100.0)]
	var stage_id := _stage_ids[_stage_index]
	if Profile.is_stage_unlocked(stage_id):
		var cleared := " ✓" if stage_id in Profile.cleared_stages else ""
		_stage_label.text = "%s  ‹ %s%s ›" % [tr("SELECT_STAGE"), tr("STAGE_%s_NAME" % stage_id), cleared]
	else:
		_stage_label.text = "%s  ‹ ??? – %s ›" % [tr("SELECT_STAGE"), tr("STAGE_%s_HINT" % stage_id)]


func _unhandled_input(event: InputEvent) -> void:
	if _shop.visible or _charms.visible or _goals.visible:
		return
	if event.is_action_pressed("goals"):
		Audio.play("click", -6.0, 0.0)
		_goals.open()
		return
	if event.is_action_pressed("shop"):
		Audio.play("click", -6.0, 0.0)
		_shop.open()
	elif event.is_action_pressed("charms"):
		Audio.play("click", -6.0, 0.0)
		_charms.open()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_index = (_index - 1 + _ids.size()) % _ids.size()
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_index = (_index + 1) % _ids.size()
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		_stage_index = (_stage_index - 1 + _stage_ids.size()) % _stage_ids.size()
		_refresh()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_stage_index = (_stage_index + 1) % _stage_ids.size()
		_refresh()
	elif event.is_action_pressed("language"):
		Settings.cycle_language()
		_refresh()
	elif event.is_action_pressed("mute"):
		Settings.toggle_mute()
	elif event.is_action_pressed("restart") or event.is_action_pressed("ui_accept"):
		_start()


func _on_card_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if i == _index:
			_start()
		else:
			_index = i
			_refresh()


func _start() -> void:
	var id := _ids[_index]
	var stage_id := _stage_ids[_stage_index]
	if not Profile.is_unlocked(id) or not Profile.is_stage_unlocked(stage_id):
		return
	Profile.select_stage(stage_id)
	Profile.select(id)
	Audio.play("select", -4.0, 0.0)
	get_tree().change_scene_to_file(MAIN_SCENE)


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
