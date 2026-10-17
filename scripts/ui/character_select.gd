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
	grid.columns = 7 if _ids.size() > 12 else 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	top.add_child(grid)
	for i in _ids.size():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(98, 112)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(i))
		var preview := CatPreview.new()
		preview.cat_id = _ids[i]
		preview.locked = not Profile.is_unlocked(_ids[i])
		preview.zoom = 2.2
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(preview)
		grid.add_child(card)
		_cards.append(card)
		_previews.append(preview)

	var detail := PanelContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_stylebox_override("panel", UiStyle.box(CARD, BORDER))
	top.add_child(detail)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 10)
	detail.add_child(drow)
	_big = CatPreview.new()
	_big.custom_minimum_size = Vector2(190, 210)
	_big.zoom = 5.0
	_big.walking = true
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
	_desc.custom_minimum_size = Vector2(300, 0)
	info.add_child(_desc)
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
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 28)
	root.add_child(bottom)
	_gold = _label(17, GOLD)
	bottom.add_child(_gold)
	_worn = _label(17, Color("c77dff"))
	bottom.add_child(_worn)
	_artifact_label = _label(17, Color("8fd3ff"))
	bottom.add_child(_artifact_label)
	_challenge_label = _label(17, Color("e04646"))
	root.add_child(_challenge_label)

	var hint := _label(16, Color("8f7ea3"))
	hint.text = "SELECT_HINT"
	root.add_child(hint)

	_shop = ShopPanel.new()
	add_child(_shop)
	_shop.closed.connect(_refresh)
	_charms = CharmPanel.new()
	add_child(_charms)
	_charms.closed.connect(_refresh)
	_artifacts = ArtifactPanel.new()
	add_child(_artifacts)
	_artifacts.closed.connect(_refresh)
	_journal = JournalPanel.new()
	add_child(_journal)
	_journal.closed.connect(_refresh)
	_challenges = ChallengePanel.new()
	add_child(_challenges)
	_challenges.closed.connect(_refresh)


func _refresh() -> void:
	var id := _ids[_index]
	var unlocked := Profile.is_unlocked(id)
	for i in _cards.size():
		_cards[i].add_theme_stylebox_override("panel", UiStyle.box(Color("5b4470") if i == _index else CARD, GOLD if i == _index else BORDER))
		_previews[i].walking = i == _index and unlocked
	_big.cat_id = id
	_big.locked = not unlocked
	_big.walking = unlocked
	var weapon: String = GameData.cats[id]["weapon"]
	_weapon_icon.id = weapon
	_weapon_icon.visible = unlocked
	_weapon_icon.queue_redraw()
	if unlocked:
		_name.text = tr("CAT_%s_NAME" % id)
		_desc.text = tr("CAT_%s_DESC" % id)
		_weapon_label.text = tr("SELECT_START_WEAPON") % tr("WEAPON_%s_NAME" % weapon)
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
	_gold.text = tr("SELECT_GOLD") % Profile.gold
	if Profile.streak > 0 or Profile.best_streak > 0:
		_gold.text += "   ·   " + tr("SELECT_STREAK") % [Profile.streak, Profile.best_streak, roundi((Profile.streak_multiplier() - 1.0) * 100.0)]
	for i in _map_cards.size():
		_map_cards[i].selected = i == _stage_index
	var stage_id := _stage_ids[_stage_index]
	if Profile.is_stage_unlocked(stage_id):
		_stage_label.text = "%s  %s" % [tr("SELECT_STAGE"), tr("STAGE_%s_NAME" % stage_id)]
	else:
		_stage_label.text = "%s  ??? – %s" % [tr("SELECT_STAGE"), tr("STAGE_%s_HINT" % stage_id)]


func _on_map_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_stage_index = i
		Audio.play("click", -6.0, 0.0)
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _shop.visible or _charms.visible or _journal.visible or _challenges.visible or _artifacts.visible:
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
	elif event.is_action_pressed("charms"):
		Audio.play("click", -6.0, 0.0)
		_charms.open()
	elif event.is_action_pressed("artifacts"):
		Audio.play("click", -6.0, 0.0)
		_artifacts.open()
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
