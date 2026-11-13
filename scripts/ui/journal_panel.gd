class_name JournalPanel
extends ColorRect
## The cat's journal: three tabs in one screen - the quest book, the goals
## and the bestiary (cats, enemies by map, weapons and passives). Things not
## met yet show as dark silhouettes. ← → switch tabs, ↑ ↓ or the mouse wheel
## scroll, Esc closes.

signal closed

const TABS := ["quests", "achievements", "goals", "bestiary"]
const GOLD := Color("f2c14e")
const DONE := Color("6cd48a")
const MUTED := Color("c4a27a")
const TEXT := Color("e6d3ab")
const OUTLINE := Color("2b1d14")
const CARD := Color("4a2f1a")
const LIST_HEIGHT := 520.0
const SCROLL_STEP := 54
const SILHOUETTE := Color(0.17, 0.12, 0.08)

var tab := "quests"

var _tab_buttons: Dictionary = {}
var _list: VBoxContainer
var _scroll: ScrollContainer
## Quests tab: the group shown on the right (a map id, "any" or "qb:CHAPTER"),
## the filter (all / open / done) and the right-hand list that the arrow
## keys scroll.
var _group := ""
var _filter := "all"
var _inner_scroll: ScrollContainer


func _ready() -> void:
	color = Color(0.09, 0.055, 0.03, 1.0)
	theme = UiStyle.panel_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	UiStyle.board(self, box)
	var title := UiStyle.paper_title(_label(34, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	title.text = "JOURNAL_TITLE"
	box.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 12)
	box.add_child(tabs)
	for t: String in TABS:
		var b := UiStyle.click_button("JOURNAL_TAB_%s" % t.to_upper(), 180, 15)
		(b as BoxButton).ring_grow = 3.0
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
		(b as BoxButton).selected = t == tab
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	match tab:
		"quests":
			_build_quests()
		"goals":
			_build_goals()
		"achievements":
			_build_achievements()
		_:
			_build_bestiary()
	_scroll.scroll_vertical = 0


# --- quests ---------------------------------------------------------------------

func _build_quests() -> void:
	# Districts in one row of chips, the next one's hint under them.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	_list.add_child(top)
	top.add_child(UiStyle.plain(tr("QB_CHAPTER_DISTRICTS"), 14, MUTED))
	var next := DistrictMap.next_locked()
	for d: String in DistrictMap.DISTRICTS:
		if DistrictMap.district_open(d):
			top.add_child(UiStyle.tag("✓ " + tr("DISTRICT_NAME_" + d.to_upper()), DONE, 14))
		elif d == next:
			top.add_child(UiStyle.tag("🔒 " + tr("DISTRICT_NAME_" + d.to_upper()), Color.WHITE, 14))
		else:
			top.add_child(UiStyle.tag("🔒 ???", Color("c4a27a"), 14))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	for f: String in ["all", "open", "done"]:
		var b := UiStyle.click_button(tr("QB_FILTER_%s" % f.to_upper()), 0, 14)
		(b as BoxButton).selected = f == _filter
		(b as BoxButton).ring_grow = 3.0
		b.pressed.connect(func() -> void:
			_filter = f
			show_tab("quests"))
		top.add_child(b)
	if next != "":
		var hint := UiStyle.plain(DistrictMap.unlock_hint(next), 13, MUTED, true)
		hint.custom_minimum_size.x = 1100
		_list.add_child(hint)
	# Left: the maps (and the quest book's chapters), right: their stories.
	var groups := _quest_groups()
	if _group == "" or _group not in groups:
		_group = _default_group(groups)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	_list.add_child(cols)
	var left := ScrollContainer.new()
	left.custom_minimum_size = Vector2(250, LIST_HEIGHT - 70)
	left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(left)
	var maps := VBoxContainer.new()
	maps.add_theme_constant_override("separation", 5)
	maps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(maps)
	for g: String in groups:
		maps.add_child(_group_button(g))
	_inner_scroll = ScrollContainer.new()
	_inner_scroll.custom_minimum_size = Vector2(840, LIST_HEIGHT - 70)
	_inner_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inner_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(_inner_scroll)
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation", 8)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inner_scroll.add_child(cards)
	var shown := 0
	for id: String in _group_items(_group):
		var done := QuestBook.is_complete(id) if _group.begins_with("qb:") else ChainStep.is_done(id)
		var started := QuestBook.steps_done(id) > 0 if _group.begins_with("qb:") else ChainStep.progress_of(id) > 0
		if (_filter == "done" and not done) or (_filter == "open" and (done or not started)):
			continue
		cards.add_child(_quest_card(id) if _group.begins_with("qb:") else _chain_card(id))
		shown += 1
	if shown == 0:
		cards.add_child(UiStyle.plain(tr("PAUSE_LOG_EMPTY"), 15, MUTED))


## The groups of the quests tab: every map with stories, "any", then the
## quest book's chapters ("qb:CHAPTER").
func _quest_groups() -> Array[String]:
	var groups: Array[String] = []
	for stage: String in GameData.stages:
		if GameData.chains.keys().any(func(c: String) -> bool: return GameData.chains[c].get("stage", "any") == stage):
			groups.append(stage)
	groups.append("any")
	for chapter: String in GameData.questbook.get("chapters", []):
		groups.append("qb:" + chapter)
	return groups


## The first map with a story under way, else the map last played.
func _default_group(groups: Array[String]) -> String:
	for g in groups:
		if g.begins_with("qb:"):
			continue
		for id: String in _group_items(g):
			if ChainStep.progress_of(id) > 0 and not ChainStep.is_done(id):
				return g
	return Profile.selected_stage if Profile.selected_stage in groups else groups[0]


func _group_items(g: String) -> Array:
	if g.begins_with("qb:"):
		var chapter := g.trim_prefix("qb:")
		return QuestBook.lines().keys().filter(func(id: String) -> bool: return QuestBook.lines()[id]["chapter"] == chapter)
	return GameData.chains.keys().filter(func(c: String) -> bool: return GameData.chains[c].get("stage", "any") == g)


func _group_name(g: String) -> String:
	if g.begins_with("qb:"):
		return tr("QB_CHAPTER_%s" % g.trim_prefix("qb:").to_upper())
	if g == "any":
		return tr("CHAIN_GROUP_ANY")
	return tr("STAGE_%s_NAME" % g) if Profile.is_stage_unlocked(g) else "???"


## A map (or chapter) in the left list: its name (wrapped when long),
## stories done and a bar; a click shows its stories.
func _group_button(g: String) -> PanelContainer:
	var items := _group_items(g)
	var done := items.filter(func(id: String) -> bool: return QuestBook.is_complete(id) if g.begins_with("qb:") else ChainStep.is_done(id)).size()
	var b := PanelContainer.new()
	var selected := g == _group
	var sb := UiStyle.card(selected)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 7
	b.add_theme_stylebox_override("panel", sb)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_group = g
			show_tab.call_deferred("quests"))
	if not selected:
		b.mouse_entered.connect(func() -> void: sb.border_color = Color("c4a27a"))
		b.mouse_exited.connect(func() -> void: sb.border_color = UiStyle.CARD_BORDER)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	var name_label := UiStyle.plain(_group_name(g), 15, UiStyle.P_RED if selected else (UiStyle.P_GREEN if done == items.size() else UiStyle.P_TEXT), true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	row.add_child(UiStyle.plain("%d / %d" % [done, items.size()], 13, UiStyle.P_MUTED))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 4
	bar.max_value = maxi(items.size(), 1)
	bar.value = done
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("c3ab7d")
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = DONE
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)
	return b


## A card for a story chain: name and state, reward, the story and the next step.
func _chain_card(id: String) -> PanelContainer:
	var done := ChainStep.is_done(id)
	var n := ChainStep.steps(id).size()
	var steps := ChainStep.progress_of(id)
	# A secret keeps its name hidden until it is found (its hint still shows).
	var hidden: bool = ChainStep.chain(id).has("secret") and steps == 0
	var next_text := ""
	if not done:
		var stage := ChainStep.stage_of(id, steps + 1)
		var where := tr("CHAIN_ANY_MAP") if stage == "any" else tr("STAGE_%s_NAME" % stage)
		if stage != "any" and not Profile.is_stage_unlocked(stage):
			where = "???"
		var need: String = ChainStep.steps(id)[steps].get("needs_cat", "")
		if need != "" and not Profile.is_unlocked(need):
			where += " · " + tr("CHAIN_NEEDS_CAT") % tr("CAT_%s_NAME" % need)
		next_text = "%s  (%s)" % [tr("CHAIN_%s_%d" % [id, steps + 1]), where]
	return _story_card("???" if hidden else tr("CHAIN_%s_NAME" % id), done, steps, n, QuestBook.reward_text(ChainStep.chain(id).get("reward", {})), tr("CHAIN_%s_DESC" % id), next_text)


## A card for a quest book line (the same look as a story).
func _quest_card(id: String) -> PanelContainer:
	if QuestBook.is_hidden(id):
		return _story_card("???", false, 0, 0, "", tr("QB_SECRET"), "")
	var done := QuestBook.is_complete(id)
	var n := QuestBook.step_count(id)
	var steps := QuestBook.steps_done(id)
	var reward := ""
	var next_text := ""
	if not done:
		var step := QuestBook.current(id)
		reward = QuestBook.reward_text(step["reward"])
		next_text = "%s  %d/%d" % [QuestBook.step_text(id, steps + 1), mini(QuestBook.progress(step), QuestBook.target(step)), QuestBook.target(step)]
	return _story_card(QuestBook.line_name(id), done, steps, n, reward, "", next_text)


func _story_card(title: String, done: bool, steps: int, n: int, reward: String, desc: String, next_text: String) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := UiStyle.card()
	sb.set_content_margin_all(12)
	if done:
		sb.border_color = Color("3f6a35")
	card.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var name_label := UiStyle.plain(title, 17, UiStyle.P_GREEN if done else UiStyle.P_TEXT)
	head.add_child(name_label)
	var state := "done" if done else ("open" if steps > 0 else "new")
	head.add_child(UiStyle.tag(tr("QB_STATE_%s" % state.to_upper()), Color("b8e6a0") if done else (Color("f2c14e") if steps > 0 else Color("e6d3ab")), 12))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	if reward != "":
		var r := UiStyle.plain(reward, 14, UiStyle.P_GOLD, true)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.custom_minimum_size.x = minf(ThemeDB.fallback_font.get_string_size(reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 4.0, 330.0)
		head.add_child(r)
	if desc != "":
		col.add_child(UiStyle.plain(desc, 14, UiStyle.P_MUTED, true))
	if n > 0:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		col.add_child(row)
		row.add_child(UiStyle.segments(n, steps, 24 if n <= 8 else 12, 6))
		if next_text != "":
			row.add_child(UiStyle.plain(tr("QB_NEXT"), 13, UiStyle.P_MUTED))
			var t := UiStyle.plain(next_text, 14, UiStyle.P_TEXT, true)
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(t)
		elif done:
			row.add_child(UiStyle.plain(tr("QB_DONE"), 13, UiStyle.P_GREEN))
	return card


# --- achievements -----------------------------------------------------------------

func _build_achievements() -> void:
	Achievements.check()
	var ids: Array = Achievements.all().keys()
	_header("%s   %s" % [tr("JOURNAL_TAB_ACHIEVEMENTS"), tr("BESTIARY_FOUND") % [ids.filter(func(a: String) -> bool: return Achievements.is_earned(a)).size(), ids.size()]])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	_list.add_child(grid)
	for id: String in ids:
		var earned := Achievements.is_earned(id)
		var secret: bool = Achievements.all()[id].get("secret", false)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(550, 58)
		card.add_theme_stylebox_override("panel", UiStyle.card(false, Color("f1d78c") if earned else Color(0, 0, 0, 0)))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		card.add_child(box)
		var name_label := _label(18, UiStyle.P_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.label_settings.outline_size = 0
		name_label.text = ("★ " if earned else "☆ ") + (tr("ACH_%s_NAME" % id) if earned or not secret else "???")
		box.add_child(name_label)
		var desc := _label(14, DONE if earned else MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		var goal := Achievements.target(id)
		var count := "" if earned or goal <= 1 else "  (%d/%d)" % [mini(Achievements.progress(id), goal), goal]
		desc.text = "   " + (tr("ACH_%s_DESC" % id) + count if earned or not secret else tr("QB_SECRET"))
		box.add_child(desc)
		grid.add_child(card)


# --- goals ----------------------------------------------------------------------

func _build_goals() -> void:
	for id: String in GameData.goals:
		var done := Goals.is_done(id)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(1000, 24)
		var name_label := _label(16, DONE if done else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.text = "%s %s – %s" % ["✓" if done else "·", tr("GOAL_%s_NAME" % id), tr("GOAL_%s_DESC" % id)]
		_fill(name_label)
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
		var reward := _reward_label()
		reward.text = "  " + Goals.reward_text(id)
		row.add_child(reward)
		_list.add_child(row)


# --- bestiary -------------------------------------------------------------------

func _build_bestiary() -> void:
	# Cats.
	var cats: Array = GameData.cats.keys().filter(func(c: String) -> bool: return not GameData.cats[c].get("npc", false))
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

	# Champion traits.
	var champs: Array = GameData.champions.keys()
	_header("%s   %s" % [tr("BESTIARY_CHAMPIONS"), tr("BESTIARY_FOUND") % [champs.filter(func(c: String) -> bool: return Profile.get_stat("champions:" + c) > 0).size(), champs.size()]])
	var cgrid := _grid()
	for c: String in champs:
		var known := Profile.get_stat("champions:" + c) > 0
		var swatch := ColorRect.new()
		swatch.color = Color(GameData.champions[c]["color"]) if known else SILHOUETTE
		swatch.custom_minimum_size = Vector2(40, 40)
		cgrid.add_child(_card(swatch, tr("CHAMPION_%s_NAME" % c) if known else "???",
			"%s\n%s" % [tr("BESTIARY_KILLS") % Profile.get_stat("champions:" + c), tr("CHAMPION_%s_DESC" % c)] if known else tr("BESTIARY_UNKNOWN"), known))

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
	sb.bg_color = CARD if known else Color("3a2412")
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
	var scroll := _inner_scroll if tab == "quests" and is_instance_valid(_inner_scroll) else _scroll
	if event.is_action_pressed("move_down", true) or event.is_action_pressed("ui_down", true):
		scroll.scroll_vertical += SCROLL_STEP
		return
	if event.is_action_pressed("move_up", true) or event.is_action_pressed("ui_up", true):
		scroll.scroll_vertical -= SCROLL_STEP
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


## A row's name takes the room the other columns leave and wraps if it must.
func _fill(label: Label) -> void:
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 300


## Rewards get a fixed column and wrap onto a second line when they're long,
## so a long one in another language never pushes the list off the screen.
func _reward_label() -> Label:
	var reward := _label(15, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward.custom_minimum_size.x = 360
	return reward
