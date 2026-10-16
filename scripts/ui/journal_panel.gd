class_name JournalPanel
extends ColorRect
## The cat's journal: three tabs in one screen - the quest book, the goals
## and the bestiary (cats, enemies by map, weapons and passives). Things not
## met yet show as dark silhouettes. ← → switch tabs, ↑ ↓ or the mouse wheel
## scroll, Esc closes.

signal closed

const TABS := ["quests", "goals", "bestiary"]
const GOLD := Color("f2c14e")
const DONE := Color("6cd48a")
const MUTED := Color("8f7ea3")
const TEXT := Color("d9cce6")
const OUTLINE := Color("2b1d14")
const CARD := Color("3b2a4a")
const LIST_HEIGHT := 520.0
const SCROLL_STEP := 54
const SILHOUETTE := Color(0.12, 0.09, 0.15)

var tab := "quests"

var _tab_buttons: Dictionary = {}
var _list: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	color = Color(0.08, 0.05, 0.1, 0.98)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := _label(34, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.text = "JOURNAL_TITLE"
	box.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 12)
	box.add_child(tabs)
	for t: String in TABS:
		var b := Button.new()
		b.text = "JOURNAL_TAB_%s" % t.to_upper()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(200, 36)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(func() -> void: show_tab(t))
		tabs.add_child(b)
		_tab_buttons[t] = b
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(1120, LIST_HEIGHT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	var hint := _label(16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint.text = "JOURNAL_HINT"
	box.add_child(hint)


## Opens the journal on `which` tab ("quests", "goals" or "bestiary").
func open(which: String = "") -> void:
	visible = true
	show_tab(which if which in TABS else tab)


func show_tab(which: String) -> void:
	tab = which
	for t: String in _tab_buttons:
		var b: Button = _tab_buttons[t]
		b.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.PANEL_HOVER if t == tab else UiStyle.PANEL, GOLD if t == tab else UiStyle.BORDER))
		b.add_theme_color_override("font_color", GOLD if t == tab else TEXT)
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	match tab:
		"quests":
			_build_quests()
		"goals":
			_build_goals()
		_:
			_build_bestiary()
	_scroll.scroll_vertical = 0


# --- quests ---------------------------------------------------------------------

func _build_quests() -> void:
	for chapter: String in GameData.questbook.get("chapters", []):
		_header(tr("QB_CHAPTER_%s" % chapter.to_upper()))
		for id: String in QuestBook.lines():
			if QuestBook.lines()[id]["chapter"] == chapter:
				_list.add_child(_quest_row(id))


func _quest_row(id: String) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var top := HBoxContainer.new()
	row.add_child(top)
	var done := QuestBook.is_complete(id)
	var n := QuestBook.step_count(id)
	var name_label := _label(18, DONE if done else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.custom_minimum_size.x = 640
	top.add_child(name_label)
	var dots := _label(16, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	dots.custom_minimum_size.x = 120
	top.add_child(dots)
	var count := _label(15, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	count.custom_minimum_size.x = 110
	top.add_child(count)
	var reward := _label(15, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	top.add_child(reward)
	var desc := _label(15, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	row.add_child(desc)
	if QuestBook.is_hidden(id):
		name_label.text = "  ???"
		desc.text = "      " + tr("QB_SECRET")
		return row
	var steps := QuestBook.steps_done(id)
	name_label.text = "%s %s" % ["✓" if done else "·", tr("QB_%s_NAME" % id)]
	dots.text = "●".repeat(steps) + "○".repeat(n - steps)
	if done:
		desc.text = "      " + tr("QB_DONE")
		return row
	var step := QuestBook.current(id)
	count.text = "%d/%d" % [mini(QuestBook.progress(step), QuestBook.target(step)), QuestBook.target(step)]
	reward.text = "  " + QuestBook.reward_text(step["reward"])
	desc.text = "      %s  %s" % [tr("QB_STEP") % [steps + 1, n], tr("QB_%s_%d" % [id, steps + 1])]
	return row


# --- goals ----------------------------------------------------------------------

func _build_goals() -> void:
	for id: String in GameData.goals:
		var done := Goals.is_done(id)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(1000, 24)
		var name_label := _label(16, DONE if done else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.text = "%s %s – %s" % ["✓" if done else "·", tr("GOAL_%s_NAME" % id), tr("GOAL_%s_DESC" % id)]
		name_label.custom_minimum_size.x = 600
		row.add_child(name_label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(150, 16)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.max_value = Goals.target(id)
		bar.value = mini(Goals.progress(id), Goals.target(id))
		row.add_child(bar)
		var count := _label(15, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		count.text = "%d/%d" % [mini(Goals.progress(id), Goals.target(id)), Goals.target(id)]
		count.custom_minimum_size.x = 90
		row.add_child(count)
		var reward := _label(15, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		reward.text = "  " + Goals.reward_text(id)
		row.add_child(reward)
		_list.add_child(row)


# --- bestiary -------------------------------------------------------------------

func _build_bestiary() -> void:
	# Cats.
	var cats: Array = GameData.cats.keys()
	_header("%s   %s" % [tr("BESTIARY_CATS"), tr("BESTIARY_FOUND") % [cats.filter(func(c: String) -> bool: return Profile.is_unlocked(c)).size(), cats.size()]])
	var grid := _grid()
	for id: String in cats:
		var known := Profile.is_unlocked(id)
		var secret: bool = GameData.cats[id].get("hidden", false)
		grid.add_child(_card(_cat_portrait(id, known), tr("CAT_%s_NAME" % id) if known else "???",
			tr("CAT_%s_DESC" % id) if known else ("" if secret else tr("CAT_%s_HINT" % id)), known))

	# Enemies by map, then rivals and secrets.
	var placed: Dictionary = {}
	for stage_id: String in GameData.stages:
		var ids := _stage_enemies(stage_id).filter(func(e: String) -> bool: return not placed.has(e))
		for e: String in ids:
			placed[e] = true
		_enemy_section(tr("BESTIARY_ENEMIES") % tr("STAGE_%s_NAME" % stage_id), ids)
	var others: Array = GameData.enemies.keys().filter(func(e: String) -> bool: return not placed.has(e))
	_enemy_section(tr("BESTIARY_OTHERS"), others)

	# Weapons (base first, each followed by its evolution) and passives.
	var weapons: Array[String] = []
	for id: String in GameData.weapons:
		if GameData.weapons[id].get("evolved", false):
			continue
		weapons.append(id)
		var evo: Dictionary = GameData.weapons[id].get("evolve", {})
		if not evo.is_empty():
			weapons.append(evo["into"])
	var known_weapons := weapons.filter(func(w: String) -> bool: return _weapon_known(w))
	_header("%s   %s" % [tr("BESTIARY_WEAPONS"), tr("BESTIARY_FOUND") % [known_weapons.size(), weapons.size()]])
	grid = _grid()
	for id in weapons:
		var known := _weapon_known(id)
		var icon := IconView.new("weapon", id, 40.0)
		if not known:
			icon.modulate = SILHOUETTE
		var card := _card(icon, tr("WEAPON_%s_NAME" % id) if known else "???", _weapon_text(id) if known else tr("BESTIARY_UNUSED"), known)
		card.custom_minimum_size.y = 96
		grid.add_child(card)
	var passives: Array = GameData.passives.keys()
	_header("%s   %s" % [tr("BESTIARY_PASSIVES"), tr("BESTIARY_FOUND") % [passives.filter(func(p: String) -> bool: return Profile.has_flag("used:" + p)).size(), passives.size()]])
	grid = _grid()
	for id: String in passives:
		var known := Profile.has_flag("used:" + id)
		var icon := IconView.new("passive", id, 40.0)
		if not known:
			icon.modulate = SILHOUETTE
		grid.add_child(_card(icon, tr("PASSIVE_%s_NAME" % id) if known else "???", tr("PASSIVE_%s_DESC" % id) if known else tr("BESTIARY_UNUSED"), known))


func _enemy_section(title: String, ids: Array) -> void:
	var met := ids.filter(func(e: String) -> bool: return _enemy_known(e))
	_header("%s   %s" % [title, tr("BESTIARY_FOUND") % [met.size(), ids.size()]])
	var grid := _grid()
	for id: String in ids:
		var known := _enemy_known(id)
		var data: Dictionary = GameData.enemies[id]
		var tag := ""
		if data.get("final", false):
			tag = tr("BESTIARY_FINAL") + " · "
		elif data.get("boss", false):
			tag = tr("BESTIARY_BOSS") + " · "
		var text := "%s%s\n%s" % [tag, tr("BESTIARY_KILLS") % Profile.get_stat("kills:" + id), tr("ENEMY_%s_DESC" % id)]
		grid.add_child(_card(EnemyPortrait.new(id, known), tr("ENEMY_%s_NAME" % id) if known else "???", text if known else tr("BESTIARY_UNKNOWN"), known))


## Every enemy a stage can send: waves, bosses, events and its final boss.
func _stage_enemies(stage_id: String) -> Array:
	var stage: Dictionary = GameData.stages[stage_id]
	var ids: Array = []
	for w: Dictionary in stage["waves"]:
		for e: String in w["enemies"] + w.get("bosses", []):
			if e not in ids:
				ids.append(e)
	for ev: Dictionary in stage.get("events", []):
		if ev["enemy"] not in ids:
			ids.append(ev["enemy"])
	var final_id: String = stage.get("final_boss", "")
	if final_id != "" and final_id not in ids:
		ids.append(final_id)
	# Regular enemies first, bosses last, final boss at the very end.
	ids.sort_custom(func(a: String, b: String) -> bool: return _rank(a) < _rank(b))
	return ids


func _rank(id: String) -> int:
	var d: Dictionary = GameData.enemies[id]
	return 2 if d.get("final", false) else (1 if d.get("boss", false) else 0)


func _enemy_known(id: String) -> bool:
	if id == "DEVIL_CAT":
		return Profile.has_flag("devil_met")
	return Profile.get_stat("kills:" + id) > 0


func _weapon_known(id: String) -> bool:
	return Profile.has_flag("used:" + id) or Profile.has_flag("evolved:" + id)


func _weapon_text(id: String) -> String:
	var data: Dictionary = GameData.weapons[id]
	var text := tr("WEAPON_%s_DESC" % id)
	var evo: Dictionary = data.get("evolve", {})
	if not evo.is_empty():
		text += "\n" + tr("BESTIARY_EVOLVES") % [tr("PASSIVE_%s_NAME" % evo["with"]), tr("WEAPON_%s_NAME" % evo["into"])]
	var branches: Dictionary = GameData.branches.get(id, {})
	if not branches.is_empty():
		var names: Array[String] = []
		for b: String in branches:
			names.append(tr("BRANCH_%s_NAME" % b) if Profile.has_flag("used:branch:" + b) else "???")
		text += "\n" + tr("BESTIARY_BRANCHES") % ", ".join(names)
	return text


func _cat_portrait(id: String, known: bool) -> Control:
	var p := CatPreview.new()
	p.cat_id = id
	p.locked = not known
	p.custom_minimum_size = Vector2(56, 48)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.zoom = 1.4
	return p


# --- building blocks ------------------------------------------------------------

func _header(text: String) -> void:
	var l := _label(22, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	l.text = text
	_list.add_child(l)


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	_list.add_child(g)
	return g


func _card(picture: Control, title: String, text: String, known: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 76)
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD if known else Color("2a1f33")
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	picture.custom_minimum_size = Vector2(maxf(picture.custom_minimum_size.x, 56), 56)
	row.add_child(picture)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var t := _label(17, Color.WHITE if known else MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	t.text = title
	col.add_child(t)
	var d := _label(13, TEXT if known else MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	d.text = text
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 270
	col.add_child(d)
	return panel


## _input, not _unhandled_input: the panel must see keys before the GUI
## focus of the screen behind it does.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed():
		return
	if event.is_action_pressed("move_down", true) or event.is_action_pressed("ui_down", true):
		_scroll.scroll_vertical += SCROLL_STEP
		return
	if event.is_action_pressed("move_up", true) or event.is_action_pressed("ui_up", true):
		_scroll.scroll_vertical -= SCROLL_STEP
		return
	if event.is_echo():
		return
	var i := TABS.find(tab)
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		show_tab(TABS[(i + 1) % TABS.size()])
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		show_tab(TABS[(i - 1 + TABS.size()) % TABS.size()])
	elif event.is_action_pressed("pause") or event.is_action_pressed("journal") \
			or (event.is_action_pressed("goals") and tab == "goals") or (event.is_action_pressed("questbook") and tab == "quests"):
		visible = false
		closed.emit()
	elif event.is_action_pressed("goals"):
		show_tab("goals")
	elif event.is_action_pressed("questbook"):
		show_tab("quests")


func _label(size: int, font_color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = font_color
	settings.outline_size = 4
	settings.outline_color = OUTLINE
	label.label_settings = settings
	label.horizontal_alignment = align
	return label
