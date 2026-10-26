extends Control
## Cat and map selection before a run: a grid of cats with the chosen one
## shown big (starting weapon, wins with it), and a row of map cards. Locked
## cats and maps show as silhouettes with a hint on how to get them. Any
## debug flag on the command line skips this screen.

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
var _items: ItemPanel
var _artifacts: ArtifactPanel
var _artifact_label: Label
var _journal: JournalPanel
var _challenges: ChallengePanel
var _challenge_label: Label
var _worn: Label
var _gold: Label
var _big: CatPreview
var _weapon_icon: IconView
var _weapon_label: Label
var _cat_stats: Label
var _map_cards: Array[MapCard] = []
var _chips: HFlowContainer
var _play: Button
var _hover := -1
var _dark_label: Label
var _dark_minus: Button
var _dark_plus: Button
var _t := 0.0
## Cat bonus stat -> [translation key, multiplier for the shown number, colour].
const BONUS_TEXT := {
	"might": ["BONUS_MIGHT", 100.0, Color("ff7a6a")],
	"cooldown": ["BONUS_COOLDOWN", -100.0, Color("ffd36a")],
	"area": ["BONUS_AREA", 100.0, Color("8ee07a")],
	"speed": ["BONUS_SPEED", 100.0, Color("6cc8ff")],
	"magnet": ["BONUS_MAGNET", 1.0, Color("c7a0ff")],
	"max_hp": ["BONUS_MAX_HP", 1.0, Color("ff8aa8")],
	"luck": ["BONUS_LUCK", 100.0, Color("f2c14e")],
	"regen": ["BONUS_REGEN", 1.0, Color("8ee07a")],
	"proj_speed": ["BONUS_PROJ_SPEED", 100.0, Color("9ae0ff")],
	"growth": ["BONUS_GROWTH", 100.0, Color("b9e86a")],
	"weapon_slots": ["BONUS_WEAPON_SLOTS", 1.0, Color("ffb35a")],
}


func _ready() -> void:
	for arg: String in GameData.args():
		if arg.begins_with("--") and arg not in ["--shop", "--charms", "--artifacts", "--goals", "--journal", "--challenges", "--ui-test"]:
			get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
			return
	for id: String in GameData.cats:
		# Secret cats only show up once they are unlocked.
		if GameData.cats[id].get("npc", false):
			continue
		if not GameData.cats[id].get("hidden", false) or Profile.is_unlocked(id):
			_ids.append(id)
	_index = maxi(_ids.find(Profile.selected_cat), 0)
	for id: String in GameData.stages:
		_stage_ids.append(id)
	_stage_index = maxi(_stage_ids.find(Profile.selected_stage), 0)
	_build()
	_refresh()
	Audio.play_music("music_menu")
	if "--shop" in GameData.args():
		_shop.open()
	if "--charms" in GameData.args():
		_charms.open()
	if "--artifacts" in GameData.args():
		_artifacts.open()
	if "--goals" in GameData.args():
		_journal.open("goals")
	if "--journal" in GameData.args():
		_journal.open("bestiary")


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# The night city from the title screen, dimmed, with twinkling stars.
	var art := TextureRect.new()
	art.texture = load("res://assets/title.png")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.modulate = Color(0.55, 0.5, 0.65)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	add_child(MenuSky.new())
	var shade := ColorRect.new()
	shade.color = Color(BG, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 32
	root.offset_right = -32
	root.offset_top = 14
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 12)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	var title := _label(40, GOLD)
	title.text = "SELECT_TITLE"
	root.add_child(title)

	# Top: the cats on the left, the chosen one big on the right.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	root.add_child(top)
	var grid := GridContainer.new()
	var wide := _ids.size() > 12
	grid.columns = 7 if wide else 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	top.add_child(grid)
	for i in _ids.size():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(88, 104) if wide else Vector2(98, 112)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(i))
		card.mouse_entered.connect(_on_card_hover.bind(i, true))
		card.mouse_exited.connect(_on_card_hover.bind(i, false))
		var preview := CatPreview.new()
		preview.cat_id = _ids[i]
		preview.locked = not Profile.is_unlocked(_ids[i])
		preview.zoom = 2.0 if wide else 2.2
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		grid.add_child(card)
		_cards.append(card)
		_previews.append(preview)

	var detail := PanelContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var detail_style := UiStyle.box(Color(CARD, 0.92), BORDER)
	detail_style.set_corner_radius_all(12)
	detail_style.shadow_color = Color(0, 0, 0, 0.4)
	detail_style.shadow_size = 8
	detail.add_theme_stylebox_override("panel", detail_style)
	top.add_child(detail)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 10)
	detail.add_child(drow)
	_big = CatPreview.new()
	_big.custom_minimum_size = Vector2(170 if wide else 190, 210)
	_big.zoom = 5.0
	_big.walking = true
	_big.gear = true
	_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drow.add_child(_big)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_child(info)
	_name = _label(30, Color.WHITE)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_name)
	_desc = _label(17, Color("d9cce6"))
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(240 if wide else 300, 0)
	info.add_child(_desc)
	# What makes this cat special, as coloured chips.
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 6)
	_chips.add_theme_constant_override("v_separation", 4)
	info.add_child(_chips)
	var weapon_row := HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 8)
	info.add_child(weapon_row)
	_weapon_icon = IconView.new("weapon", "SCRATCH", 40.0)
	weapon_row.add_child(_weapon_icon)
	_weapon_label = _label(17, GOLD)
	_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_row.add_child(_weapon_label)
	_cat_stats = _label(15, Color("8f7ea3"))
	_cat_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_cat_stats)

	# Middle: the maps.
	_stage_label = _label(20, GOLD)
	root.add_child(_stage_label)
	# Darkness of the chosen map: - and + (or the keys).
	var dark_row := HBoxContainer.new()
	dark_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dark_row.add_theme_constant_override("separation", 8)
	root.add_child(dark_row)
	_dark_minus = UiStyle.click_button("-", 36, 20)
	_dark_minus.pressed.connect(_change_darkness.bind(-1))
	dark_row.add_child(_dark_minus)
	_dark_label = _label(17, Color("c79bff"))
	dark_row.add_child(_dark_label)
	_dark_plus = UiStyle.click_button("+", 36, 20)
	_dark_plus.pressed.connect(_change_darkness.bind(1))
	dark_row.add_child(_dark_plus)
	var maps := HBoxContainer.new()
	maps.alignment = BoxContainer.ALIGNMENT_CENTER
	maps.add_theme_constant_override("separation", 8)
	root.add_child(maps)
	for i in _stage_ids.size():
		var card := MapCard.new(_stage_ids[i])
		if _stage_ids.size() > 6:
			card.custom_minimum_size.x = 166
		card.gui_input.connect(_on_map_input.bind(i))
		maps.add_child(card)
		_map_cards.append(card)

	# Bottom: what you take along, and the keys.
	var loadout := PanelContainer.new()
	var loadout_style := UiStyle.box(Color(0.08, 0.05, 0.12, 0.6), Color(BORDER, 0.6))
	loadout_style.set_corner_radius_all(10)
	loadout.add_theme_stylebox_override("panel", loadout_style)
	loadout.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(loadout)
	var loadout_rows := VBoxContainer.new()
	loadout_rows.add_theme_constant_override("separation", 2)
	loadout.add_child(loadout_rows)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 28)
	loadout_rows.add_child(bottom)
	_gold = _label(17, GOLD)
	bottom.add_child(_gold)
	_worn = _label(17, Color("c77dff"))
	bottom.add_child(_worn)
	_artifact_label = _label(17, Color("8fd3ff"))
	bottom.add_child(_artifact_label)
	_challenge_label = _label(16, Color("ff7a6a"))
	loadout_rows.add_child(_challenge_label)

	# Everything you can do here, as buttons for the mouse (the keys still work).
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	root.add_child(buttons)
	var play := UiStyle.click_button("%s (Enter)" % tr("MENU_PLAY"), 200, 21)
	play.custom_minimum_size.y = 44
	play.add_theme_color_override("font_color", GOLD)
	var play_style := UiStyle.box(Color("5b3a20"), GOLD)
	play_style.set_border_width_all(3)
	play.add_theme_stylebox_override("normal", play_style)
	var play_hover := UiStyle.box(Color("7a4e28"), Color("ffe08a"))
	play_hover.set_border_width_all(3)
	play.add_theme_stylebox_override("hover", play_hover)
	play.add_theme_stylebox_override("pressed", play_hover)
	play.pressed.connect(_start)
	buttons.add_child(play)
	_play = play
	for entry: Array in [["MENU_UPGRADES", "U", func() -> void: _shop.open()],
			["MENU_CHARMS", "C", func() -> void: _charms.open()],
			["MENU_ITEMS", "I", func() -> void: _items.open()],
			["ARTIFACTS_TITLE", "V", func() -> void: _artifacts.open()],
			["CHALLENGES_TITLE", "X", func() -> void: _challenges.open()],
			["SELECT_BTN_DAILY", "T", _start_daily],
			["MENU_JOURNAL", "J", func() -> void: _journal.open("quests")],
			["SET_BACK", "Esc", func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")]]:
		var b := UiStyle.click_button("%s (%s)" % [tr(entry[0]), entry[1]], 0)
		b.pressed.connect(entry[2])
		buttons.add_child(b)
	# Longer words in some languages: shrink the row to fit the screen.
	UiStyle.fit_row(buttons, 1240.0)
	var hint := _label(15, Color("8f7ea3"))
	hint.text = "SELECT_HINT"
	root.add_child(hint)

	_shop = ShopPanel.new()
	add_child(_shop)
	_shop.closed.connect(_refresh)
	_charms = CharmPanel.new()
	add_child(_charms)
	_charms.closed.connect(_refresh)
	_items = ItemPanel.new()
	add_child(_items)
	_items.closed.connect(_refresh)
	_artifacts = ArtifactPanel.new()
	add_child(_artifacts)
	_artifacts.closed.connect(_refresh)
	_journal = JournalPanel.new()
	add_child(_journal)
	_journal.closed.connect(_refresh)
	_challenges = ChallengePanel.new()
	add_child(_challenges)
	_challenges.closed.connect(_refresh)


func _process(delta: float) -> void:
	_t += delta
	if _play != null:
		_play.modulate = Color(1, 1, 1).lerp(Color(1.25, 1.15, 0.9), 0.5 + 0.5 * sin(_t * 3.0))


func _on_card_hover(i: int, inside: bool) -> void:
	if inside:
		_hover = i
	elif _hover == i:
		_hover = -1
	_style_cards()


## The cat cards: the chosen one glows gold, the one under the mouse lights up.
func _style_cards() -> void:
	for i in _cards.size():
		var chosen := i == _index
		var fill := Color("5b4470") if chosen else (Color("4a3860") if i == _hover else Color(CARD, 0.9))
		var edge := GOLD if chosen else (Color("b9a8c9") if i == _hover else BORDER)
		var sb := UiStyle.box(fill, edge)
		sb.set_corner_radius_all(10)
		if chosen:
			sb.set_border_width_all(3)
			sb.shadow_color = Color(GOLD, 0.35)
			sb.shadow_size = 8
		_cards[i].add_theme_stylebox_override("panel", sb)


func _fill_chips(id: String, unlocked: bool) -> void:
	for c in _chips.get_children():
		c.queue_free()
	if not unlocked:
		return
	var bonus: Dictionary = GameData.cats[id].get("bonus", {})
	if bonus.is_empty():
		_chips.add_child(_chip(tr("BONUS_NONE"), Color("b9a8c9")))
	for key: String in bonus:
		if not BONUS_TEXT.has(key):
			continue
		var spec: Array = BONUS_TEXT[key]
		var value := float(bonus[key]) * float(spec[1])
		var shown := str(roundi(value))
		if absf(value - roundf(value)) > 0.01:
			shown = ("%.1f" % value).replace(".", tr("DECIMAL_SEP"))
		_chips.add_child(_chip(tr(spec[0]) % shown, spec[2]))


func _chip(text: String, color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := UiStyle.box(Color(color, 0.16), Color(color, 0.8))
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", sb)
	var l := _label(14, color.lightened(0.3))
	l.text = text
	chip.add_child(l)
	return chip


func _refresh() -> void:
	var id := _ids[_index]
	var unlocked := Profile.is_unlocked(id)
	_style_cards()
	_fill_chips(id, unlocked)
	for i in _cards.size():
		_previews[i].walking = i == _index and unlocked
	_big.cat_id = id
	_big.locked = not unlocked
	_big.walking = unlocked
	var weapon: String = GameData.cats[id]["weapon"]
	_weapon_icon.id = weapon
	_weapon_icon.visible = unlocked and weapon != ""
	_weapon_icon.queue_redraw()
	if unlocked:
		_name.text = tr("CAT_%s_NAME" % id)
		_desc.text = tr("CAT_%s_DESC" % id)
		_weapon_label.text = tr("SELECT_START_WEAPON") % tr("WEAPON_%s_NAME" % weapon) if weapon != "" else tr("SELECT_NO_WEAPON")
		_cat_stats.text = tr("SELECT_CAT_STATS") % [Profile.get_stat("wins_cat:" + id), Profile.get_stat("best_level_cat:" + id), Profile.get_stat("bosses_cat:" + id)]
	else:
		_name.text = tr("SELECT_LOCKED")
		_desc.text = tr("CAT_%s_HINT" % id)
		_weapon_label.text = ""
		_cat_stats.text = ""
	var worn: Array = Profile.equipped_charms.map(func(c: String) -> String: return tr("CHARM_%s_NAME" % c))
	_worn.text = tr("SELECT_CHARMS") % ("—" if worn.is_empty() else ", ".join(worn))
	var arts: Array = Profile.equipped_artifacts.map(func(a: String) -> String: return tr("ARTIFACT_%s_NAME" % a))
	_artifact_label.text = tr("SELECT_ARTIFACTS") % ("—" if arts.is_empty() else ", ".join(arts))
	var ch: Array = Profile.challenges.map(func(c: String) -> String: return tr("CHALLENGE_%s_NAME" % c))
	_challenge_label.text = tr("SELECT_CHALLENGES") % ["—" if ch.is_empty() else ", ".join(ch), Profile.challenge_gold()]
	var plan := Profile.daily_plan()
	var done := Profile.has_flag("daily_win:" + Profile.today())
	_challenge_label.text += "      " + tr("SELECT_DAILY") % [tr("STAGE_%s_NAME" % plan["stage"]), ", ".join((plan["challenges"] as Array).map(func(c: String) -> String: return tr("CHALLENGE_%s_NAME" % c)))] + (" ✓" if done else "")
	_gold.text = tr("SELECT_GOLD") % Profile.gold
	if Profile.streak > 0 or Profile.best_streak > 0:
		_gold.text += "   ·   " + tr("SELECT_STREAK") % [Profile.streak, Profile.best_streak, roundi((Profile.streak_multiplier() - 1.0) * 100.0)]
	for i in _map_cards.size():
		_map_cards[i].selected = i == _stage_index
	var stage_id := _stage_ids[_stage_index]
	_refresh_darkness(stage_id)
	if Profile.is_stage_unlocked(stage_id):
		var stage: Dictionary = GameData.stages[stage_id]
		var info := tr("SELECT_STAGE_INFO") % [int(stage.get("duration_minutes", 30)), MapCard.difficulty(stage_id)]
		_stage_label.text = "%s  %s   ·   %s" % [tr("SELECT_STAGE"), tr("STAGE_%s_NAME" % stage_id), info]
	else:
		_stage_label.text = "%s  ??? – %s" % [tr("SELECT_STAGE"), tr("STAGE_%s_HINT" % stage_id)]


func _change_darkness(step: int) -> void:
	var stage_id := _stage_ids[_stage_index]
	var top := Profile.max_darkness(stage_id)
	if top == 0:
		Audio.play("hurt", -12.0, 0.0)
		return
	Profile.set_darkness(stage_id, Profile.darkness_for(stage_id) + step)
	Audio.play("click", -6.0, 0.0)
	_refresh()


func _refresh_darkness(stage_id: String) -> void:
	var top := Profile.max_darkness(stage_id)
	var level := Profile.darkness_for(stage_id)
	_dark_minus.visible = top > 0
	_dark_plus.visible = top > 0
	if top == 0:
		_dark_label.text = tr("SELECT_DARKNESS_LOCKED")
	elif level == 0:
		_dark_label.text = tr("SELECT_DARKNESS_OFF") % top
	else:
		_dark_label.text = tr("SELECT_DARKNESS") % [level, roundi(Spawner.DARKNESS_HP * level * 100.0), roundi(Spawner.DARKNESS_GOLD * level * 100.0)]


func _on_map_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stage_index = i
		Audio.play("click", -6.0, 0.0)
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _shop.visible or _charms.visible or _items.visible or _journal.visible or _challenges.visible or _artifacts.visible:
		return
	if event.is_action_pressed("challenges"):
		Audio.play("click", -6.0, 0.0)
		_challenges.open()
		return
	for entry: Array in [["questbook", "quests"], ["goals", "goals"], ["journal", "bestiary"]]:
		if event.is_action_pressed(entry[0]):
			Audio.play("click", -6.0, 0.0)
			_journal.open(entry[1])
			return
	if event.is_action_pressed("shop"):
		Audio.play("click", -6.0, 0.0)
		_shop.open()
	elif event.is_action_pressed("items"):
		Audio.play("click", -6.0, 0.0)
		_items.open()
	elif event.is_action_pressed("charms"):
		Audio.play("click", -6.0, 0.0)
		_charms.open()
	elif event.is_action_pressed("artifacts"):
		Audio.play("click", -6.0, 0.0)
		_artifacts.open()
	elif event.is_action_pressed("daily"):
		_start_daily()
	elif event.is_action_pressed("darkness_down"):
		_change_darkness(-1)
	elif event.is_action_pressed("darkness_up"):
		_change_darkness(1)
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
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		_stage_index = (_stage_index + 1) % _stage_ids.size()
		Audio.play("click", -6.0, 0.0)
		_refresh()
	elif event.is_action_pressed("pause"):
		Audio.play("click", -6.0, 0.0)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
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


## The daily night with the chosen cat: today's map, challenges and seed.
func _start_daily() -> void:
	var id := _ids[_index]
	if not Profile.is_unlocked(id):
		Audio.play("hurt", -10.0, 0.0)
		return
	Profile.select(id)
	Profile.start_daily()
	# The same floor and the same luck for everyone today.
	seed(int(Profile.daily_plan()["seed"]))
	Audio.play("select", -4.0, 0.0)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _start() -> void:
	var id := _ids[_index]
	var stage_id := _stage_ids[_stage_index]
	if not Profile.is_unlocked(id) or not Profile.is_stage_unlocked(stage_id):
		Audio.play("hurt", -10.0, 0.0)
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
